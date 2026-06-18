# AI-Assisted Journal Upload (PoC)

CAP (Node.js) + Fiori Elements + SAP AI Core implementation of the design in
`01_Journal_Upload_AI_PoC_Design_and_Build_Plan.md`.

A user uploads a natural-language **guidance document** (posting policy) plus a
**data file** (Excel/CSV). The system generates policy-compliant posting
proposals, **validates them deterministically** against the live S/4 system,
scores per-line confidence, routes through a **toggleable approval** step, and
posts to S/4 — all with a full audit trail.

> **Deterministic-first:** the LLM only proposes GL mappings / item texts with a
> grounding clause + reasoning. It never computes balances or invents master
> data — arithmetic and existence checks run in CAP against released S/4 APIs.

---

## Standard released S/4 APIs — verified live on SHD250

The master-data validation is grounded on **standard released `API_*` OData**.
Each service and **every field used was verified against the live SHD250 system**
(org *National University of Singapore*, destination `SHD250SYSTEM`, on-premise
via Cloud Connector `Training-BC-Dev`) before coding. See `VERIFICATION.md`.

| Concern | Released API (verified) | Entity / fields used |
|---|---|---|
| GL account exists / open for posting | `API_JOURNALENTRYITEMBASIC_SRV` | `A_GLAccountInChartOfAccounts`: `ChartOfAccounts`, `GLAccount`, `AccountIsBlockedForPosting`, `AccountIsMarkedForDeletion`, `GLAccountType` |
| Cost center valid / not blocked | `API_JOURNALENTRYITEMBASIC_SRV` (+ `API_COSTCENTER_SRV`) | `A_CostCenter`: `CostCenter`, `ControllingArea`, `ValidityEndDate`, `IsBlkdForPrimaryCostsPosting` |
| Company code / chart of accounts / currency | `API_JOURNALENTRYITEMBASIC_SRV` | `A_CompanyCode`: `CompanyCode`, `Currency`, `ChartOfAccounts`, `FiscalYearVariant` |
| Profit center | `API_JOURNALENTRYITEMBASIC_SRV` | `A_ProfitCenter` |
| Journal entry read-back / dedupe | `API_JOURNALENTRYITEMBASIC_SRV` | `A_JournalEntryItemBasic` (157 fields) |

The verified EDMX is imported under `srv/external/` and used as a typed CAP
external service, so the field names are checked **at compile time** too.

> The dedicated `API_GLACCOUNTINCHARTOFACCOUNTS_SRV` is registered on SHD250 but
> currently returns *"No System Alias found"* (a Basis routing gap). We therefore
> read the **same released `A_GLAccountInChartOfAccounts` entity** via the working
> `API_JOURNALENTRYITEMBASIC_SRV` service — no loss of standard-API fidelity.

---

## Architecture / pipeline

```
Upload (guidance + data)  ->  Parse (canonical rows, leading-zero-safe codes)
  ->  Generate proposal (LLM orchestration: AI Core | stub)   [grounding + reasoning]
  ->  Deterministic validation (balance=0, GL/cost-object/company existence)  ← released API_*
  ->  Confidence scoring (per line + overall)
  ->  Toggleable approval (rule: confidence × amount × company code)
  ->  Idempotent posting (batchId + lineHash)  ->  Audit
```

| Stage | Code |
|---|---|
| Parse | `srv/lib/parser.js` |
| Validate (live master data) | `srv/lib/validator.js` |
| LLM orchestration | `srv/lib/orchestrator.js` |
| Confidence | `srv/lib/scorer.js` |
| Approval state machine | `srv/lib/approval.js` |
| Idempotent posting | `srv/lib/poster.js` |
| Service handlers | `srv/service.js` |
| Data model | `db/schema.cds` |
| Fiori annotations | `srv/annotations.cds` |
| Fiori Elements app (Horizon theme) | `app/journalui/` |

## Feature flags (env)

| Var | Default | Meaning |
|---|---|---|
| `MASTERDATA_MODE` | `live` | `live` = validate against S/4; `skip` = offline demo (checks become Warnings) |
| `ORCHESTRATION_MODE` | `stub` | `live` = AI Core Gen AI Hub orchestration; `stub` = deterministic proposal |
| `POSTING_MODE` | `stub` | `stub` = log payload + synthetic doc no.; `live` = post via GL posting service |
| `DESTINATION_NAME` | `SHD250SYSTEM` | S/4 destination (never hardcoded) |
| `AICORE_DESTINATION` | `ai-core-destination` | AI Core destination |
| `AICORE_ORCH_DEPLOYMENT` | – | orchestration deployment id (enables `live` orchestration) |
| `DEFAULT_COMPANY_CODE` / `DEFAULT_CURRENCY` | – / `SGD` | fallbacks when not in the file |

## Roles

`JournalUploader` (upload / generate / validate) and `JournalApprover`
(approve / reject / post) — see `xs-security.json`.

---

## Run locally

```bash
npm install
cds deploy --to sqlite                       # creates db.sqlite with seed data
MASTERDATA_MODE=skip ORCHESTRATION_MODE=stub POSTING_MODE=stub \
  DEFAULT_COMPANY_CODE=1010 cds serve
# open http://localhost:4004  (Fiori app: /journalui/webapp/index.html)
```

Mock users: `alice` (Uploader+Approver), `bob` (Uploader).

End-to-end via REST (uses the bound OData actions):

```bash
B="http://alice:@localhost:4004/journal"
B64=$(base64 -w0 test/sample.csv)
ID=$(curl -s -X POST "$B/uploadData" -H "Content-Type: application/json" \
  -d "{\"guidance_ID\":\"11111111-1111-1111-1111-111111111111\",\"fileName\":\"sample.csv\",\"contentBase64\":\"$B64\"}" \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['ID'])")
EK="$B/Cases(ID=$ID,IsActiveEntity=true)"
for a in generateProposal validateProposal submitForApproval approve postJournal; do
  curl -s -X POST "$EK/JournalService.$a" -d '{}' -w "  <- $a\n" -o /dev/null; done
```

## Build & deploy (BTP Cloud Foundry)

```bash
mbt build                                     # -> mta_archives/*.mtar
cf deploy mta_archives/fs2-ai-journal-upload-app_1.0.0.mtar
```

The MTA provisions `xsuaa`, and binds the existing `destination` +
`connectivity` services so the CAP service reaches S/4 (`SHD250SYSTEM`) through
the Cloud Connector. Persistence is self-seeding in-memory SQLite (PoC); swap to
HANA HDI when entitlement is available.

## Acceptance criteria status

1. ✅ Upload guidance + Excel → proposal with per-line grounding + confidence.
2. ✅ Unbalanced / bad-GL file **blocked by the rules engine** before posting.
3. ✅ Confidence/amount thresholds route lines to STP vs approval.
4. ✅ Approved batch posts (stub/live) and is **idempotent** on replay (`batchId + lineHash`).
5. ✅ Full audit trail retrievable per case.
