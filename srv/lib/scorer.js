/**
 * Per-line confidence scoring (design §6.6). Deterministic and explainable —
 * confidence reflects how well-grounded a line is, NOT model self-reporting.
 *
 * Factors:
 *   + GL account present & validated against S/4
 *   + grounding clause found in guidance
 *   + mapped via an explicit deterministic rule
 *   - validation warnings / missing master data
 */
function scoreLine(line) {
  let score = 0.5;
  if (line.glAccount) score += 0.15;
  if (line.validationStatus === 'Passed') score += 0.25;
  else if (line.validationStatus === 'Warning') score += 0.05;
  else if (line.validationStatus === 'Error') score -= 0.4;
  if (line.groundingClause && !/no specific clause/i.test(line.groundingClause)) score += 0.1;
  if (/mapped via rule/i.test(line.reasoning || '')) score += 0.05;
  if (!line.costCenter && !line.profitCenter) score -= 0.02;
  return Math.max(0, Math.min(1, Number(score.toFixed(3))));
}

function score(lines) {
  lines.forEach(l => { l.confidence = scoreLine(l); });
  const overall = lines.length
    ? Number((lines.reduce((s, l) => s + l.confidence, 0) / lines.length).toFixed(3))
    : 0;
  return overall;
}

module.exports = { score, scoreLine };
