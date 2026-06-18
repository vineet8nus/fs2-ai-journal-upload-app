const crypto = require('crypto');

/**
 * Idempotency key (design §9). A replayed batch produces identical line
 * hashes, so the posting adapter can dedupe and never double-post.
 */
function lineHash(batchId, line) {
  const basis = [
    batchId,
    line.glAccount,
    line.amount,
    line.debitCredit,
    line.costCenter || '',
    line.companyCode || '',
    line.lineNo
  ].join('|');
  return crypto.createHash('sha256').update(basis).digest('hex');
}

module.exports = { lineHash };
