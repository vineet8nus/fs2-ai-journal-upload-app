const cds = require('@sap/cds');
const { parseFile } = require('./lib/parser');
const { validate } = require('./lib/validator');
const { generate } = require('./lib/orchestrator');
const { score } = require('./lib/scorer');
const approval = require('./lib/approval');
const poster = require('./lib/poster');
const { lineHash } = require('./lib/hash');

module.exports = class JournalService extends cds.ApplicationService {
  async init() {
    const { Cases, Proposals, ProposalLines, SourceRows, AuditLogs, Guidance, MappingRules } = this.entities;

    const audit = (caseID, event, detail, actor) =>
      INSERT.into(AuditLogs).entries({
        case_ID: caseID, event, actor: actor || 'system',
        detail: typeof detail === 'string' ? detail : JSON.stringify(detail)
      });

    const caseKey = (req) => req.params?.[0]?.ID || req.params?.[0] || req.data.ID;

    // ---- Upload data file -> create case + canonical source rows ----------
    this.on('uploadData', async (req) => {
      const { guidance_ID, fileName, contentBase64 } = req.data;
      const parsed = parseFile(contentBase64, fileName);
      if (!parsed.ok) return req.error(400, `Parse failed: ${(parsed.errors || [parsed.error]).join('; ')}`);

      const batchId = 'B' + Date.now().toString(36).toUpperCase();
      const companyCode = parsed.rows.find(r => r.companyCode)?.companyCode
        || process.env.DEFAULT_COMPANY_CODE || '';
      const ID = cds.utils.uuid();
      await INSERT.into(Cases).entries({
        ID, fileName, guidance_ID, status: 'Parsed', batchId, companyCode,
        rowCount: parsed.rows.length
      });
      await INSERT.into(SourceRows).entries(parsed.rows.map(r => ({
        case_ID: ID, lineNo: r.__lineNo, rawJson: JSON.stringify(r)
      })));
      await audit(ID, 'UPLOAD', { fileName, rows: parsed.rows.length, batchId });
      return SELECT.one.from(Cases).where({ ID });
    });

    // ---- Generate proposal (LLM orchestration) ----------------------------
    this.on('generateProposal', async (req) => {
      const ID = caseKey(req);
      const c = await SELECT.one.from(Cases).where({ ID });
      if (!c) return req.error(404, 'Case not found');

      const rows = (await SELECT.from(SourceRows).where({ case_ID: ID }))
        .map(r => JSON.parse(r.rawJson));
      const guidance = c.guidance_ID ? await SELECT.one.from(Guidance).where({ ID: c.guidance_ID }) : null;
      const rules = c.guidance_ID ? await SELECT.from(MappingRules).where({ guidance_ID: c.guidance_ID }) : [];

      const result = await generate(guidance?.content || '', rules, rows);

      // clear any prior proposal (re-run)
      const prior = await SELECT.one.from(Proposals).where({ case_ID: ID });
      if (prior) await DELETE.from(Proposals).where({ ID: prior.ID });

      const proposalID = cds.utils.uuid();
      await INSERT.into(Proposals).entries({ ID: proposalID, case_ID: ID, validationStatus: 'Pending' });
      await INSERT.into(ProposalLines).entries(result.lines.map((l, i) => ({
        ID: cds.utils.uuid(), proposal_ID: proposalID, lineNo: i + 1,
        glAccount: l.glAccount, amount: l.amount, currency: l.currency,
        debitCredit: l.debitCredit, costCenter: l.costCenter, profitCenter: l.profitCenter,
        companyCode: l.companyCode || c.companyCode, itemText: l.itemText,
        groundingClause: l.groundingClause, reasoning: l.reasoning,
        validationStatus: 'Pending'
      })));
      await UPDATE(Cases).set({ status: 'Proposed', message: `Proposal generated (${result.source})` }).where({ ID });
      await audit(ID, 'PROPOSE', { source: result.source, lines: result.lines.length });
      return SELECT.one.from(Cases).where({ ID });
    });

    // ---- Deterministic validation + confidence scoring --------------------
    this.on('validateProposal', async (req) => {
      const ID = caseKey(req);
      const c = await SELECT.one.from(Cases).where({ ID });
      if (!c) return req.error(404, 'Case not found');
      const p = await SELECT.one.from(Proposals).where({ case_ID: ID });
      if (!p) return req.error(400, 'No proposal to validate; generate one first');

      const lines = await SELECT.from(ProposalLines).where({ proposal_ID: p.ID });
      const vr = await validate(lines);            // mutates lines: validationStatus/msg
      const overall = score(lines);                // mutates lines: confidence

      for (const l of lines) {
        await UPDATE(ProposalLines).set({
          validationStatus: l.validationStatus, validationMsg: l.validationMsg,
          confidence: l.confidence, glAccountName: l.glAccountName
        }).where({ ID: l.ID });
      }
      const status = vr.hasError ? 'Failed' : 'Validated';
      await UPDATE(Proposals).set({
        balanced: vr.balanced, debitTotal: vr.debitTotal, creditTotal: vr.creditTotal,
        overallConfidence: overall, validationStatus: vr.hasError ? 'Failed' : 'Passed'
      }).where({ ID: p.ID });
      await UPDATE(Cases).set({
        status,
        message: vr.hasError
          ? `Validation blocked: ${vr.balanced ? '' : 'unbalanced; '}${lines.filter(l => l.validationStatus === 'Error').length} error line(s)`
          : `Validated · confidence ${overall} · ${vr.liveChecks ? 'live master-data checks' : 'master-data skipped'}`
      }).where({ ID });
      await audit(ID, 'VALIDATE', { balanced: vr.balanced, overall, hasError: vr.hasError, liveChecks: vr.liveChecks });
      return SELECT.one.from(Cases).where({ ID });
    });

    // ---- Toggleable approval (state machine) ------------------------------
    this.on('submitForApproval', async (req) => {
      const ID = caseKey(req);
      const c = await SELECT.one.from(Cases).where({ ID });
      if (!c) return req.error(404, 'Case not found');
      if (c.status !== 'Validated') return req.error(400, `Case must be Validated (is ${c.status})`);
      const p = await SELECT.one.from(Proposals).where({ case_ID: ID });
      const lines = await SELECT.from(ProposalLines).where({ proposal_ID: p.ID });

      const { requiresApproval, policy } = await approval.evaluate(lines, c.companyCode, Number(p.debitTotal));
      for (const l of lines) {
        await UPDATE(ProposalLines).set({ requiresApproval: l.requiresApproval }).where({ ID: l.ID });
      }
      const status = requiresApproval ? 'PendingApproval' : 'Approved';
      await UPDATE(Cases).set({
        status,
        message: requiresApproval
          ? `Routed to approval (conf<${policy.confidenceThreshold} or amount>${policy.amountThreshold})`
          : 'Straight-through (no approval trip)'
      }).where({ ID });
      await audit(ID, 'APPROVAL_ROUTE', { requiresApproval, policy });
      return SELECT.one.from(Cases).where({ ID });
    });

    this.on('approve', async (req) => {
      const ID = caseKey(req);
      await UPDATE(Cases).set({ status: 'Approved', message: 'Approved' }).where({ ID });
      await audit(ID, 'APPROVE', { by: req.user.id }, req.user.id);
      return SELECT.one.from(Cases).where({ ID });
    });

    this.on('rejectCase', async (req) => {
      const ID = caseKey(req);
      await UPDATE(Cases).set({ status: 'Rejected', message: `Rejected: ${req.data.reason || ''}` }).where({ ID });
      await audit(ID, 'REJECT', { reason: req.data.reason, by: req.user.id }, req.user.id);
      return SELECT.one.from(Cases).where({ ID });
    });

    // ---- Idempotent posting -----------------------------------------------
    this.on('postJournal', async (req) => {
      const ID = caseKey(req);
      const c = await SELECT.one.from(Cases).where({ ID });
      if (!c) return req.error(404, 'Case not found');
      if (c.status !== 'Approved') return req.error(400, `Case must be Approved (is ${c.status})`);
      const p = await SELECT.one.from(Proposals).where({ case_ID: ID });
      let lines = await SELECT.from(ProposalLines).where({ proposal_ID: p.ID });

      // compute idempotency hashes
      lines = lines.map(l => ({ ...l, lineHash: lineHash(c.batchId, l) }));
      for (const l of lines) await UPDATE(ProposalLines).set({ lineHash: l.lineHash }).where({ ID: l.ID });

      try {
        const result = await poster.post(c, lines);
        await UPDATE(Cases).set({ status: 'Posted', message: `Posted ${result.belnr} (${result.mode})` }).where({ ID });
        await audit(ID, 'POST', { belnr: result.belnr, mode: result.mode });
      } catch (e) {
        await UPDATE(Cases).set({ status: 'Failed', message: `Posting failed: ${e.message}` }).where({ ID });
        await audit(ID, 'POST_FAILED', { error: e.message });
        return req.error(502, `Posting failed: ${e.message}`);
      }
      return SELECT.one.from(Cases).where({ ID });
    });

    // ---- Guidance test harness (no persistence) ---------------------------
    this.on('testGuidance', async (req) => {
      const { guidance_ID, sampleBase64 } = req.data;
      const parsed = parseFile(sampleBase64, 'sample');
      if (!parsed.ok) return req.error(400, `Parse failed: ${(parsed.errors || [parsed.error]).join('; ')}`);
      const guidance = await SELECT.one.from(Guidance).where({ ID: guidance_ID });
      const rules = await SELECT.from(MappingRules).where({ guidance_ID });
      const result = await generate(guidance?.content || '', rules, parsed.rows);
      const vr = await validate(result.lines.map(l => ({ ...l })));
      const overall = score(vr.lines);
      return JSON.stringify({ source: result.source, balanced: vr.balanced, overallConfidence: overall, lines: vr.lines }, null, 2);
    });

    return super.init();
  }
};
