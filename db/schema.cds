namespace journal.upload;

using { cuid, managed } from '@sap/cds/common';

/**
 * Posting guidance (natural-language policy). Injected whole into the
 * LLM orchestration prompt (context injection — see design §4).
 */
entity GuidanceDocs : cuid, managed {
  name        : String(120) @mandatory;
  scope       : String(60);                       // e.g. company code / posting type
  content     : LargeString @mandatory;           // the policy text
  version     : Integer default 1;
  active      : Boolean default true;
  rules       : Composition of many MappingRules on rules.guidance = $self;
}

/**
 * Structured, deterministic mapping rules retrieved WITHOUT the LLM
 * (GL determination etc.). Resolved by the validation/orchestration code.
 */
entity MappingRules : cuid {
  guidance        : Association to GuidanceDocs;
  sourceKey       : String(120) @mandatory;       // e.g. cost type / source description
  targetGLAccount : String(10);
  costObject      : String(10);
  description     : String(200);
}

type CaseStatus : String enum {
  Draft; Parsed; Proposed; Validated; PendingApproval; Approved; Rejected; Posted; Failed;
}

/**
 * One upload run: a guidance doc + a data file → proposal → posting.
 */
entity UploadCases : cuid, managed {
  fileName        : String(200);
  guidance        : Association to GuidanceDocs;
  status          : CaseStatus default 'Draft';
  batchId         : String(40);                   // idempotency key root
  companyCode     : String(4);
  rowCount        : Integer default 0;
  message         : String(500);                  // last status / error message
  rawRows         : Composition of many SourceRows on rawRows.![case] = $self;
  proposal        : Composition of one Proposals   on proposal.![case] = $self;
  auditLogs       : Composition of many AuditLogs  on auditLogs.![case] = $self;
}

/** Canonical, parsed representation of an uploaded data row (pre-LLM). */
entity SourceRows : cuid {
  ![case]        : Association to UploadCases;
  lineNo      : Integer;
  rawJson     : LargeString;                       // normalized source cells as JSON
}

entity Proposals : cuid {
  ![case]               : Association to UploadCases;
  balanced           : Boolean default false;
  debitTotal         : Decimal(15,2) default 0;
  creditTotal        : Decimal(15,2) default 0;
  overallConfidence  : Decimal(4,3) default 0;
  validationStatus   : String(20);                 // Pending / Passed / Failed
  lines              : Composition of many ProposalLines on lines.proposal = $self;
}

type ValidationState : String enum { Pending; Passed; Warning; Error; }
type DebitCredit     : String enum { S; H; }       // SAP convention: S=debit, H=credit

entity ProposalLines : cuid {
  proposal         : Association to Proposals;
  lineNo           : Integer;
  glAccount        : String(10);
  glAccountName    : String(120);
  amount           : Decimal(15,2);
  currency         : String(5);
  debitCredit      : DebitCredit;
  costCenter       : String(10);
  profitCenter     : String(10);
  companyCode      : String(4);
  itemText         : String(200);
  // AI grounding + explainability
  confidence       : Decimal(4,3) default 0;
  groundingClause  : String(1000);                 // guidance clause that drove this line
  reasoning        : LargeString;                  // model reasoning (audit evidence)
  // deterministic validation results
  validationStatus : ValidationState default 'Pending';
  validationMsg    : String(500);
  requiresApproval : Boolean default false;
  // idempotency
  lineHash         : String(64);
}

entity AuditLogs : cuid {
  ![case]      : Association to UploadCases;
  event     : String(60);
  actor     : String(120);
  timestamp : Timestamp @cds.on.insert: $now;
  detail    : LargeString;
}

/**
 * Toggleable approval thresholds (design §8). Maintainable without redeploy.
 * "Off" = thresholds set so nothing trips → full straight-through processing.
 */
entity ApprovalPolicies : cuid, managed {
  companyCode       : String(4) @mandatory;        // '*' = default for all
  confidenceThreshold : Decimal(4,3) default 0.85; // lines below this → review
  amountThreshold     : Decimal(15,2) default 100000;
  alwaysReview        : Boolean default false;
  active              : Boolean default true;
}
