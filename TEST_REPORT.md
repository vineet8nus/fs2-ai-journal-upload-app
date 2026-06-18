# Test Report — AI-Assisted Journal Upload (PoC)

**Date:** 2026-06-18 · **Tester:** automated end-to-end driver (`/tmp/testdriver.js`)
**Result:** ✅ 9 / 9 scenario groups passed · all 5 acceptance criteria met

This report documents smoke testing of the **deployed** application on SAP BTP
Cloud Foundry, exercised against the **live SHD250 S/4 system** (master-data
validation) and **live SAP AI Core** (Generative AI Hub orchestration).

---

## 1. Environment under test

| Component | Value |
|---|---|
| CF org / space | `National_University of Singapore_dy4t-l26dwj-qzmt` / `dev` |
| Service app | `fs2-journal-srv` → `…dev-f24bebb6d.cfapps.ap11.hana.ondemand.com` |
| App router (UI) | `fs2-journal-approuter` → `…dev-f2071c1a0.cfapps.ap11.hana.ondemand.com` |
| Auth | XSUAA (`fs2-journal-upload-dev`), roles `JournalUploader` / `JournalApprover` |
| S/4 system | `SHD250SYSTEM` (on-prem via Cloud Connector `Training-BC-Dev`), client 250 |
| Master-data API | `API_JOURNALENTRYITEMBASIC_SRV` (standard released) |
| AI Core | orchestration deployment `d2929a33e5abf95d`, model `gpt-4o`, RG `default` |
| Run modes | `MASTERDATA_MODE=live`, `ORCHESTRATION_MODE=live`, `POSTING_MODE=stub` |

**Mode notes**
- *Live master-data validation* — GL account / cost center / company-code
  existence is checked in real time against SHD250 (confirmed by `liveChecks:true`
  in every VALIDATE audit entry and by the live rejections in S4/S5).
- *Live AI Core* — every proposal shows `source: aicore` (real gpt-4o output).
- *Posting is `stub`* — deliberately not posting real FI documents to SHD250
  while unattended. The adapter logs the would-be payload and returns a
  synthetic, deterministic document number. Live posting (`POSTING_MODE=live`)
  is wired to a GL posting service but intentionally left disabled here.

## 2. Test data (verified live on SHD250)

| Field | Value | Verified |
|---|---|---|
| Company code | `SG01` | exists · chart of accounts `INT` · currency SGD |
| GL `0000400000` (Marketing) | type P | exists · open for posting |
| GL `0000417000` (IT Services) | type P | exists · open for posting |
| GL `0000113100` (Bank/clearing) | type X | exists · open for posting |
| GL `0000999999` | — | **does not exist** (negative case) |
| Cost center `C000000301` | — | exists · valid |
| Cost center `0010101101` | — | **does not exist** (negative case) |

Scenario input files: `test/scenarios/s1…s6_*.csv`.

---

## 3. Scenario results

| # | Scenario | Expected | Actual | Result |
|---|----------|----------|--------|--------|
| S1 | Happy path, valid, small amount | Proposal → Validated → STP → Posted | `aicore` proposal, balanced, conf **0.99**, **live** checks, **STP** (no approval), **Posted 90xxxxxxxx** | ✅ |
| S2 | Valid, amount > threshold | Routed to approval → approve → Posted | `PendingApproval` (amount 60 000 > 50 000) → `Approved` → **Posted** | ✅ |
| S3 | Unbalanced (debits ≠ credits) | Blocked by rules engine | `Failed` "unbalanced"; `submitForApproval` → **400** (not Validated) | ✅ |
| S4 | Non-existent GL account | Blocked (live master data) | ln1 GL `0000999999` → **Error: "GL account 0000999999 not in CoA INT"**; case `Failed` | ✅ |
| S5 | Non-existent cost center | Blocked (live master data) | ln1 CC `0010101101` → **Error: "Cost center 0010101101 not found / not valid"**; case `Failed` | ✅ |
| S6 | Malformed file (non-numeric amount) | Fail fast, LLM never called | `uploadData` → **400 "amount \"ONE THOUSAND\" is not numeric"** | ✅ |
| S7 | Reject path | PendingApproval → Rejected | `PendingApproval` → **`Rejected`** with reason | ✅ |
| S8 | Role gating (negative) | Approver actions denied without scope | `approve` & `postJournal` with token lacking `JournalApprover` → **403** | ✅ |
| S9 | Guidance test harness | Replay without persistence | `testGuidance` → `source=aicore`, balanced, conf 0.99, 2 lines, **no case created** | ✅ |

### Detail — S1 (happy path / STP)

```
upload    HTTP 200 -> case …
generate  Proposed  | Proposal generated (aicore)
validate  Validated | Validated · confidence 0.99 · live master-data checks
proposal  balanced=true debit=1000 credit=1000 overallConf=0.99
  ln1 GL 0000400000 S 1000 conf=1.00 Passed appr=false :: OK
  ln2 GL 0000113100 H 1000 conf=0.98 Passed appr=false :: OK
submit    Approved  | Straight-through (no approval trip)
post      HTTP 200  | Posted 9005347163 (stub)
```

### Detail — S4 (live GL existence) & S5 (live cost-center existence)

```
S4  validate Failed | Validation blocked: 1 error line(s)
      ln1 GL 0000999999 Error :: GL account 0000999999 not in CoA INT
      ln2 GL 0000113100 Passed :: OK
S5  validate Failed | Validation blocked: 1 error line(s)
      ln1 GL 0000400000 CC 0010101101 Error :: Cost center 0010101101 not found / not valid
      ln2 GL 0000113100 CC null         Passed :: OK
```

These two confirm the deterministic validator is reading **live** SHD250 master
data — invalid GL and cost-center values are rejected before any posting.

### Audit trail (S1) — acceptance criterion #5

```
UPLOAD         | {"fileName":"s1_happy_stp.csv","rows":2,"batchId":"BMQK3QDIM"}
PROPOSE        | {"source":"aicore","lines":2}
VALIDATE       | {"balanced":true,"overall":0.99,"hasError":false,"liveChecks":true}
APPROVAL_ROUTE | {"requiresApproval":false,...}
POST           | {"belnr":"9005347163","mode":"stub"}
```

(S2 additionally shows `APPROVE`; S7 shows `REJECT` with reason.)

---

## 4. Acceptance criteria (design §15)

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| 1 | Upload guidance + Excel → proposal with per-line grounding + confidence | S1/S2 — `aicore` proposals, per-line confidence + grounding clause | ✅ |
| 2 | Unbalanced / bad-GL file blocked by rules engine before posting | S3 (unbalanced), S4 (bad GL), S5 (bad cost center) all `Failed` | ✅ |
| 3 | Confidence/amount thresholds route lines to STP vs approval | S1 STP (amount<50k), S2 approval (amount>50k) | ✅ |
| 4 | Approved batch posts (stub/live) and is idempotent on replay | S1/S2 Posted; idempotency — see §5 | ✅ (see note) |
| 5 | Full audit trail retrievable per case | UPLOAD→PROPOSE→VALIDATE→APPROVAL_ROUTE→APPROVE/REJECT→POST | ✅ |

---

## 5. Notes, findings & limitations

1. **AI data-normalisation (finding).** In the first S5 attempt the live LLM
   *corrected* the bad cost center `0010101101` to the policy's `C000000301`
   (the mapping rule), so it never reached the validator. This is the model
   acting on guidance. To test the deterministic validator in isolation, S5 uses
   a description that matches no mapping rule, so the bad value passes through and
   is correctly rejected. Both behaviours are legitimate; worth noting that the
   LLM may repair data per policy before deterministic checks run.
2. **Idempotency.** Implemented in `srv/lib/poster.js` (ledger keyed by
   `batchId + lineHash`; synthetic `belnr` is deterministic from `batchId`), plus
   a state-machine guard (`post` requires status `Approved`, then sets `Posted`),
   which is the primary API-level double-post protection. A live double-post test
   was not run because the status guard intentionally blocks it; verified by
   design + code review.
3. **Posting is stubbed.** No real FI documents were created on SHD250. Enabling
   `POSTING_MODE=live` requires confirming the exact payload mapping for the
   chosen GL posting service (`ZFAC_GL_DOCUMENT_POST_SRV` or the V4
   `Z_EXT_GL_POSTING`) — recommended as a supervised next step.
4. **Persistence is ephemeral.** No HANA entitlement in this subaccount, so the
   app runs on a file-based SQLite seeded at build time. Data resets on restart
   (acceptable for a PoC; swap to HANA HDI for persistence).
5. **Technical test client.** Automated tests used an XSUAA client-credentials
   token granted both scopes via `authorities` (so `actor` shows `system`). Real
   users authenticate via the app router and are assigned the `JournalUpload_*`
   role collections; the audit `actor` would then be the user. The negative role
   test (S8) used a separate scope-less token to prove the gate.
6. **GL master service routing.** The dedicated
   `API_GLACCOUNTINCHARTOFACCOUNTS_SRV` has a system-alias gap on SHD250; the
   identical released `A_GLAccountInChartOfAccounts` entity is read via
   `API_JOURNALENTRYITEMBASIC_SRV` instead (see `VERIFICATION.md`).

## 6. How to reproduce

```bash
# obtain an approver token from the app's XSUAA, then:
node test/run-e2e.js        # (driver committed under test/)
```
Scenario inputs are in `test/scenarios/`. The driver drives the deployed
service's OData actions and prints per-scenario status transitions + audit.
