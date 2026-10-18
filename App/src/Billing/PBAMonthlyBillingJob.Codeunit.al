namespace Contoso.ProjectBilling;

using System.Threading;

/// <summary>
/// Job queue entry that runs on the first day of every month at 06:00 (Next Run Date Formula &lt;CM+1D&gt;) and starts
/// the billing run of the past month for the Project Billing Agent.
/// </summary>
codeunit 50208 "PBA Monthly Billing Job"
{
    Access = Internal;
    TableNo = "Job Queue Entry";

    var
        JobDescriptionTxt: Label 'Project Billing Agent: monthly billing run';
        NextRunDateFormulaTok: Label '<CM+1D>', Locked = true;

    trigger OnRun()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
    begin
        PBABillingRunMgt.StartRun(GetPeriodToInvoice(Today()), Enum::"PBA Billing Handler"::"Project Billing Agent", PBABillingRun);
    end;

    /// <summary>
    /// A date in the month before RunDate: the run on 1 November invoices October.
    /// </summary>
    procedure GetPeriodToInvoice(RunDate: Date): Date
    begin
        exit(CalcDate('<-CM-1D>', RunDate));
    end;

    procedure EnsureJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if FindJobQueueEntry(JobQueueEntry) then begin
            RepairJobQueueEntry();
            exit;
        end;
        if not JobQueueEntry.WritePermission() then
            exit;

        JobQueueEntry.Init();
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.Validate("Object ID to Run", Codeunit::"PBA Monthly Billing Job");
        JobQueueEntry.Description := CopyStr(JobDescriptionTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        Evaluate(JobQueueEntry."Next Run Date Formula", NextRunDateFormulaTok);
        JobQueueEntry."Starting Time" := 060000T;
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(CalcDate(JobQueueEntry."Next Run Date Formula", Today()), 060000T);
        SetRetries(JobQueueEntry);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    /// <summary>
    /// A run that breaks once is retried instead of leaving the recurring job in Error; a job in Error or On Hold is
    /// started again. Called on every upgrade (each publish of a new version).
    /// </summary>
    procedure RepairJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not JobQueueEntry.WritePermission() then
            exit;
        if not FindJobQueueEntry(JobQueueEntry) then
            exit;
        repeat
            if JobQueueEntry."Maximum No. of Attempts to Run" < MaxAttempts() then begin
                SetRetries(JobQueueEntry);
                JobQueueEntry.Modify();
            end;
            if JobQueueEntry.Status in [JobQueueEntry.Status::Error, JobQueueEntry.Status::"On Hold"] then
                JobQueueEntry.Restart();
        until JobQueueEntry.Next() = 0;
    end;

    procedure FindJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"PBA Monthly Billing Job");
        exit(JobQueueEntry.FindSet());
    end;

    local procedure SetRetries(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry."Maximum No. of Attempts to Run" := MaxAttempts();
        JobQueueEntry."Rerun Delay (sec.)" := 60;
    end;

    local procedure MaxAttempts(): Integer
    begin
        exit(3);
    end;
}
