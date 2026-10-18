namespace Contoso.ProjectBilling;

using System.Threading;

page 50203 "PBA Billing Runs"
{
    PageType = List;
    ApplicationArea = Jobs;
    UsageCategory = Lists;
    Caption = 'Billing Runs';
    SourceTable = "PBA Billing Run";
    SourceTableView = sorting("Period End") order(descending);
    CardPageId = "PBA Billing Run";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Runs)
            {
                field("No."; Rec."No.")
                {
                }
                field("Period Start"; Rec."Period Start")
                {
                }
                field("Period End"; Rec."Period End")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Handled By"; Rec."Handled By")
                {
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                }
                field("Lines to Decide"; Rec."Lines to Decide")
                {
                }
                field("Amount to Invoice"; Rec."Amount to Invoice")
                {
                }
                field("Amount on Hold"; Rec."Amount on Hold")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunBillingNow)
            {
                Caption = 'Run Billing Now';
                Image = CreateDocuments;
                ToolTip = 'Start a billing run for the Project Billing Agent for a month you choose, as the monthly job does on the first day of the month.';

                trigger OnAction()
                var
                    PBABillingRun: Record "PBA Billing Run";
                    PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
                    PBAStartBillingRun: Page "PBA Start Billing Run";
                begin
                    if PBAStartBillingRun.RunModal() <> Action::OK then
                        exit;
                    PBABillingRunMgt.StartRun(PBAStartBillingRun.GetPeriodEnd(), Enum::"PBA Billing Handler"::"Project Billing Agent", PBABillingRun);
                    Commit();
                    Page.Run(Page::"PBA Billing Run", PBABillingRun);
                end;
            }
            action(ScheduleMonthlyBilling)
            {
                Caption = 'Schedule Monthly Billing';
                Image = Timesheet;
                ToolTip = 'Create the job queue entry that starts a billing run for the Project Billing Agent on the first day of every month at 06:00.';

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                    PBAMonthlyBillingJob: Codeunit "PBA Monthly Billing Job";
                begin
                    PBAMonthlyBillingJob.EnsureJobQueueEntry();
                    if PBAMonthlyBillingJob.FindJobQueueEntry(JobQueueEntry) then
                        Page.Run(Page::"Job Queue Entry Card", JobQueueEntry);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RunBillingNow_Promoted; RunBillingNow)
            {
            }
            actionref(ScheduleMonthlyBilling_Promoted; ScheduleMonthlyBilling)
            {
            }
        }
    }
}
