const cds = require('@sap/cds');
const { executeHttpRequest } = require('@sap-cloud-sdk/http-client');

/**
 * LLM orchestration (design §6.4). The prompt = canonical rows + injected
 * guidance (context injection, §4) + deterministic mapping rules.
 *
 * The model PROPOSES GL mappings / item texts and emits a grounding clause +
 * reasoning per line. It MUST NOT compute balances or invent master data —
 * arithmetic and existence are handled deterministically downstream (§7).
 *
 * ORCHESTRATION_MODE=stub (default) | live
 *   live  -> SAP AI Core Generative AI Hub orchestration deployment, reached via
 *            the bound `aicore` service credentials (VCAP) — most reliable.
 *   stub  -> deterministic heuristic proposal (keeps the full flow runnable)
 */
const MODE = process.env.ORCHESTRATION_MODE || 'stub';
const AICORE_DEST = process.env.AICORE_DESTINATION || 'ai-core-destination';
const RESOURCE_GROUP = process.env.AICORE_RESOURCE_GROUP || 'default';
const ORCH_DEPLOYMENT = process.env.AICORE_ORCH_DEPLOYMENT; // orchestration deployment id
const LOG = cds.log('orchestration');

/** Read AI Core credentials from the bound `aicore` service (VCAP_SERVICES). */
function aicoreBinding() {
  try {
    const vcap = JSON.parse(process.env.VCAP_SERVICES || '{}');
    const b = (vcap.aicore || [])[0];
    return b ? b.credentials : null;
  } catch { return null; }
}

let tokenCache = { token: null, exp: 0 };
async function aicoreToken(cred) {
  if (tokenCache.token && Date.now() < tokenCache.exp) return tokenCache.token;
  const auth = Buffer.from(`${cred.clientid}:${cred.clientsecret}`).toString('base64');
  const r = await fetch(`${cred.url}/oauth/token?grant_type=client_credentials`, {
    method: 'POST', headers: { Authorization: `Basic ${auth}` }
  });
  if (!r.ok) throw new Error(`AI Core token HTTP ${r.status}`);
  const j = await r.json();
  tokenCache = { token: j.access_token, exp: Date.now() + (j.expires_in - 60) * 1000 };
  return tokenCache.token;
}

const SYSTEM_PROMPT = `You are a finance posting assistant. You receive a posting GUIDANCE policy and parsed DATA rows.
For EACH data row produce one journal line as JSON with fields:
  glAccount (string), debitCredit ("S" debit or "H" credit), amount (positive number),
  costCenter (string or null), companyCode (string), currency (string),
  itemText (<=50 chars), groundingClause (the exact guidance sentence that justifies the mapping),
  reasoning (one short sentence).
Rules: Do NOT compute or balance totals. Do NOT invent GL accounts not implied by guidance or mapping rules.
Respond with ONLY a JSON object: { "lines": [ ... ] }.`;

function buildUserPrompt(guidanceText, mappingRules, rows) {
  const rulesText = mappingRules.length
    ? mappingRules.map(r => `- "${r.sourceKey}" -> GL ${r.targetGLAccount}${r.costObject ? ', CC ' + r.costObject : ''}`).join('\n')
    : '(none)';
  return `GUIDANCE POLICY:\n${guidanceText}\n\nDETERMINISTIC MAPPING RULES:\n${rulesText}\n\nDATA ROWS (JSON):\n${JSON.stringify(rows)}\n`;
}

/** Live call to AI Core Generative AI Hub orchestration. */
async function callOrchestration(guidanceText, mappingRules, rows) {
  if (!ORCH_DEPLOYMENT) throw new Error('AICORE_ORCH_DEPLOYMENT not configured');
  const body = {
    orchestration_config: {
      module_configurations: {
        templating_module_config: {
          template: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: '{{?user}}' }
          ]
        },
        llm_module_config: {
          model_name: process.env.AICORE_MODEL || 'gpt-4o',
          model_params: { temperature: 0, response_format: { type: 'json_object' } }
        }
      }
    },
    input_params: { user: buildUserPrompt(guidanceText, mappingRules, rows) }
  };
  const path = `/v2/inference/deployments/${ORCH_DEPLOYMENT}/completion`;
  const cred = aicoreBinding();
  let data;
  if (cred) {
    // Preferred: bound aicore service credentials (avoids destination URL drift).
    const apiUrl = (cred.serviceurls && cred.serviceurls.AI_API_URL) || cred.AI_API_URL;
    const token = await aicoreToken(cred);
    const r = await fetch(`${apiUrl}${path}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'AI-Resource-Group': RESOURCE_GROUP, 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!r.ok) throw new Error(`AI Core orchestration HTTP ${r.status}: ${(await r.text()).slice(0, 200)}`);
    data = await r.json();
  } else {
    // Fallback: AI Core destination handles auth + base URL.
    const res = await executeHttpRequest(
      { destinationName: AICORE_DEST },
      { method: 'post', url: path,
        headers: { 'AI-Resource-Group': RESOURCE_GROUP, 'Content-Type': 'application/json' },
        data: body },
      { fetchCsrfToken: false }
    );
    data = res.data;
  }
  const content = data?.orchestration_result?.choices?.[0]?.message?.content
    || data?.choices?.[0]?.message?.content;
  return JSON.parse(content);
}

/** Deterministic stub proposal — used when no model deployment is wired. */
function stubProposal(guidanceText, mappingRules, rows) {
  const sentences = (guidanceText || '').split(/(?<=[.!?])\s+/).filter(Boolean);
  const findClause = (desc) => {
    const d = String(desc || '').toLowerCase();
    const words = d.split(/\W+/).filter(w => w.length > 3);
    const hit = sentences.find(s => words.some(w => s.toLowerCase().includes(w)));
    return hit || (sentences[0] || 'No specific clause matched');
  };
  const ruleFor = (desc) => mappingRules.find(r =>
    String(desc || '').toLowerCase().includes(String(r.sourceKey || '').toLowerCase()));

  const lines = rows.map((r) => {
    const rule = ruleFor(r.description);
    const glAccount = r.glAccount || (rule && rule.targetGLAccount) || '';
    const rawAmt = Number(r.amount || 0);
    const dc = r.debitCredit === 'S' || r.debitCredit === 'H'
      ? r.debitCredit
      : (rawAmt < 0 ? 'H' : 'S');
    return {
      glAccount,
      debitCredit: dc,
      amount: Math.abs(rawAmt),
      costCenter: r.costCenter || (rule && rule.costObject) || null,
      profitCenter: r.profitCenter || null,
      companyCode: r.companyCode || process.env.DEFAULT_COMPANY_CODE || '',
      currency: r.currency || process.env.DEFAULT_CURRENCY || 'SGD',
      itemText: (r.itemText || r.description || '').toString().slice(0, 50),
      groundingClause: findClause(r.description),
      reasoning: rule
        ? `Mapped via rule "${rule.sourceKey}" → GL ${rule.targetGLAccount}.`
        : (r.glAccount ? 'GL account taken from source file.' : 'No mapping rule matched; GL left blank for review.')
    };
  });
  return { lines };
}

async function generate(guidanceText, mappingRules, rows) {
  if (MODE === 'live') {
    try {
      const out = await callOrchestration(guidanceText, mappingRules, rows);
      return { source: 'aicore', ...out };
    } catch (e) {
      LOG.warn('AI Core orchestration failed, falling back to stub:', e.message);
    }
  }
  return { source: 'stub', ...stubProposal(guidanceText, mappingRules, rows) };
}

module.exports = { generate };
