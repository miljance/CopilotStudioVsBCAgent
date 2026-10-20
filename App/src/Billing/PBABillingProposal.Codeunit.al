namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;

/// <summary>
/// Business Central's part of the billing run: which billable planning lines of the open projects can be invoiced for
/// the period, their amounts, and the mechanical checks (milestone reached, invoice cap). The agent never adds up
/// amounts; it reads what this codeunit wrote. Projects without a billing method are left alone.
/// - Time and Material: billable lines created by usage (System-Created Entry) up to the end of the period.
/// - Fixed Price: planned billable lines of a task whose milestone was reached by the end of the period. A milestone
///   planned in the period but not reached is proposed as Milestone Not Reached, so the agent can report it.
/// - Invoice cap: lines in date order, on top of what is already transferred to invoices; a line that goes over the cap
///   and every line after it are Exceeds Invoice Cap. Checked again whenever a decision changes (held lines do not
///   count).
/// </summary>
codeunit 50206 "PBA Billing Proposal"
{
    Access = Internal;

    var
        MilestoneNotReachedTxt: Label 'The milestone of task %1 is not reached. It was planned for %2.', Comment = '%1 = project task No., %2 = planning date';
        MilestoneReachedLaterTxt: Label 'The milestone of task %1 was reached on %2, after the end of the period.', Comment = '%1 = project task No., %2 = date';
        ExceedsCapTxt: Label 'Invoice cap %1 exceeded: %2 already on invoices, %3 including this line.', Comment = '%1 = cap, %2 = amount already transferred to invoices, %3 = running total';
        RunAlreadyInvoicedErr: Label 'Billing run %1 already has draft invoices. Its lines cannot be proposed again.', Comment = '%1 = billing run No.';

    procedure CreateLines(var PBABillingRun: Record "PBA Billing Run")
    var
        Job: Record Job;
        PBABillingLine: Record "PBA Billing Line";
        NextLineNo: Integer;
    begin
        PBABillingLine.SetRange("Billing Run No.", PBABillingRun."No.");
        PBABillingLine.SetFilter("Sales Invoice No.", '<>%1', '');
        if not PBABillingLine.IsEmpty() then
            Error(RunAlreadyInvoicedErr, PBABillingRun."No.");
        PBABillingLine.SetRange("Sales Invoice No.");
        PBABillingLine.DeleteAll();

        NextLineNo := 0;
        Job.SetRange(Status, Job.Status::Open);
        Job.SetFilter("PBA Billing Method", '<>%1', Job."PBA Billing Method"::" ");
        if Job.FindSet() then
            repeat
                AddProjectLines(PBABillingRun, Job, NextLineNo);
            until Job.Next() = 0;
    end;

    local procedure AddProjectLines(PBABillingRun: Record "PBA Billing Run"; Job: Record Job; var NextLineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        PBABillingLine: Record "PBA Billing Line";
    begin
        JobPlanningLine.SetCurrentKey("Job No.", "Planning Date", "Document No.");
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Contract Line", true);
        JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);
        JobPlanningLine.SetFilter("Qty. to Transfer to Invoice", '>0');
        JobPlanningLine.SetRange("System-Created Entry", Job."PBA Billing Method" = Job."PBA Billing Method"::"Time and Material");
        if Job."PBA Billing Method" = Job."PBA Billing Method"::"Time and Material" then
            JobPlanningLine.SetRange("Planning Date", 0D, PBABillingRun."Period End");
        if not JobPlanningLine.FindSet() then
            exit;

        repeat
            if InitLine(PBABillingRun, Job, JobPlanningLine, PBABillingLine) then begin
                NextLineNo += 10000;
                PBABillingLine."Line No." := NextLineNo;
                PBABillingLine.Insert();
            end;
        until JobPlanningLine.Next() = 0;

        Clear(PBABillingLine);
        ApplyCap(PBABillingRun."No.", Job."No.", PBABillingLine, 0);
    end;

    /// <summary>
    /// Checks the invoice cap again with the decision CurrentLine is about to get. A held line does not count, so
    /// holding a line can bring later lines back under the cap, and invoicing a held line can push them over it.
    /// Called when a decision changes; CurrentLine is updated in memory, the other lines of the project are modified.
    /// </summary>
    procedure ApplyInvoiceCap(var CurrentLine: Record "PBA Billing Line")
    begin
        ApplyCap(CurrentLine."Billing Run No.", CurrentLine."Job No.", CurrentLine, CurrentLine."Line No.");
    end;

    /// <summary>
    /// Lines of the project in line order (= date order), on top of what is already on invoices. Lines already
    /// invoiced are part of that amount; lines on hold and milestones not reached do not count. The line that goes
    /// over the cap and every counted line after it are Exceeds Invoice Cap; the others are OK.
    /// </summary>
    local procedure ApplyCap(BillingRunNo: Code[20]; JobNo: Code[20]; var CurrentLine: Record "PBA Billing Line"; CurrentLineNo: Integer)
    var
        Job: Record Job;
        PBABillingLine: Record "PBA Billing Line";
        WorkLine: Record "PBA Billing Line";
        PBAAmountFormat: Codeunit "PBA Amount Format";
        OldCheck: Enum "PBA Billing Check";
        OldNote: Text[250];
        AlreadyTransferred: Decimal;
        RunningTotal: Decimal;
        CapExceeded: Boolean;
    begin
        if not Job.Get(JobNo) then
            exit;
        if Job."PBA Invoice Cap" <= 0 then
            exit;

        AlreadyTransferred := GetAmountTransferredToInvoices(JobNo);
        RunningTotal := AlreadyTransferred;
        CapExceeded := false;
        PBABillingLine.SetRange("Billing Run No.", BillingRunNo);
        PBABillingLine.SetRange("Job No.", JobNo);
        if not PBABillingLine.FindSet() then
            exit;
        repeat
            WorkLine := PBABillingLine;
            if WorkLine."Line No." = CurrentLineNo then
                WorkLine := CurrentLine;
            if (WorkLine."Sales Invoice No." = '') and (WorkLine.Check <> WorkLine.Check::"Milestone Not Reached") and
               (WorkLine.Decision <> WorkLine.Decision::Hold)
            then begin
                OldCheck := WorkLine.Check;
                OldNote := WorkLine."Check Note";
                RunningTotal += WorkLine.Amount;
                CapExceeded := CapExceeded or (RunningTotal > Job."PBA Invoice Cap");
                if CapExceeded then begin
                    WorkLine.Check := WorkLine.Check::"Exceeds Invoice Cap";
                    WorkLine."Check Note" := CopyStr(StrSubstNo(ExceedsCapTxt,
                        PBAAmountFormat.FormatAmount(Job."PBA Invoice Cap"),
                        PBAAmountFormat.FormatAmount(AlreadyTransferred),
                        PBAAmountFormat.FormatAmount(RunningTotal)), 1, MaxStrLen(WorkLine."Check Note"));
                end else begin
                    WorkLine.Check := WorkLine.Check::OK;
                    WorkLine."Check Note" := '';
                end;
                if WorkLine."Line No." = CurrentLineNo then begin
                    CurrentLine.Check := WorkLine.Check;
                    CurrentLine."Check Note" := WorkLine."Check Note";
                end else
                    if (WorkLine.Check <> OldCheck) or (WorkLine."Check Note" <> OldNote) then
                        WorkLine.Modify();
            end;
        until PBABillingLine.Next() = 0;
    end;

    local procedure InitLine(PBABillingRun: Record "PBA Billing Run"; Job: Record Job; JobPlanningLine: Record "Job Planning Line"; var PBABillingLine: Record "PBA Billing Line"): Boolean
    var
        JobTask: Record "Job Task";
    begin
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        PBABillingLine.Init();
        PBABillingLine."Billing Run No." := PBABillingRun."No.";
        PBABillingLine.Check := PBABillingLine.Check::OK;
        if Job."PBA Billing Method" = Job."PBA Billing Method"::"Fixed Price" then
            if not JobTask."PBA Milestone Reached" then begin
                // A milestone planned after the period is not due yet: nothing to report.
                if JobPlanningLine."Planning Date" > PBABillingRun."Period End" then
                    exit(false);
                PBABillingLine.Check := PBABillingLine.Check::"Milestone Not Reached";
                PBABillingLine."Check Note" := CopyStr(StrSubstNo(MilestoneNotReachedTxt, JobTask."Job Task No.", Format(JobPlanningLine."Planning Date", 0, 9)), 1, MaxStrLen(PBABillingLine."Check Note"));
            end else
                if JobTask."PBA Milestone Reached Date" > PBABillingRun."Period End" then begin
                    PBABillingLine.Check := PBABillingLine.Check::"Milestone Not Reached";
                    PBABillingLine."Check Note" := CopyStr(StrSubstNo(MilestoneReachedLaterTxt, JobTask."Job Task No.", Format(JobTask."PBA Milestone Reached Date", 0, 9)), 1, MaxStrLen(PBABillingLine."Check Note"));
                end;

        PBABillingLine."Customer No." := Job."Bill-to Customer No.";
        PBABillingLine."Customer Name" := Job."Bill-to Name";
        PBABillingLine."Job No." := Job."No.";
        PBABillingLine."Job Description" := Job.Description;
        PBABillingLine."Job Task No." := JobTask."Job Task No.";
        PBABillingLine."Job Task Description" := JobTask.Description;
        PBABillingLine."Planning Line No." := JobPlanningLine."Line No.";
        PBABillingLine."Billing Method" := Job."PBA Billing Method";
        PBABillingLine."Planning Date" := JobPlanningLine."Planning Date";
        PBABillingLine.Type := JobPlanningLine.Type;
        PBABillingLine."No." := JobPlanningLine."No.";
        PBABillingLine.Description := JobPlanningLine.Description;
        PBABillingLine.Quantity := JobPlanningLine."Qty. to Transfer to Invoice";
        PBABillingLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        PBABillingLine."Unit Price" := JobPlanningLine."Unit Price";
        PBABillingLine.Amount := GetLineAmount(JobPlanningLine, JobPlanningLine."Qty. to Transfer to Invoice");
        PBABillingLine."Billing Notes" := Job."PBA Billing Notes";
        exit(true);
    end;

    /// <summary>
    /// What the project's billable planning lines already put on invoices (draft or posted), at their own prices.
    /// </summary>
    procedure GetAmountTransferredToInvoices(JobNo: Code[20]) Total: Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Contract Line", true);
        JobPlanningLine.SetAutoCalcFields("Qty. Transferred to Invoice");
        if JobPlanningLine.FindSet() then
            repeat
                Total += GetLineAmount(JobPlanningLine, JobPlanningLine."Qty. Transferred to Invoice");
            until JobPlanningLine.Next() = 0;
    end;

    local procedure GetLineAmount(JobPlanningLine: Record "Job Planning Line"; Qty: Decimal): Decimal
    begin
        exit(Round(Qty * JobPlanningLine."Unit Price" * (1 - JobPlanningLine."Line Discount %" / 100)));
    end;
}
