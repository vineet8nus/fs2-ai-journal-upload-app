# AI-Assisted Journal Upload — Design Document & Build Plan (PoC)

**Target platform:** SAP BTP (Cloud Foundry) · **Stack:** CAP (Node.js) + UI5/Fiori Elements + SAP AI Core (Generative AI Hub)
**S/4 connectivity:** Destination `SHD250SYSTEM` (configurable) · **Posting service:** existing `Z_EXT_GL_POSTING` (RAP, draft→activate)
**Status:** PoC scope — real grounding + validation + confidence; posting behind a feature flag (stub default, live optional)

---

## 1. Purpose & scope

Build a journal-upload assistant that improves on SAP's standard "AI-assisted journal upload" rather than cloning it. A user uploads a natural-language **guidance document** (posting policy) plus a **data file** (Excel/CSV); the system generates policy-compliant posting proposals, validates them deterministically, scores confidence, routes through a **toggleable approval step**, and posts to S/4.

In scope for the PoC: guidance management, data upload + parse, proposal generation (LLM), deterministic validation, confidence scoring, toggleable approval, audit trail, and a posting adapter wired to `Z_EXT_GL_POSTING` (stub by default).
Out of scope for the PoC: vector retrieval, learning/feedback loop automation, multi-document grounding at scale (designed for, not built).

---

## 2. What makes it better than SAP standard

| # | Differentiator | SAP standard | This design |
|---|----------------|--------------|-------------|
| 1 | **Deterministic-first validation** | Single LLM pass | Rules engine validates schema, balance = 0, GL/cost-object existence **before** the proposal is shown. LLM never does arithmetic or master-data checks. |
| 2 | **Grounded explainability** | Proposal only | Each line carries the guidance clause that drove it + model reasoning, persisted as audit evidence. |
| 3 | **Confidence-based STP** | Amount-threshold workflow | Per-line confidence score; toggle = **confidence × amount × company code**. High-confidence lines straight-through; low-confidence routed to human. |
| 4 | **Guidance test harness** | None | Replay a guidance doc against sample data and diff output before it goes live. |
| 5 | **Idempotent posting** | Batch ID | Dedupe by `batchId + lineHash`; retries never double-post. |
| 6 | **Feedback capture** | None | Accept/edit/reject decisions stored to improve few-shot examples later (designed-for). |

---

## 3. Solution architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  UI5 / Fiori Elements app  (Upload guidance · Upload data ·            │
│  Review proposals w/ confidence + grounding + validation · Approve)    │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │ OData V4 (CAP)
┌───────────────────────────────▼──────────────────────────────────────┐
│  CAP service (Node.js) on BTP CF                                       │
│   ├─ Guidance store      (HANA / sqlite-PoC)                           │
│   ├─ Excel/CSV parser     (XCO / SheetJS)                              │
│   ├─ Deterministic validation engine  (schema, balance, master data)  │
│   ├─ LLM orchestration    → SAP AI Core / Generative AI Hub            │
│   ├─ Confidence scorer + toggleable approval state machine            │
│   └─ Posting adapter      → Z_EXT_GL_POSTING (feature-flagged)         │
└──────┬───────────────────────────────┬───────────────────────────────┘
       │ Destination: AICORE           │ Destination: SHD250SYSTEM (cfg)
┌──────▼──────────┐            ┌────────▼──────────────────────────────┐
│ SAP AI Core     │            │ S/4HANA  (master-data reads + posting)│
│ Gen AI Hub      │            │ Z_EXT_GL_POSTING (RAP draft→activate)  │
└─────────────────┘            └───────────────────────────────────────┘
```

---

## 4. Grounding / RAG decision — no vectors for the PoC

Vectors solve a retrieval problem you don't have yet. Storage ≠ retrieval ≠ grounding.

| Approach | Cost | When to use | PoC? |
|----------|------|-------------|------|
| **Context injection** (load full guidance doc into the prompt) | ~free | Docs ≤ ~50k tokens; one policy per case | ✅ **Default** |
| HANA Cloud native vectors (`REAL_VECTOR`) | low (no separate vector DB) | Many/large docs | Future only |
| HANA fuzzy / full-text retrieval | low | Term-matchable lookups | Future only |
| Structured rules in tables/CDS | low | GL determination, mapping rules | ✅ for rules portion |
| Dropbox / external store | n/a | **Not recommended** — storage only, adds auth + data-residency baggage | ❌ |

**Decision:** store guidance text in a CAP entity (`GuidanceDoc.content`) and inject the relevant doc whole into the orchestration prompt. Structured mapping rules (e.g. GL determination) live in a `MappingRule` table and are retrieved deterministically, not via the LLM. Graduate to HANA `REAL_VECTOR` only if guidance volume outgrows the context window.

---

## 5. Data model (CAP entities)

```cds
entity GuidanceDoc      { key ID: UUID; name: String; scope: String;  // e.g. company code / posting type
                          content: LargeString; version: Integer; active: Boolean; }
entity MappingRule      { key ID: UUID; guidance: Association to GuidanceDoc;
                          sourceKey: String; targetGLAccount: String; costObject: String; }
entity UploadCase       { key ID: UUID; fileName: String; guidance: Association to GuidanceDoc;
                          status: String enum { Draft; Proposed; Validated; PendingApproval; Posted; Failed; };
                          batchId: String; }
entity Proposal         { key ID: UUID; case: Association to UploadCase; balanced: Boolean;
                          overallConfidence: Decimal; }
entity ProposalLine     { key ID: UUID; proposal: Association to Proposal;
                          glAccount: String; amount: Decimal; debitCredit: String; costObject: String;
                          confidence: Decimal; groundingClause: String; reasoning: LargeString;
                          lineHash: String; validationStatus: String; }
entity AuditLog         { key ID: UUID; case: Association to UploadCase; event: String;
                          actor: String; timestamp: Timestamp; detail: LargeString; }
```

---

## 6. Core flow

1. **Upload guidance** → stored/versioned; optional test-harness replay against sample data.
2. **Upload data file** → parser normalizes rows into a canonical structure.
3. **Deterministic pre-checks** → schema valid, columns present, amounts numeric. Fail fast; the LLM is never called on malformed input.
4. **Generate proposal (LLM)** → orchestration prompt = canonical rows + injected guidance + deterministic mapping rules. Output: structured lines, each with grounding clause + reasoning. **The LLM proposes mappings/texts; it does not compute balances.**
5. **Deterministic validation** → balance = 0 per document, GL account exists, cost object exists, company-code validity. (Master-data existence checked via S/4 OData reads over `SHD250SYSTEM`.)
6. **Confidence scoring** → per line; `overallConfidence` aggregated.
7. **Toggleable approval** → precondition rule decides STP vs human review (see §8).
8. **Post** → idempotent; via posting adapter (§9).
9. **Audit** → every step + decision persisted.

---

## 7. Deterministic validation engine

Runs in CAP, **never** in the LLM. Checks:
- Structural: required columns, data types, date formats.
- Financial: debits = credits per document; rounding tolerance configurable.
- Master data (via S/4 reads over the destination): GL account exists & open for posting, cost center/order valid, company code valid, currency valid.
- Policy: posting period open, document type allowed for the scenario.

Each failure attaches to the line (`validationStatus`) with a human-readable message. A proposal cannot reach `Validated` with any severity-error line.

---

## 8. Toggleable approval (the on/off step)

Mirror SAP's precondition pattern, but richer. The toggle is a **rule**, not a global switch:

```
approvalRequired = (lineConfidence < CONF_THRESHOLD)
                || (docAmount     > AMOUNT_THRESHOLD[companyCode])
                || (companyCode in ALWAYS_REVIEW_LIST)
```

- All thresholds are config (CAP entity `ApprovalPolicy`), maintainable without redeploy.
- "Off" = thresholds set so nothing trips → full straight-through processing.
- PoC implements an in-app state machine (`PendingApproval → Approved/Rejected`). Production swaps in **SAP Build Process Automation** with the same precondition contract.

---

## 9. S/4 integration & destination config

- **Connectivity:** SAP Cloud SDK via BTP **Destination Service**. Destination name is **not hardcoded** — read from env `DESTINATION_NAME` (default `SHD250SYSTEM`), `AUTH_MODE=btp` on CF / `local` for dev, `SAP_CLIENT=250`.
- **Master-data reads:** released `API_*` OData for GL account / cost object / company code existence.
- **Posting:** reuse the existing **`Z_EXT_GL_POSTING`** RAP service (`zep_gl_posting_v4_web_api`), draft→activate flow:
  `POST (IsActiveEntity=false)` → `Prepare` (validates) → `Activate` (returns `belnr`) → read-back; `Discard` on any failure to avoid orphaned drafts. V4 needs CSRF on the initial draft POST; `If-Match: *` on Activate.
- **Idempotency:** posting adapter checks `batchId + lineHash` before draft create; a replayed batch returns the prior `belnr` instead of re-posting.
- **Feature flag:** `POSTING_MODE=stub|live`. PoC default `stub` (logs the would-be payload + returns a synthetic doc number) so the whole flow runs without touching FI.

```typescript
// destination resolution — configurable, never hardcoded
const DEST = process.env.DESTINATION_NAME || "SHD250SYSTEM";
await executeHttpRequest({ destinationName: DEST }, { /* ... */ });
```

---

## 10. Security & auth

- **XSUAA** for app auth; role `JournalUploader`, `JournalApprover`.
- **Destination Service** + (optional) **Connectivity Service** for S/4 reach (Cloud Connector if S/4 is on-prem/private).
- **AI Core** bound via service key / destination `AICORE`; prompts run through the Generative AI Hub **orchestration** service (enables data masking + templating). No PII in logs.

---

## 11. BTP services to provision

```bash
cf create-service destination          lite          jrnl-destination
cf create-service xsuaa                application   jrnl-xsuaa     -c xs-security.json
cf create-service hana                  hdi-shared    jrnl-db        # (or sqlite for first PoC pass)
cf create-service aicore               <plan>        jrnl-aicore    # Generative AI Hub
```

Destinations in BTP cockpit: `SHD250SYSTEM` (HTTP, to S/4) and `AICORE` (to AI Core).

---

## 12. Build plan (phased)

**Phase 0 — Foundation (0.5–1 day)**
- Scaffold CAP project in SAP Build Code; bind destination + xsuaa (+ hana/sqlite).
- Configure `SHD250SYSTEM` destination; smoke-test an S/4 OData read.
- Wire AI Core / Gen AI Hub; smoke-test a prompt round-trip.

**Phase 1 — Core pipeline (2–3 days)**
- Data model (§5), Excel/CSV parser, upload endpoints.
- Deterministic pre-checks + validation engine (§6–7) with S/4 master-data reads.
- LLM orchestration with context injection (§4) + grounding capture.

**Phase 2 — Confidence + approval (1–2 days)**
- Confidence scorer, `ApprovalPolicy`, toggleable state machine (§8).
- Audit trail.

**Phase 3 — Posting adapter (1 day)**
- `Z_EXT_GL_POSTING` adapter with draft→activate, Discard-on-error, idempotency, `POSTING_MODE` flag (§9).

**Phase 4 — UI (2–3 days)**
- Fiori Elements List Report (cases) + Object Page (proposal review: lines, confidence, grounding, validation, approve/reject); freestyle upload dialog.

**Phase 5 — Harden + demo (1 day)**
- Guidance test harness, error handling, `cf push`, end-to-end demo script.

---

## 13. Repo structure

```
journal-upload-ai/
├─ db/            schema.cds, sample data
├─ srv/           service.cds, handlers (parse, validate, orchestrate, score, post)
│  └─ external/   SHD250SYSTEM (S/4) + AICORE service consumption
├─ app/           UI5 / Fiori Elements
├─ xs-security.json
├─ mta.yaml       (or manifest.yaml)
└─ .env           (local dev only)
```

---

## 14. Prerequisites & open items

- [ ] **AI Core / Generative AI Hub** entitlement active in the BTP subaccount (model access — GPT-4o / Claude / etc.).
- [ ] `SHD250SYSTEM` destination reachable from BTP (Cloud Connector if S/4 is private).
- [ ] Confirm `Z_EXT_GL_POSTING` is deployed/released on SHD250 and the service path is current.
- [ ] Sample guidance doc + sample Excel for the test harness.
- [ ] Decide PoC persistence: HANA HDI vs sqlite (faster start).

## 15. Acceptance criteria (PoC)

1. Upload guidance + Excel → proposal generated with per-line grounding + confidence.
2. A deliberately unbalanced / bad-GL file is **blocked by the rules engine** before any LLM-trusted posting.
3. Confidence/amount thresholds correctly route lines to STP vs approval.
4. Approved batch posts via `Z_EXT_GL_POSTING` (or stub) and is **idempotent** on replay.
5. Full audit trail retrievable per case.
