namespace Contoso.ProjectBilling;

page 50208 "PBA Start Billing Run"
{
    PageType = StandardDialog;
    ApplicationArea = Jobs;
    Caption = 'Run Billing Now';

    layout
    {
        area(Content)
        {
            field(PeriodEnd; PeriodEnd)
            {
                Caption = 'Month to Invoice';
                ToolTip = 'Specifies a date in the month to invoice. The run covers the whole calendar month.';
            }
            field(HandledBy; HandledBy)
            {
                Caption = 'Handled By';
                ToolTip = 'Specifies which agent decides the lines: the Project Billing Agent gets a task at once; the Copilot Studio agent reads the run through the API.';
            }
        }
    }

    var
        PeriodEnd: Date;
        HandledBy: Enum "PBA Billing Handler";

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

    procedure GetHandledBy(): Enum "PBA Billing Handler"
    begin
        exit(HandledBy);
    end;
}
