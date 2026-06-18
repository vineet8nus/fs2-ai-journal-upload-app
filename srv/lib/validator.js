const cds = require('@sap/cds');

/**
 * Deterministic validation engine (design §7). Runs in CAP, NEVER in the LLM.
 * Master-data existence is checked against the live S/4 system via the
 * verified standard released API `API_JOURNALENTRYITEMBASIC_SRV`, which
 * exposes A_GLAccountInChartOfAccounts, A_CostCenter, A_CompanyCode.
 *
 * MASTERDATA_MODE=live (default) | skip — skip lets the pipeline run in
 * local/offline demos without S/4 connectivity (checks become Warnings).
 */
const ROUNDING_TOLERANCE = Number(process.env.BALANCE_TOLERANCE || '0.01');
const MASTERDATA_MODE = process.env.MASTERDATA_MODE || 'live';

const LOG = cds.log('validation');

async function s4() {
  try {
    return await cds.connect.to('API_JOURNALENTRYITEMBASIC_SRV');
  } catch (e) {
    LOG.warn('S/4 master-data service unavailable:', e.message);
    return null;
  }
}

/** Resolve ChartOfAccounts for a company code (cached per run). */
async function companyCodeInfo(srv, companyCode, cache) {
  if (!companyCode) return null;
  if (cache.cc.has(companyCode)) return cache.cc.get(companyCode);
  const { A_CompanyCode } = srv.entities;
  let row = null;
  try {
    row = await srv.run(SELECT.one.from(A_CompanyCode).where({ CompanyCode: companyCode }));
  } catch (e) { LOG.warn('CompanyCode read failed', companyCode, e.message); }
  cache.cc.set(companyCode, row);
  return row;
}

async function glExists(srv, chartOfAccounts, glAccount, cache) {
  const key = `${chartOfAccounts}/${glAccount}`;
  if (cache.gl.has(key)) return cache.gl.get(key);
  const { A_GLAccountInChartOfAccounts } = srv.entities;
  let row = null;
  try {
    row = await srv.run(SELECT.one.from(A_GLAccountInChartOfAccounts)
      .where({ ChartOfAccounts: chartOfAccounts, GLAccount: glAccount }));
  } catch (e) { LOG.warn('GL read failed', key, e.message); }
  cache.gl.set(key, row);
  return row;
}

async function costCenterExists(srv, costCenter, cache) {
  if (cache.cc2.has(costCenter)) return cache.cc2.get(costCenter);
  const { A_CostCenter } = srv.entities;
  let row = null;
  try {
    // existence + currently valid (ValidityEndDate >= today)
    const today = new Date().toISOString().slice(0, 10);
    row = await srv.run(SELECT.one.from(A_CostCenter)
      .where({ CostCenter: costCenter, ValidityEndDate: { '>=': today } }));
  } catch (e) { LOG.warn('CostCenter read failed', costCenter, e.message); }
  cache.cc2.set(costCenter, row);
  return row;
}

/**
 * Validate a proposal (array of line objects). Mutates each line with
 * validationStatus ('Passed' | 'Warning' | 'Error') + validationMsg.
 * Returns { balanced, debitTotal, creditTotal, hasError, lines }.
 */
async function validate(lines) {
  const cache = { cc: new Map(), gl: new Map(), cc2: new Map() };
  const srv = MASTERDATA_MODE === 'skip' ? null : await s4();
  const liveChecks = !!srv;

  // 1. Financial: debits = credits per document (design §7 Financial).
  let debit = 0, credit = 0;
  for (const l of lines) {
    const amt = Number(l.amount || 0);
    if (l.debitCredit === 'H') credit += amt; else debit += amt;
  }
  const balanced = Math.abs(debit - credit) <= ROUNDING_TOLERANCE;

  // 2. Per-line structural + master-data checks.
  for (const l of lines) {
    const msgs = [];
    let state = 'Passed';

    if (l.amount == null || Number.isNaN(Number(l.amount)) || Number(l.amount) === 0) {
      msgs.push('Amount missing or zero'); state = 'Error';
    }
    if (!l.glAccount) {
      msgs.push('GL account missing'); state = 'Error';
    }
    if (l.debitCredit !== 'S' && l.debitCredit !== 'H') {
      msgs.push('Debit/Credit indicator must be S or H'); state = 'Error';
    }

    if (state !== 'Error') {
      if (!liveChecks) {
        msgs.push('Master-data check skipped (no S/4 connectivity)');
        if (state === 'Passed') state = 'Warning';
      } else {
        const cc = await companyCodeInfo(srv, l.companyCode, cache);
        const coa = cc && cc.ChartOfAccounts;
        if (l.companyCode && !cc) { msgs.push(`Company code ${l.companyCode} not found`); state = 'Error'; }

        if (l.glAccount && coa) {
          const gl = await glExists(srv, coa, l.glAccount, cache);
          if (!gl) { msgs.push(`GL account ${l.glAccount} not in CoA ${coa}`); state = 'Error'; }
          else {
            if (gl.AccountIsBlockedForPosting) { msgs.push(`GL ${l.glAccount} blocked for posting`); state = 'Error'; }
            if (gl.AccountIsMarkedForDeletion) { msgs.push(`GL ${l.glAccount} marked for deletion`); state = 'Error'; }
            l.glAccountName = l.glAccountName || gl.GLAccountExternal || l.glAccount;
          }
        } else if (l.glAccount && !coa) {
          msgs.push('Cannot verify GL account: chart of accounts unknown'); state = state === 'Passed' ? 'Warning' : state;
        }

        if (l.costCenter) {
          const cstr = await costCenterExists(srv, l.costCenter, cache);
          if (!cstr) { msgs.push(`Cost center ${l.costCenter} not found / not valid`); state = 'Error'; }
          else if (cstr.IsBlkdForPrimaryCostsPosting === 'X') { msgs.push(`Cost center ${l.costCenter} blocked for primary postings`); state = 'Error'; }
        }
      }
    }

    l.validationStatus = state;
    l.validationMsg = msgs.join('; ') || 'OK';
  }

  const hasError = lines.some(l => l.validationStatus === 'Error') || !balanced;
  return {
    balanced,
    debitTotal: Number(debit.toFixed(2)),
    creditTotal: Number(credit.toFixed(2)),
    hasError,
    liveChecks,
    lines
  };
}

module.exports = { validate };
