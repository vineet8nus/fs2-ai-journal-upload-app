const cds = require('@sap/cds');

/**
 * Toggleable approval (design §8). The toggle is a RULE, not a global switch:
 *
 *   approvalRequired = (lineConfidence < CONF_THRESHOLD)
 *                   || (docAmount      > AMOUNT_THRESHOLD[companyCode])
 *                   || (companyCode in ALWAYS_REVIEW_LIST)
 *
 * Thresholds live in ApprovalPolicies (maintainable without redeploy).
 * "Off" = thresholds set so nothing trips → full straight-through processing.
 */
async function policyFor(companyCode) {
  const { ApprovalPolicies } = cds.entities('journal.upload');
  const specific = companyCode && await SELECT.one.from(ApprovalPolicies)
    .where({ companyCode, active: true });
  if (specific) return specific;
  const def = await SELECT.one.from(ApprovalPolicies).where({ companyCode: '*', active: true });
  return def || { confidenceThreshold: 0.85, amountThreshold: 100000, alwaysReview: false };
}

/**
 * Apply the precondition rule to each line. Mutates line.requiresApproval and
 * returns true if ANY line requires human review.
 */
async function evaluate(lines, companyCode, docAmount) {
  const policy = await policyFor(companyCode);
  let any = false;
  for (const l of lines) {
    const required =
      Number(l.confidence) < Number(policy.confidenceThreshold) ||
      Number(docAmount) > Number(policy.amountThreshold) ||
      !!policy.alwaysReview;
    l.requiresApproval = required;
    if (required) any = true;
  }
  return { requiresApproval: any, policy };
}

module.exports = { evaluate, policyFor };
