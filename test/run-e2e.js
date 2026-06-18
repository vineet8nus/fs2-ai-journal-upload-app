/*
 * End-to-end smoke-test driver for the DEPLOYED app (live SHD250 + live AI Core).
 * Drives the OData actions for all scenarios in ./scenarios and prints, per
 * scenario, the status transitions, per-line validation, and audit trail.
 *
 * Config via env (defaults target the deployed PoC):
 *   SRV_URL            base URL of fs2-journal-srv (…/journal)
 *   XSUAA_URL          XSUAA token URL
 *   XSUAA_CLIENTID     client id (from `cf create-service-key fs2-journal-xsuaa k`)
 *   XSUAA_CLIENTSECRET client secret
 *   NOSCOPE_TOKEN      (optional) a token WITHOUT JournalApprover, for the role test
 *   GUIDANCE_ID        guidance doc id (default = seeded Marketing policy)
 *
 * Run: node test/run-e2e.js
 */
const fs = require('fs');
const path = require('path');

const SRV = (process.env.SRV_URL || '').replace(/\/$/, '');
const XU = process.env.XSUAA_URL;
const CID = process.env.XSUAA_CLIENTID;
const SEC = process.env.XSUAA_CLIENTSECRET;
const GUID = process.env.GUIDANCE_ID || '11111111-1111-1111-1111-111111111111';
const SDIR = path.join(__dirname, 'scenarios');
if (!SRV || !XU || !CID || !SEC) { console.error('Set SRV_URL, XSUAA_URL, XSUAA_CLIENTID, XSUAA_CLIENTSECRET'); process.exit(2); }

let TOK; const NOSCOPE = process.env.NOSCOPE_TOKEN;
const results = [];

async function token() {
  const r = await fetch(`${XU}/oauth/token?grant_type=client_credentials`, {
    method: 'POST', headers: { Authorization: 'Basic ' + Buffer.from(`${CID}:${SEC}`).toString('base64') }
  });
  return (await r.json()).access_token;
}
const b64 = (f) => fs.readFileSync(path.join(SDIR, f)).toString('base64');
async function call(method, p, body, tok = TOK) {
  const r = await fetch(`${SRV}${p}`, {
    method, headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' },
    body: body !== undefined ? JSON.stringify(body) : undefined
  });
  const txt = await r.text(); let data = null;
  try { data = txt ? JSON.parse(txt) : null; } catch { data = txt; }
  return { status: r.status, data };
}
const EK = (id) => `/Cases(ID=${id},IsActiveEntity=true)`;
const msg = (d) => (d && d.status ? `${d.status} | ${d.message || ''}` : (d && d.error ? `ERR ${d.error.code}: ${d.error.message}` : JSON.stringify(d)));
const upload = (file) => call('POST', '/uploadData', { guidance_ID: GUID, fileName: file, contentBase64: b64(file) });
const lines = async (id) => (await call('GET', `${EK(id)}/proposal?$expand=lines($select=lineNo,glAccount,amount,debitCredit,costCenter,confidence,validationStatus,validationMsg,requiresApproval)`)).data;
const audit = async (id) => ((await call('GET', `${EK(id)}/auditLogs?$select=event,actor,detail&$orderby=timestamp`)).data || {}).value || [];
function rec(name, steps, extra = {}) { results.push({ name, steps, ...extra }); console.log(`\n### ${name}`); steps.forEach(s => console.log('   ', s)); }

(async () => {
  TOK = await token();
  console.log('SRV', SRV);

  { const steps = []; const up = await upload('s1_happy_stp.csv'); const id = up.data.ID;
    steps.push(`upload HTTP ${up.status} -> case ${id}`);
    steps.push('generate ' + msg((await call('POST', `${EK(id)}/JournalService.generateProposal`, {})).data));
    steps.push('validate ' + msg((await call('POST', `${EK(id)}/JournalService.validateProposal`, {})).data));
    const pl = await lines(id);
    steps.push(`proposal balanced=${pl.balanced} debit=${pl.debitTotal} credit=${pl.creditTotal} overallConf=${pl.overallConfidence}`);
    pl.lines.forEach(l => steps.push(`  ln${l.lineNo} GL ${l.glAccount} ${l.debitCredit} ${l.amount} conf=${l.confidence} ${l.validationStatus} appr=${l.requiresApproval} :: ${l.validationMsg}`));
    steps.push('submit ' + msg((await call('POST', `${EK(id)}/JournalService.submitForApproval`, {})).data));
    const post = await call('POST', `${EK(id)}/JournalService.postJournal`, {});
    steps.push(`post HTTP ${post.status} ` + msg(post.data));
    rec('S1 Happy path / STP / live validation + AI Core', steps, { caseId: id, audit: await audit(id) }); }

  { const steps = []; const up = await upload('s2_happy_approval.csv'); const id = up.data.ID;
    await call('POST', `${EK(id)}/JournalService.generateProposal`, {});
    steps.push('validate ' + msg((await call('POST', `${EK(id)}/JournalService.validateProposal`, {})).data));
    steps.push('submit ' + msg((await call('POST', `${EK(id)}/JournalService.submitForApproval`, {})).data));
    steps.push('approve ' + msg((await call('POST', `${EK(id)}/JournalService.approve`, {})).data));
    const post = await call('POST', `${EK(id)}/JournalService.postJournal`, {});
    steps.push(`post HTTP ${post.status} ` + msg(post.data));
    rec('S2 amount>threshold -> approval -> post', steps, { caseId: id, audit: await audit(id) }); }

  { const steps = []; const up = await upload('s3_unbalanced.csv'); const id = up.data.ID;
    await call('POST', `${EK(id)}/JournalService.generateProposal`, {});
    steps.push('validate ' + msg((await call('POST', `${EK(id)}/JournalService.validateProposal`, {})).data));
    steps.push('submit HTTP ' + (await call('POST', `${EK(id)}/JournalService.submitForApproval`, {})).status + ' (expect 400)');
    rec('S3 Unbalanced -> blocked', steps, { caseId: id }); }

  for (const [name, file] of [['S4 Non-existent GL -> blocked (live)', 's4_bad_gl.csv'], ['S5 Non-existent cost center -> blocked (live)', 's5_bad_costcenter.csv']]) {
    const steps = []; const up = await upload(file); const id = up.data.ID;
    await call('POST', `${EK(id)}/JournalService.generateProposal`, {});
    steps.push('validate ' + msg((await call('POST', `${EK(id)}/JournalService.validateProposal`, {})).data));
    (await lines(id)).lines.forEach(l => steps.push(`  ln${l.lineNo} GL ${l.glAccount} CC ${l.costCenter} ${l.validationStatus} :: ${l.validationMsg}`));
    rec(name, steps, { caseId: id }); }

  { const up = await upload('s6_parse_error.csv');
    rec('S6 Malformed file -> fail fast', [`upload HTTP ${up.status} ` + msg(up.data) + ' (expect 400)']); }

  { const steps = []; const up = await upload('s2_happy_approval.csv'); const id = up.data.ID;
    await call('POST', `${EK(id)}/JournalService.generateProposal`, {});
    await call('POST', `${EK(id)}/JournalService.validateProposal`, {});
    steps.push('submit ' + msg((await call('POST', `${EK(id)}/JournalService.submitForApproval`, {})).data));
    steps.push('reject ' + msg((await call('POST', `${EK(id)}/JournalService.rejectCase`, { reason: 'Not approved for demo' })).data));
    rec('S7 Reject path', steps, { caseId: id, audit: await audit(id) }); }

  if (NOSCOPE) { const steps = []; const up = await upload('s1_happy_stp.csv'); const id = up.data.ID;
    await call('POST', `${EK(id)}/JournalService.generateProposal`, {});
    await call('POST', `${EK(id)}/JournalService.validateProposal`, {});
    steps.push('approve (no scope) HTTP ' + (await call('POST', `${EK(id)}/JournalService.approve`, {}, NOSCOPE)).status + ' (expect 403)');
    steps.push('post (no scope) HTTP ' + (await call('POST', `${EK(id)}/JournalService.postJournal`, {}, NOSCOPE)).status + ' (expect 403)');
    rec('S8 Role gating (negative)', steps, { caseId: id }); }

  { const r = await call('POST', '/testGuidance', { guidance_ID: GUID, sampleBase64: b64('s1_happy_stp.csv') });
    let p = null; try { p = JSON.parse(r.data.value || r.data); } catch {}
    rec('S9 Guidance test harness (no persistence)', [`testGuidance HTTP ${r.status} source=${p && p.source} balanced=${p && p.balanced} conf=${p && p.overallConfidence} lines=${p && p.lines && p.lines.length}`]); }

  fs.writeFileSync(path.join(__dirname, 'last-results.json'), JSON.stringify(results, null, 2));
  console.log('\n=== DONE ===');
})().catch(e => { console.error('FATAL', e); process.exit(1); });
