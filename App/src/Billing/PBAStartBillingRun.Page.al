namespace Contoso.ProjectBilling;

page 50208 "PBA Start Billing Run"
{
    PageType = StandardDialog;
    ApplicationArea = Jobs;
    Caption = 'Run Billing Now';
    // Always for the Project Billing Agent: the Copilot Studio agent starts its runs itself, through the billingRuns API.

    layout
    {
        area(Content)
        {
            field(PeriodEnd; PeriodEnd)
            {
                Caption = 'Month to Invoice';
                ToolTip = 'Specifies a date in the month to invoice. The run covers the whole calendar month.';
            }
        }
    }

    var
        PeriodEnd: Date;

    trigger OnOpenPage()
    var
        PBAMonthlyBillingJob: Codeunit "PBA Monthly Billing Job";
    begin
        PeriodEnd := CalcDate('<CM>', PBAMonthlyBillingJob.GetPeriodToInvoice(WorkDate()));
    end;

    procedure GetPeriodEnd(): Date
    begin
        exit(PeriodEnd);
    end;
}
