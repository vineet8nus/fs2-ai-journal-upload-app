/* checksum : 2f92fbc2df62b91e252220e0957c3e4d */
@cds.external : true
@m.IsDefaultEntityContainer : 'true'
@sap.message.scope.supported : 'true'
@sap.supported.formats : 'atom json xlsx'
service API_JOURNALENTRYITEMBASIC_SRV {
  @cds.external : true
  @cds.persistence.skip : true
  @sap.creatable : 'false'
  @sap.updatable : 'false'
  @sap.deletable : 'false'
  @sap.content.version : '1'
  @sap.label : 'Company Code Data'
  entity A_CompanyCode {
    @sap.display.format : 'UpperCase'
    @sap.label : 'Company Code'
    key CompanyCode : String(4) not null;
    @sap.label : 'Company Name'
    @sap.quickinfo : 'Name of Company Code or Company'
    CompanyCodeName : String(25);
    @sap.label : 'City'
    CityName : String(25);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Country/Region Key'
    Country : String(3);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Currency'
    @sap.quickinfo : 'Currency Key'
    @sap.semantics : 'currency-code'
    Currency : String(5);
    @sap.label : 'Language Key'
    Language : String(2);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Chart of Accounts'
    ChartOfAccounts : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Fiscal Year Variant'
    FiscalYearVariant : String(2);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Company'
    Company : String(6);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Credit Control Area'
    CreditControlArea : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Alternative COA'
    @sap.quickinfo : 'Alternative Chart of Accounts'
    CountryChartOfAccounts : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'FM Area'
    @sap.quickinfo : 'Financial Management Area'
    FinancialManagementArea : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Address'
    AddressID : String(10);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Taxes on Sls/Purc.'
    @sap.quickinfo : 'Taxes on Sales/Purchases Group'
    TaxableEntity : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'VAT Registration No.'
    @sap.quickinfo : 'VAT Registration Number'
    VATRegistration : String(20);
    @sap.label : 'Extended WTax Active'
    @sap.quickinfo : 'Indicator: Extended Withholding Tax Active'
    ExtendedWhldgTaxIsActive : Boolean;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Controlling Area'
    ControllingArea : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Field status variant'
    @sap.quickinfo : 'Field Status Variant'
    FieldStatusVariant : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Output Tax Code'
    @sap.quickinfo : 'Output Tax Code for Non-Taxable Transactions'
    NonTaxableTransactionTaxCode : String(2);
    @sap.label : 'Tax Determ.with Doc.Date'
    @sap.quickinfo : 'Indicator: Document Date As the Basis for Tax Determination'
    DocDateIsUsedForTaxDetn : Boolean;
    @sap.label : 'Tax Date'
    @sap.quickinfo : 'Tax Reporting Date Active in Documents'
    TaxRptgDateIsActive : Boolean;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @sap.creatable : 'false'
  @sap.updatable : 'false'
  @sap.deletable : 'false'
  @sap.content.version : '1'
  @sap.label : 'Cost Center Data'
  entity A_CostCenter {
    @sap.display.format : 'UpperCase'
    @sap.label : 'Controlling Area'
    key ControllingArea : String(4) not null;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Cost Center'
    key CostCenter : String(10) not null;
    @sap.display.format : 'Date'
    @sap.label : 'Valid To'
    @sap.quickinfo : 'Valid To Date'
    key ValidityEndDate : Date not null;
    @sap.display.format : 'Date'
    @sap.label : 'Valid From'
    @sap.quickinfo : 'Valid-From Date'
    ValidityStartDate : Date;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Company Code'
    CompanyCode : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Business Area'
    BusinessArea : String(4);
    @sap.label : 'Person Responsible'
    CostCtrResponsiblePersonName : String(20);
    @sap.display.format : 'UpperCase'
    @sap.label : 'User Responsible'
    CostCtrResponsibleUser : String(12);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Currency'
    @sap.quickinfo : 'Currency Key'
    @sap.semantics : 'currency-code'
    CostCenterCurrency : String(5);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Profit Center'
    ProfitCenter : String(10);
    @sap.label : 'Department'
    Department : String(12);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Costing Sheet'
    CostingSheet : String(6);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Functional Area'
    FunctionalArea : String(16);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Country/Region Key'
    Country : String(3);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Region'
    @sap.quickinfo : 'Region (State, Province, County)'
    Region : String(3);
    @sap.label : 'City'
    CityName : String(35);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Hierarchy Area'
    @sap.quickinfo : 'Standard Hierarchy Area'
    CostCenterStandardHierArea : String(12);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Cost Center Category'
    CostCenterCategory : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Actual primary costs'
    @sap.quickinfo : 'Lock Indicator for Actual Primary Postings'
    IsBlkdForPrimaryCostsPosting : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Actl Sec. Costs'
    @sap.quickinfo : 'Lock Indicator for Actual Secondary Costs'
    IsBlkdForSecondaryCostsPosting : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Actual Revenues'
    @sap.quickinfo : 'Lock Indicator for Actual Revenue Postings'
    IsBlockedForRevenuePosting : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Commitment Update'
    @sap.quickinfo : 'Lock Indicator for Commitment Update'
    IsBlockedForCommitmentPosting : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Plan primary costs'
    @sap.quickinfo : 'Lock Indicator for Plan Primary Costs'
    IsBlockedForPlanPrimaryCosts : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Lock Plan Sec Costs'
    @sap.quickinfo : 'Lock Indicator for Plan Secondary Costs'
    IsBlockedForPlanSecondaryCosts : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Lock Planning Revn'
    @sap.quickinfo : 'Lock Indicator for Planning Revenues'
    IsBlockedForPlanRevenues : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Record Quantity'
    @sap.quickinfo : 'Indicator for Recording Consumption Quantities'
    ConsumptionQtyIsRecorded : String(1);
    @sap.label : 'Language Key'
    Language : String(2);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Created By'
    @sap.quickinfo : 'Entered By'
    CostCenterCreatedByUser : String(12);
    @sap.display.format : 'Date'
    @sap.label : 'Entered On'
    CostCenterCreationDate : Date;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @sap.creatable : 'false'
  @sap.updatable : 'false'
  @sap.deletable : 'false'
  @sap.content.version : '1'
  @sap.label : 'General Ledger Account in Chart of Accounts Data'
  entity A_GLAccountInChartOfAccounts {
    @sap.display.format : 'UpperCase'
    @sap.label : 'Chart of Accounts'
    key ChartOfAccounts : String(4) not null;
    @sap.display.format : 'UpperCase'
    @sap.label : 'G/L Account'
    @sap.quickinfo : 'G/L Account Number'
    key GLAccount : String(10) not null;
    @sap.label : 'Balance sheet acct'
    @sap.quickinfo : 'Indicator: Account is a balance sheet account?'
    IsBalanceSheetAccount : Boolean;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Account Group'
    @sap.quickinfo : 'G/L Account Group'
    GLAccountGroup : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Group Account Number'
    CorporateGroupAccount : String(10);
    @sap.display.format : 'UpperCase'
    @sap.label : 'P&L state. acct'
    @sap.quickinfo : 'P&L statement account type'
    ProfitLossAccountType : String(2);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Sample Account'
    @sap.quickinfo : 'Number of the Sample Account'
    SampleGLAccount : String(10);
    @sap.label : 'Deletion Flag'
    @sap.quickinfo : 'Indicator: Account Marked for Deletion?'
    AccountIsMarkedForDeletion : Boolean;
    @sap.label : 'Creation Block'
    @sap.quickinfo : 'Indicator: Account Is Blocked for Creation ?'
    AccountIsBlockedForCreation : Boolean;
    @sap.label : 'Posting Block'
    @sap.quickinfo : 'Indicator: Is Account Blocked for Posting?'
    AccountIsBlockedForPosting : Boolean;
    @sap.label : 'Planning Block'
    @sap.quickinfo : 'Indicator: Account Blocked for Planning ?'
    AccountIsBlockedForPlanning : Boolean;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Trading Partner No.'
    @sap.quickinfo : 'Company ID of Trading Partner'
    PartnerCompany : String(6);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Functional Area'
    FunctionalArea : String(16);
    @sap.display.format : 'Date'
    @sap.label : 'Created On'
    @sap.quickinfo : 'Record Created On'
    CreationDate : Date;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Created by'
    @sap.quickinfo : 'Name of Person who Created the Object'
    CreatedByUser : String(12);
    @odata.Type : 'Edm.DateTimeOffset'
    @sap.label : 'Time Stamp'
    @sap.quickinfo : 'UTC Time Stamp in Short Form (YYYYMMDDhhmmss)'
    LastChangeDateTime : DateTime;
    @sap.display.format : 'UpperCase'
    @sap.label : 'G/L Account Type'
    @sap.quickinfo : 'Type of a General Ledger Account'
    GLAccountType : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'G/L Acct External ID'
    @sap.quickinfo : 'G/L Account Number'
    GLAccountExternal : String(10);
    @sap.label : 'Balance sheet acct'
    @sap.quickinfo : 'Indicator: Account is a balance sheet account?'
    IsProfitLossAccount : Boolean;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @sap.creatable : 'false'
  @sap.updatable : 'false'
  @sap.deletable : 'false'
  @sap.content.version : '1'
  @sap.semantics : 'aggregate'
  @sap.label : 'Journal Entry Item Basic Data'
  entity A_JournalEntryItemBasic {
    @sap.sortable : 'false'
    @sap.filterable : 'false'
    key ID : String not null;
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'LedgerName'
    @sap.label : 'Ledger'
    @sap.quickinfo : 'Ledger in General Ledger Accounting'
    Ledger : String(2);
    @sap.label : 'Ledger Name'
    LedgerName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Source Ledger'
    SourceLedger : String(2);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'NonNegative'
    @sap.label : 'Fiscal Year of Ledger'
    LedgerFiscalYear : String(4);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'ControllingAreaName'
    @sap.label : 'Controlling Area'
    ControllingArea : String(4);
    @sap.label : 'Ctrlg Area Name'
    @sap.quickinfo : 'Controlling Area Name'
    ControllingAreaName : String(25);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CompanyCodeName'
    @sap.label : 'Company Code'
    CompanyCode : String(4);
    @sap.label : 'Company Code Name'
    CompanyCodeName : String(25);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'GLAccountName'
    @sap.label : 'G/L Account'
    GLAccount : String(10);
    @sap.label : 'G/L Account Name'
    GLAccountName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Financial Transaction Type'
    FinancialTransactionType : String(3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Business Transaction Category'
    BusinessTransactionCategory : String(4);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Business Transaction Type'
    BusinessTransactionType : String(4);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Source Reference Document Type'
    SourceReferenceDocumentType : String(5);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Obsolete Reason'
    @sap.quickinfo : 'Journal Entry Item Obsolete Reason'
    JrnlEntryItemObsoleteReason : String(1);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CostCenterName'
    @sap.label : 'Cost Center'
    CostCenter : String(10);
    @sap.label : 'Cost Center Name'
    CostCenterName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'ProfitCenterName'
    @sap.label : 'Profit Center'
    ProfitCenter : String(10);
    @sap.label : 'Profit Center Name'
    @sap.quickinfo : 'Description of Profit Center'
    ProfitCenterName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'FunctionalAreaName'
    @sap.label : 'Functional Area'
    FunctionalArea : String(16);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Functional Area Name'
    FunctionalAreaName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'BusinessAreaName'
    @sap.label : 'Business Area'
    BusinessArea : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Business Area Name'
    BusinessAreaName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'SegmentName'
    @sap.label : 'Segment'
    @sap.quickinfo : 'Segment for Segmental Reporting'
    Segment : String(10);
    @sap.label : 'Segment Name'
    SegmentName : String(50);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerCostCenterName'
    @sap.label : 'Partner Cost Center'
    PartnerCostCenter : String(10);
    @sap.label : 'PCostCName'
    @sap.quickinfo : 'Partner Cost Center Name'
    PartnerCostCenterName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerProfitCenterName'
    @sap.label : 'Partner Profit Center'
    PartnerProfitCenter : String(10);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Part Profit Ctr Name'
    @sap.quickinfo : 'Partner Profit Center Name'
    PartnerProfitCenterName : String(50);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerFunctionalAreaName'
    @sap.label : 'Partner Func. Area'
    @sap.quickinfo : 'Partner Functional Area'
    PartnerFunctionalArea : String(16);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Part Func Area Name'
    @sap.quickinfo : 'Partner Functional Area Name'
    PartnerFunctionalAreaName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerBusinessAreaName'
    @sap.label : 'Partner Bus. Area'
    @sap.quickinfo : 'Partner Business Area'
    PartnerBusinessArea : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Part Bus Area Name'
    @sap.quickinfo : 'Partner Business Area Name'
    PartnerBusinessAreaName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerCompanyName'
    @sap.label : 'Trading Partner'
    @sap.quickinfo : 'Company ID of Trading Partner'
    PartnerCompany : String(6);
    @sap.label : 'Company Name'
    PartnerCompanyName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerSegmentName'
    @sap.label : 'Partner Segment'
    @sap.quickinfo : 'Partner Segment for Segmental Reporting'
    PartnerSegment : String(10);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Partner Segment Name'
    PartnerSegmentName : String(50);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Transaction Currency'
    @sap.semantics : 'currency-code'
    TransactionCurrency : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'TransactionCurrency'
    @sap.label : 'Amount in Transaction Currency'
    @sap.filterable : 'false'
    AmountInTransactionCurrency : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Company Code Currency'
    @sap.semantics : 'currency-code'
    CompanyCodeCurrency : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'CompanyCodeCurrency'
    @sap.label : 'Amount in Company Code Currency'
    @sap.filterable : 'false'
    AmountInCompanyCodeCurrency : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Global Currency'
    @sap.semantics : 'currency-code'
    GlobalCurrency : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'GlobalCurrency'
    @sap.label : 'Amount in Global Currency'
    @sap.filterable : 'false'
    AmountInGlobalCurrency : Decimal(24, 3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'GlobalCurrency'
    @sap.label : 'Fixed Amount in Global Currency'
    @sap.filterable : 'false'
    FixedAmountInGlobalCrcy : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Functional Currency'
    @sap.semantics : 'currency-code'
    FunctionalCurrency : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FunctionalCurrency'
    @sap.label : 'Amount in Functional Currency'
    @sap.filterable : 'false'
    AmountInFunctionalCurrency : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'CO Object Currency'
    @sap.semantics : 'currency-code'
    ControllingObjectCurrency : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'ControllingObjectCurrency'
    @sap.label : 'Amount in Object Currency'
    @sap.filterable : 'false'
    AmountInObjectCurrency : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Cost Source Unit'
    @sap.semantics : 'unit-of-measure'
    CostSourceUnit : String(3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'CostSourceUnit'
    @sap.label : 'Valuation Quantity'
    @sap.filterable : 'false'
    ValuationQuantity : Decimal(23, 3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'CostSourceUnit'
    @sap.label : 'Valuation Fixed Quantity'
    @sap.filterable : 'false'
    ValuationFixedQuantity : Decimal(23, 3);
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Reference Qty UoM'
    @sap.quickinfo : 'Unit of Measure for Reference Quantity'
    @sap.semantics : 'unit-of-measure'
    ReferenceQuantityUnit : String(3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'ReferenceQuantityUnit'
    @sap.label : 'Reference quantity'
    @sap.filterable : 'false'
    ReferenceQuantity : Decimal(23, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 1'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency1 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency1'
    @sap.label : 'Amount in Freely Defined Currency 1'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency1 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 2'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency2 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency2'
    @sap.label : 'Amount in Freely Defined Currency 2'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency2 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 3'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency3 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency3'
    @sap.label : 'Amount in Freely Defined Currency 3'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency3 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 4'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency4 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency4'
    @sap.label : 'Amount in Freely Defined Currency 4'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency4 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 5'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency5 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency5'
    @sap.label : 'Amount in Freely Defined Currency 5'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency5 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 6'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency6 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency6'
    @sap.label : 'Amount in Freely Defined Currency 6'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency6 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 7'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency7 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency7'
    @sap.label : 'Amount in Freely Defined Currency 7'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency7 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Freely Defined Currency 8'
    @sap.semantics : 'currency-code'
    FreeDefinedCurrency8 : String(5);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'FreeDefinedCurrency8'
    @sap.label : 'Amount in Freely Defined Currency 8'
    @sap.filterable : 'false'
    AmountInFreeDefinedCurrency8 : Decimal(24, 3);
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Base Unit of Measure'
    @sap.semantics : 'unit-of-measure'
    BaseUnit : String(3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'BaseUnit'
    @sap.label : 'Quantity'
    @sap.filterable : 'false'
    Quantity : Decimal(23, 3);
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Additional Quantity 1 Unit'
    @sap.semantics : 'unit-of-measure'
    AdditionalQuantity1Unit : String(3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'AdditionalQuantity1Unit'
    @sap.label : 'Additional Quantity 1'
    @sap.filterable : 'false'
    AdditionalQuantity1 : Decimal(23, 3);
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Additional Quantity 2 Unit'
    @sap.semantics : 'unit-of-measure'
    AdditionalQuantity2Unit : String(3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'AdditionalQuantity2Unit'
    @sap.label : 'Additional Quantity 2'
    @sap.filterable : 'false'
    AdditionalQuantity2 : Decimal(23, 3);
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Additional Quantity 3 Unit'
    @sap.semantics : 'unit-of-measure'
    AdditionalQuantity3Unit : String(3);
    @sap.aggregation.role : 'measure'
    @sap.unit : 'AdditionalQuantity3Unit'
    @sap.label : 'Additional Quantity 3'
    @sap.filterable : 'false'
    AdditionalQuantity3 : Decimal(23, 3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Journal Entry Category'
    AccountingDocumentCategory : String(1);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'NonNegative'
    @sap.label : 'Fiscal Period'
    FiscalPeriod : String(3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Fiscal Year Variant'
    FiscalYearVariant : String(2);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Fiscal Year Period'
    FiscalYearPeriod : String(8);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Chart of Accounts'
    ChartOfAccounts : String(4);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PlantName'
    @sap.label : 'Plant'
    Plant : String(4);
    @sap.label : 'Plant Name'
    PlantName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CustomerName'
    @sap.label : 'Customer'
    @sap.quickinfo : 'Customer Number'
    Customer : String(10);
    @sap.label : 'Name of Customer'
    CustomerName : String(80);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Controlling Debit Credit Code'
    ControllingDebitCreditCode : String(1);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Project External ID'
    ProjectExternalID : String(24);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'ProjectDescription'
    @sap.label : 'Project'
    Project : String(24);
    @sap.label : 'Project Description'
    ProjectDescription : String(40);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'WBS Element External ID'
    WBSElementExternalID : String(24);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'WBSElementDescription'
    @sap.label : 'WBS Element'
    WBSElement : String(24);
    @sap.label : 'WBS Element Name'
    @sap.quickinfo : 'Work Breakdown Structure Element Name'
    WBSElementDescription : String(40);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerCompanyCodeName'
    @sap.label : 'Partner Company Code'
    PartnerCompanyCode : String(4);
    @sap.label : 'Partner Company Code Name'
    PartnerCompanyCodeName : String(25);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CostCtrActivityTypeName'
    @sap.label : 'Activity Type'
    CostCtrActivityType : String(6);
    @sap.label : 'Activity Type Name'
    CostCtrActivityTypeName : String(60);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Order ID'
    OrderID : String(12);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Partner Order'
    PartnerOrder : String(12);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerCostCtrActivityTypeName'
    @sap.label : 'Partner Cost Center Activity Type'
    PartnerCostCtrActivityType : String(6);
    @sap.label : 'Part Act Type Name'
    @sap.quickinfo : 'Partner Activity Type Name'
    PartnerCostCtrActivityTypeName : String(60);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerProjectDescription'
    @sap.label : 'Partner Project'
    PartnerProject : String(24);
    @sap.label : 'Part Proj Descript'
    @sap.quickinfo : 'Partner Project Description (1st text line)'
    PartnerProjectDescription : String(40);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'PartnerWBSElementDescription'
    @sap.label : 'Partner WBS Element'
    PartnerWBSElement : String(24);
    @sap.label : 'WBS Descr'
    @sap.quickinfo : 'Partner WBS Element Description'
    PartnerWBSElementDescription : String(40);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'SalesOrganizationName'
    @sap.label : 'Sales Organization'
    SalesOrganization : String(4);
    @sap.label : 'Sales Org Name'
    @sap.quickinfo : 'Sales Organization Name'
    SalesOrganizationName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'DistributionChannelName'
    @sap.label : 'Distribution Channel'
    DistributionChannel : String(2);
    @sap.label : 'Distrib Channel Name'
    @sap.quickinfo : 'Distribution Channel Name'
    DistributionChannelName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'DivisionName'
    @sap.label : 'Division'
    OrganizationDivision : String(2);
    @sap.label : 'Divison Name'
    @sap.quickinfo : 'Name of Division'
    DivisionName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'ProductName'
    @sap.label : 'Product'
    @sap.quickinfo : 'Product Number'
    Product : String(40);
    @sap.label : 'Product Description'
    ProductName : String(40);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'SoldMaterialName'
    @sap.label : 'Sold Material'
    SoldMaterial : String(40);
    @sap.label : 'Sold Material Name'
    SoldMaterialName : String(40);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'MaterialGroupName'
    @sap.label : 'Product Sold Group'
    MaterialGroup : String(9);
    @sap.label : 'Product Group Desc.'
    @sap.quickinfo : 'Product Group Description'
    MaterialGroupName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CustomerGroupName'
    @sap.label : 'Customer Group'
    CustomerGroup : String(2);
    @sap.label : 'Customer Group Name'
    @sap.quickinfo : 'Name of Customer Group'
    CustomerGroupName : String(30);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CustomerSupplierCountryName'
    @sap.label : 'Customer or Supplier Country/Region'
    CustomerSupplierCountry : String(3);
    @sap.label : 'Country/Region Name'
    CustomerSupplierCountryName : String(50);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'CustomerSupplierIndustryName'
    @sap.label : 'Customer Supplier Industry'
    CustomerSupplierIndustry : String(4);
    @sap.label : 'Industry Key'
    @sap.quickinfo : 'Description of the Industry Key'
    CustomerSupplierIndustryName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.text : 'SalesDistrictName'
    @sap.label : 'Sales District'
    SalesDistrict : String(6);
    @sap.label : 'District Name'
    @sap.quickinfo : 'Name of the District'
    SalesDistrictName : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'FM Area'
    @sap.quickinfo : 'Financial Management Area'
    FinancialManagementArea : String(4);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Fund'
    Fund : String(10);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Grant'
    GrantID : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Budget Period'
    BudgetPeriod : String(10);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Sponsored Program'
    SponsoredProgram : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Sponsored Class'
    SponsoredClass : String(20);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Bdgt Validty No.'
    @sap.quickinfo : 'Budget Validity Number'
    GteeMBudgetValidityNumber : String(3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Joint venture'
    JointVenture : String(6);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Joint Venture Equity Group'
    JointVentureEquityGroup : String(3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Joint Venture Cost Recovery Code'
    JointVentureCostRecoveryCode : String(2);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Joint Venture Partner'
    JointVenturePartner : String(10);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Joint Venture Billing Type'
    JointVentureBillingType : String(2);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Joint Venture Equity Type'
    JointVentureEquityType : String(3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'Date'
    @sap.label : 'Joint Venture Production Date'
    JointVentureProductionDate : Date;
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'Date'
    @sap.label : 'Joint Venture Billing Date'
    JointVentureBillingDate : Date;
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'Date'
    @sap.label : 'Joint Venture Operational Date'
    JointVentureOperationalDate : Date;
    @odata.Type : 'Edm.DateTimeOffset'
    @odata.Precision : 7
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Cutback Run'
    CutbackRun : Timestamp;
    @sap.aggregation.role : 'dimension'
    @sap.label : 'Joint Venture Accounting Activity'
    JointVentureAccountingActivity : String(2);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'PartnerVenture'
    @sap.quickinfo : 'Partner Venture'
    PartnerVenture : String(6);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Partner Equity Group'
    PartnerEquityGroup : String(3);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Sender Cost Recovery Code'
    SenderCostRecoveryCode : String(2);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Cutback Account'
    CutbackAccount : String(10);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Cutback Cost Object'
    CutbackCostObject : String(22);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'RE Business Entity'
    REBusinessEntity : String(8);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Real Estate Building'
    RealEstateBuilding : String(8);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Real Estate Property'
    RealEstateProperty : String(8);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'RE Rental Object'
    RERentalObject : String(8);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'Real Estate Contract'
    RealEstateContract : String(13);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'RE Service Charge Key'
    REServiceChargeKey : String(4);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'UpperCase'
    @sap.label : 'RE Settlement Unit'
    RESettlementUnitID : String(5);
    @sap.aggregation.role : 'dimension'
    @sap.display.format : 'Date'
    @sap.label : 'Settlement Reference Date'
    SettlementReferenceDate : Date;
    to_CompanyCode : Association to A_CompanyCode {  };
    to_CurrentCostCenter : Association to A_CostCenter {  };
    to_CurrentProfitCenter : Association to A_ProfitCenter {  };
    to_GLAccountInChartOfAccounts : Association to A_GLAccountInChartOfAccounts {  };
  };

  @cds.external : true
  @cds.persistence.skip : true
  @sap.creatable : 'false'
  @sap.updatable : 'false'
  @sap.deletable : 'false'
  @sap.content.version : '1'
  @sap.label : 'Profit Center Data'
  entity A_ProfitCenter {
    @sap.display.format : 'UpperCase'
    @sap.label : 'Controlling Area'
    key ControllingArea : String(4) not null;
    @sap.display.format : 'UpperCase'
    @sap.label : 'Profit Center'
    key ProfitCenter : String(10) not null;
    @sap.display.format : 'Date'
    @sap.label : 'Valid To'
    @sap.quickinfo : 'Valid To Date'
    key ValidityEndDate : Date not null;
    @sap.label : 'Person Resp. for PC'
    @sap.quickinfo : 'Person Responsible for Profit Center'
    ProfitCtrResponsiblePersonName : String(20);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Company Code'
    CompanyCode : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'User Responsible'
    @sap.quickinfo : 'User Responsible for the Profit Center'
    ProfitCtrResponsibleUser : String(12);
    @sap.display.format : 'Date'
    @sap.label : 'Valid From'
    @sap.quickinfo : 'Valid-From Date'
    ValidityStartDate : Date;
    @sap.label : 'Department'
    Department : String(12);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Hierarchy Area'
    @sap.quickinfo : 'Profit center area'
    ProfitCenterStandardHierarchy : String(12);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Segment'
    @sap.quickinfo : 'Segment for Segmental Reporting'
    Segment : String(10);
    @sap.label : 'Lock indicator'
    ProfitCenterIsBlocked : String(1);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Form. Planning Temp.'
    @sap.quickinfo : 'Template for Formula Planning in Profit Centers'
    FormulaPlanningTemplate : String(10);
    @sap.label : 'Title'
    FormOfAddress : String(15);
    @sap.label : 'Name'
    @sap.quickinfo : 'Name 1'
    AddressName : String(35);
    @sap.label : 'Name 2'
    AdditionalName : String(35);
    @sap.label : 'Name 3'
    ProfitCenterAddrName3 : String(35);
    @sap.label : 'Name 4'
    ProfitCenterAddrName4 : String(35);
    @sap.label : 'Street'
    @sap.quickinfo : 'Street and House Number'
    StreetAddressName : String(35);
    @sap.display.format : 'UpperCase'
    @sap.label : 'PO Box'
    POBox : String(10);
    @sap.label : 'City'
    CityName : String(35);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Postal Code'
    PostalCode : String(10);
    @sap.label : 'District'
    District : String(35);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Country/Region Key'
    Country : String(3);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Region'
    @sap.quickinfo : 'Region (State, Province, County)'
    Region : String(3);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Tax Jurisdiction'
    TaxJurisdiction : String(15);
    @sap.label : 'Language Key'
    Language : String(2);
    @sap.label : 'Telephone 1'
    @sap.quickinfo : 'First telephone number'
    PhoneNumber1 : String(16);
    @sap.label : 'Telephone 2'
    @sap.quickinfo : 'Second telephone number'
    PhoneNumber2 : String(16);
    @sap.label : 'Telebox Number'
    TeleboxNumber : String(15);
    @sap.label : 'Telex Number'
    TelexNumber : String(30);
    @sap.label : 'Fax Number'
    FaxNumber : String(31);
    @sap.label : 'Data line'
    @sap.quickinfo : 'Data communication line no.'
    DataCommunicationPhoneNumber : String(14);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Printer name'
    @sap.quickinfo : 'Printer name for profit center'
    ProfitCenterPrinterName : String(4);
    @sap.display.format : 'UpperCase'
    @sap.label : 'Created By'
    @sap.quickinfo : 'Entered By'
    ProfitCenterCreatedByUser : String(12);
    @sap.display.format : 'Date'
    @sap.label : 'Entered On'
    ProfitCenterCreationDate : Date;
  };
};

