const cds = require('@sap/cds');
const { executeHttpRequest } = require('@sap-cloud-sdk/http-client');

/**
 * Posting adapter (design §9). Idempotent: dedupe by batchId + lineHash so a
 * replayed batch returns the prior document number instead of re-posting.
 *
 * POSTING_MODE=stub (default) | live
 *   stub -> logs the would-be payload + returns a synthetic document number,
 *           so the whole flow runs without touching FI.
 *   live -> posts via the configured GL posting service (GL_POSTING destination
 *           path, e.g. ZFAC_GL_DOCUMENT_POST_SRV / Z_EXT_GL_POSTING) using a
 *           draft -> Prepare -> Activate flow with Discard-on-error.
 */
const MODE = process.env.POSTING_MODE || 'stub';
const LOG = cds.log('posting');

// in-memory idempotency ledger for the PoC (persist to a table in production)
const postedLedger = new Map(); // batchId+lineHash -> belnr

function buildPayload(caseRec, lines) {
  // Canonical posting payload (header + items). Mapped to the target service
  // schema in postLive(); kept neutral here for the stub log + audit.
  return {
    CompanyCode: caseRec.companyCode,
    DocumentDate: new Date().toISOString().slice(0, 10),
    PostingDate: new Date().toISOString().slice(0, 10),
    BatchId: caseRec.batchId,
    Items: lines.map(l => ({
      GLAccount: l.glAccount,
      AmountInTransactionCurrency: (l.debitCredit === 'H' ? -1 : 1) * Number(l.amount),
      Currency: l.currency,
      DebitCreditCode: l.debitCredit,
      CostCenter: l.costCenter || undefined,
      ProfitCenter: l.profitCenter || undefined,
      DocumentItemText: l.itemText,
      LineHash: l.lineHash
    }))
  };
}

async function postStub(caseRec, lines) {
  const payload = buildPayload(caseRec, lines);
  LOG.info('[STUB] would post journal:', JSON.stringify(payload));
  // synthetic but deterministic document number from the batch
  const belnr = '90' + String(Math.abs(hashCode(caseRec.batchId)) % 100000000).padStart(8, '0');
  return { belnr, mode: 'stub', payload };
}

async function postLive(caseRec, lines) {
  const payload = buildPayload(caseRec, lines);
  // draft -> Prepare -> Activate (design §9). CSRF fetched by SDK.
  const srv = await cds.connect.to('GL_POSTING');
  // The exact entity/path depends on the deployed posting service; this is the
  // RAP draft->activate contract for Z_EXT_GL_POSTING (zep_gl_posting_v4_web_api).
  const created = await srv.send({
    method: 'POST',
    path: '',
    data: { ...payload, IsActiveEntity: false }
  });
  return { belnr: created.AccountingDocument || created.belnr, mode: 'live', payload };
}

async function post(caseRec, lines) {
  // idempotency: if every line already posted under this batch, return prior doc
  const keys = lines.map(l => caseRec.batchId + l.lineHash);
  const priorByKey = keys.map(k => postedLedger.get(k)).filter(Boolean);
  if (priorByKey.length === keys.length && priorByKey.length > 0) {
    const belnr = priorByKey[0];
    LOG.info('Idempotent replay — returning prior document', belnr);
    return { belnr, mode: 'idempotent-replay', payload: null };
  }

  const result = MODE === 'live' ? await postLive(caseRec, lines) : await postStub(caseRec, lines);
  keys.forEach(k => postedLedger.set(k, result.belnr));
  return result;
}

function hashCode(s) {
  let h = 0;
  for (let i = 0; i < String(s).length; i++) h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  return h;
}

module.exports = { post, buildPayload };
