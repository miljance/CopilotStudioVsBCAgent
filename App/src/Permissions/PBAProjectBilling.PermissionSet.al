namespace Contoso.ProjectBilling;

/// <summary>
/// For project managers who review the billing runs, and for the Copilot Studio connection that works through the
/// billingRuns and billingLines APIs. Creating the draft invoices also needs the user's own sales invoice permissions.
/// The agent itself runs with D365 READ and PBA Agent Edit (see PBA Agent Setup).
/// </summary>
permissionset 50200 "PBA Project Billing"
{
    Caption = 'Project Billing Agent - use';
    Assignable = true;

    Permissions =
        tabledata "PBA Billing Run" = RIMD,
        tabledata "PBA Billing Line" = RIMD,
        table "PBA Billing Run" = X,
        table "PBA Billing Line" = X,
        page "PBA Billing Runs" = X,
        page "PBA Billing Run" = X,
        page "PBA Billing Lines" = X,
        page "PBA Start Billing Run" = X,
        page "PBA Billing Runs API" = X,
        page "PBA Billing Lines API" = X,
        page "PBA Billing Line Decisions API" = X,
        codeunit "PBA Billing Run Mgt." = X,
        codeunit "PBA Billing Proposal" = X,
        codeunit "PBA Draft Invoices" = X,
        codeunit "PBA Monthly Billing Job" = X;
}
