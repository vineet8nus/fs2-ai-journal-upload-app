using JournalService as service from './service';

////////////////////////////////////////////////////////////////////////////
// Cases — List Report + Object Page
////////////////////////////////////////////////////////////////////////////
annotate service.Cases with @(
  UI.HeaderInfo: {
    TypeName      : 'Upload Case',
    TypeNamePlural: 'Upload Cases',
    Title         : { Value: fileName },
    Description   : { Value: status }
  },
  UI.SelectionFields: [ status, companyCode ],
  UI.LineItem: [
    { Value: fileName,    Label: 'File' },
    { Value: status,      Label: 'Status', Criticality: statusCriticality },
    { Value: companyCode, Label: 'Company Code' },
    { Value: rowCount,    Label: 'Rows' },
    { Value: batchId,     Label: 'Batch' },
    { Value: message,     Label: 'Message' },
    { Value: createdAt,   Label: 'Created' }
  ],
  UI.Identification: [
    { $Type: 'UI.DataFieldForAction', Action: 'JournalService.generateProposal',  Label: 'Generate Proposal' },
    { $Type: 'UI.DataFieldForAction', Action: 'JournalService.validateProposal',  Label: 'Validate' },
    { $Type: 'UI.DataFieldForAction', Action: 'JournalService.submitForApproval', Label: 'Submit for Approval' },
    { $Type: 'UI.DataFieldForAction', Action: 'JournalService.approve',           Label: 'Approve' },
    { $Type: 'UI.DataFieldForAction', Action: 'JournalService.rejectCase',            Label: 'Reject' },
    { $Type: 'UI.DataFieldForAction', Action: 'JournalService.postJournal',              Label: 'Post', Criticality: #Positive }
  ],
  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', ID: 'General',  Label: 'Case', Target: '@UI.FieldGroup#General' },
    { $Type: 'UI.ReferenceFacet', ID: 'ProposalLines', Label: 'Proposal Lines', Target: 'proposal/lines/@UI.LineItem' },
    { $Type: 'UI.ReferenceFacet', ID: 'Audit',    Label: 'Audit Trail', Target: 'auditLogs/@UI.LineItem' }
  ],
  UI.FieldGroup #General: { Data: [
    { Value: fileName,    Label: 'File' },
    { Value: status,      Label: 'Status', Criticality: statusCriticality },
    { Value: companyCode, Label: 'Company Code' },
    { Value: batchId,     Label: 'Batch ID' },
    { Value: rowCount,    Label: 'Rows' },
    { Value: message,     Label: 'Message' }
  ]}
);

////////////////////////////////////////////////////////////////////////////
// Proposal lines — confidence, grounding, validation
////////////////////////////////////////////////////////////////////////////
annotate service.ProposalLines with @(
  UI.LineItem: [
    { Value: lineNo,            Label: '#' },
    { Value: glAccount,         Label: 'GL Account' },
    { Value: glAccountName,     Label: 'GL Name' },
    { Value: debitCredit,       Label: 'D/C' },
    { Value: amount,            Label: 'Amount' },
    { Value: currency,          Label: 'Curr' },
    { Value: costCenter,        Label: 'Cost Center' },
    { Value: confidence,        Label: 'Confidence', Criticality: confidenceCriticality },
    { Value: validationStatus,  Label: 'Validation', Criticality: validationCriticality },
    { Value: validationMsg,     Label: 'Detail' },
    { Value: requiresApproval,  Label: 'Needs Approval' },
    { Value: itemText,          Label: 'Item Text' },
    { Value: groundingClause,   Label: 'Grounding Clause' }
  ],
  UI.HeaderInfo: {
    TypeName: 'Proposal Line', TypeNamePlural: 'Proposal Lines',
    Title: { Value: glAccount }, Description: { Value: itemText }
  },
  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Posting', Target: '@UI.FieldGroup#Posting' },
    { $Type: 'UI.ReferenceFacet', Label: 'AI Grounding & Reasoning', Target: '@UI.FieldGroup#Grounding' }
  ],
  UI.FieldGroup #Posting: { Data: [
    { Value: glAccount }, { Value: glAccountName }, { Value: debitCredit }, { Value: amount },
    { Value: currency }, { Value: costCenter }, { Value: profitCenter }, { Value: companyCode },
    { Value: validationStatus, Criticality: validationCriticality }, { Value: validationMsg }
  ]},
  UI.FieldGroup #Grounding: { Data: [
    { Value: confidence, Criticality: confidenceCriticality },
    { Value: groundingClause }, { Value: reasoning }, { Value: requiresApproval }
  ]}
);

////////////////////////////////////////////////////////////////////////////
// Audit log line items
////////////////////////////////////////////////////////////////////////////
annotate service.AuditLogs with @(
  UI.LineItem: [
    { Value: timestamp, Label: 'Time' },
    { Value: event,     Label: 'Event' },
    { Value: actor,     Label: 'Actor' },
    { Value: detail,    Label: 'Detail' }
  ]
);

////////////////////////////////////////////////////////////////////////////
// Guidance docs
////////////////////////////////////////////////////////////////////////////
annotate service.Guidance with @(
  UI.HeaderInfo: { TypeName: 'Guidance', TypeNamePlural: 'Guidance Documents', Title: { Value: name } },
  UI.LineItem: [
    { Value: name,    Label: 'Name' },
    { Value: scope,   Label: 'Scope' },
    { Value: version, Label: 'Version' },
    { Value: active,  Label: 'Active' }
  ],
  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Content', Target: '@UI.FieldGroup#Content' },
    { $Type: 'UI.ReferenceFacet', Label: 'Mapping Rules', Target: 'rules/@UI.LineItem' }
  ],
  UI.FieldGroup #Content: { Data: [
    { Value: name }, { Value: scope }, { Value: version }, { Value: active }, { Value: content }
  ]}
);

annotate service.MappingRules with @(
  UI.LineItem: [
    { Value: sourceKey,       Label: 'Source Key' },
    { Value: targetGLAccount, Label: 'GL Account' },
    { Value: costObject,      Label: 'Cost Object' },
    { Value: description,     Label: 'Description' }
  ]
);
