# Live S/4 API Verification (SHD250)

Before any code was written, the standard released APIs and **every field** used
by the validation engine were verified against the **live SHD250 system**, not
assumed from documentation.

## How

SHD250 is on-premise (`ProxyType=OnPremise`, Cloud Connector location
`Training-BC-Dev`) and unreachable directly. A temporary verifier app
(`jrnl-verifier`) was deployed to CF bound to the existing `destination` +
`connectivity` services, fetched `$metadata` for candidate released APIs through
the Cloud Connector via the SAP Cloud SDK, and was then deleted. This is exactly
the connectivity path the real app uses (also the Phase-0 S/4 smoke test).

Destination: `SHD250SYSTEM` → `fs2dev.hec.nus.edu.sg`, `sap-client=250`,
BasicAuthentication. Gateway catalog reported **1704 services**.

## Results

| Service | Result | Notes |
|---|---|---|
| `API_JOURNALENTRYITEMBASIC_SRV` | ✅ HTTP 200 | 5 entity types — primary source of master data + JE items |
| `API_COSTCENTER_SRV` | ✅ HTTP 200 | `A_CostCenter`, `A_CostCenterText` |
| `API_BUSINESS_PARTNER` | ✅ HTTP 200 | sanity check (56 entity types) |
| `API_GLACCOUNTINCHARTOFACCOUNTS_SRV` | ⚠️ HTTP 500 | registered but *"No System Alias found"* — Basis routing gap |
| `API_COMPANYCODE_SRV` | ❌ HTTP 403 | not activated on this front-end |
| `API_INTERNALORDER_SRV` | ❌ HTTP 403 | not activated |
| `API_PROFITCENTER_SRV` | ❌ HTTP 403 | not activated |
| `API_OPLACCTGDOCITEMCUBE_SRV` | ❌ HTTP 403 | not activated |

## Decision

`API_JOURNALENTRYITEMBASIC_SRV` is a single **activated, released** service that
exposes all required master-data entity types, so the validation engine grounds
on it. Verified entity/field names (now imported as typed CAP external service
under `srv/external/`):

- **A_GLAccountInChartOfAccounts** — `ChartOfAccounts`, `GLAccount`,
  `AccountIsBlockedForPosting`, `AccountIsMarkedForDeletion`, `GLAccountType`,
  `IsBalanceSheetAccount`
- **A_CostCenter** — `CostCenter`, `ControllingArea`, `ValidityEndDate`,
  `CompanyCode`, `IsBlkdForPrimaryCostsPosting`
- **A_CompanyCode** — `CompanyCode`, `Currency`, `ChartOfAccounts`,
  `FiscalYearVariant`, `ControllingArea`
- **A_ProfitCenter** — `ProfitCenter`, `ControllingArea`, `CompanyCode`
- **A_JournalEntryItemBasic** — 157 fields (read-back / dedupe)

## Posting services available (for `POSTING_MODE=live`)

Present on SHD250 (OData V2 catalog): `ZFAC_GL_DOCUMENT_POST_SRV` (standard
"Post General Journal Entries" F0718), `ZUI_JOURNALENTRY_MANAGE`,
`ZFI_JOURNAL_UPLOAD_FORMAT_SRV`, `ZFINCS_JRNLENTR_POST_SRV`. The design's
`Z_EXT_GL_POSTING` (`zep_gl_posting_v4_web_api`) is an OData **V4** service (not
in the V2 catalog). `srv/lib/poster.js` targets `GL_POSTING` (default path
`ZFAC_GL_DOCUMENT_POST_SRV`), configurable via the destination path.
