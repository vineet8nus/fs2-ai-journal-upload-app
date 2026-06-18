const XLSX = require('xlsx');

/**
 * Deterministic Excel/CSV parser (design §6.2 + §7 structural checks).
 * Normalizes an uploaded file (base64) into canonical rows. The LLM is
 * NEVER called on malformed input — we fail fast here.
 *
 * Canonical row keys (case-insensitive header mapping):
 *   description | text | narrative   -> description
 *   amount | value                   -> amount (numeric)
 *   glaccount | gl | account         -> glAccount (optional hint)
 *   costcenter | costobject          -> costCenter (optional hint)
 *   companycode | bukrs              -> companyCode
 *   currency | waers                 -> currency
 *   debitcredit | dc | sign          -> debitCredit (S/H)
 */
const HEADER_MAP = {
  description: 'description', text: 'description', narrative: 'description', memo: 'description',
  amount: 'amount', value: 'amount', betrag: 'amount',
  glaccount: 'glAccount', gl: 'glAccount', account: 'glAccount', hkont: 'glAccount',
  costcenter: 'costCenter', costobject: 'costCenter', kostl: 'costCenter',
  profitcenter: 'profitCenter', prctr: 'profitCenter',
  companycode: 'companyCode', bukrs: 'companyCode', cocd: 'companyCode',
  currency: 'currency', waers: 'currency', curr: 'currency',
  debitcredit: 'debitCredit', dc: 'debitCredit', sign: 'debitCredit', shkzg: 'debitCredit',
  itemtext: 'itemText', sgtxt: 'itemText'
};

function normalizeHeader(h) {
  const key = String(h || '').toLowerCase().replace(/[^a-z]/g, '');
  return HEADER_MAP[key] || key;
}

// SAP master-data keys are fixed-width, zero-padded strings. Spreadsheet
// parsers strip leading zeros from numeric-looking codes (0000400000 -> 400000),
// which would break exact-match master-data lookups. Re-pad numeric codes.
const CODE_WIDTHS = { glAccount: 10, costCenter: 10, profitCenter: 10, companyCode: 4 };
function padCode(field, value) {
  if (value == null || value === '') return value;
  const s = String(value).trim();
  const w = CODE_WIDTHS[field];
  if (w && /^[0-9]+$/.test(s) && s.length < w) return s.padStart(w, '0');
  return s;
}

function parseFile(contentBase64, fileName = 'upload') {
  const buf = Buffer.from(contentBase64, 'base64');
  let wb;
  try {
    wb = XLSX.read(buf, { type: 'buffer', cellDates: false });
  } catch (e) {
    return { ok: false, error: `Unreadable file: ${e.message}` };
  }
  const sheetName = wb.SheetNames[0];
  if (!sheetName) return { ok: false, error: 'No worksheet found in file' };
  const sheet = wb.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet, { defval: null, raw: true });
  if (!rows.length) return { ok: false, error: 'File contains no data rows' };

  const canonical = [];
  const errors = [];
  rows.forEach((r, i) => {
    const out = {};
    for (const [k, v] of Object.entries(r)) out[normalizeHeader(k)] = v;
    // preserve SAP code widths (leading zeros)
    for (const f of Object.keys(CODE_WIDTHS)) if (out[f] != null) out[f] = padCode(f, out[f]);
    // structural checks (deterministic pre-check — design §6.3)
    if (out.amount != null) {
      const n = Number(String(out.amount).replace(/,/g, ''));
      if (Number.isNaN(n)) errors.push(`Row ${i + 1}: amount "${out.amount}" is not numeric`);
      else out.amount = n;
    }
    if (out.description == null && out.glAccount == null) {
      errors.push(`Row ${i + 1}: needs at least a description or a GL account`);
    }
    out.__lineNo = i + 1;
    canonical.push(out);
  });

  return { ok: errors.length === 0, errors, rows: canonical, sheetName, fileName };
}

module.exports = { parseFile, normalizeHeader };
