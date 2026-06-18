using journal.upload as ju from '../db/schema';

/**
 * AI-Assisted Journal Upload service (OData V4).
 * UI: Fiori Elements List Report / Object Page.
 */
service JournalService @(path: '/journal', requires: 'authenticated-user') {

  @odata.draft.enabled
  entity Cases as projection on ju.UploadCases {
    *,
    case status
      when 'Failed'  then 1 when 'Rejected' then 1
      when 'Proposed' then 2 when 'PendingApproval' then 2
      when 'Validated' then 3 when 'Approved' then 3 when 'Posted' then 3
      else 0
    end as statusCriticality : Integer
  }
  actions {
    // Pipeline (design §6). All deterministic work happens server-side; the
    // LLM only proposes mappings/texts — it never computes balances.
    @Common.SideEffects: { TargetEntities: ['/Cases', 'proposal', 'proposal/lines'] }
    action generateProposal()  returns Cases;
    @Common.SideEffects: { TargetEntities: ['proposal', 'proposal/lines'] }
    action validateProposal()  returns Cases;
    action submitForApproval() returns Cases;
    action approve()           returns Cases        @(requires: 'JournalApprover');
    action rejectCase(reason: String) returns Cases @(requires: 'JournalApprover');
    @Common.SideEffects: { TargetEntities: ['/Cases'] }
    action postJournal()        returns Cases        @(requires: 'JournalApprover');
  };

  entity Proposals     as projection on ju.Proposals;
  entity ProposalLines as projection on ju.ProposalLines {
    *,
    case when confidence >= 0.85 then 3 when confidence >= 0.6 then 2 else 1 end as confidenceCriticality : Integer,
    case validationStatus when 'Passed' then 3 when 'Warning' then 2 when 'Error' then 1 else 0 end as validationCriticality : Integer
  };
  entity SourceRows    as projection on ju.SourceRows;
  entity AuditLogs     as projection on ju.AuditLogs;

  @odata.draft.enabled
  entity Guidance      as projection on ju.GuidanceDocs;
  entity MappingRules  as projection on ju.MappingRules;

  @odata.draft.enabled
  entity ApprovalPolicies as projection on ju.ApprovalPolicies;

  // Upload: create a case from an uploaded data file (base64 content).
  // Parser normalizes rows into SourceRows (design §6.2).
  action uploadData(guidance_ID: UUID, fileName: String, contentBase64: LargeString) returns Cases;

  // Guidance test harness (design differentiator #4): replay a guidance doc
  // against sample data and return the proposal WITHOUT persisting a case.
  action testGuidance(guidance_ID: UUID, sampleBase64: LargeString) returns LargeString;
}
