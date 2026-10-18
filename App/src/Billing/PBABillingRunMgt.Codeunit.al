namespace Contoso.ProjectBilling;

/// <summary>
/// Creates billing runs. A run covers one calendar month; its No. names the month (BR-2026-09, a second run of the
/// same month BR-2026-09-2). Business Central proposes the lines at once. A run for the Project Billing Agent becomes an
/// agent task; a run for the Copilot Studio agent waits for it to read the lines through the API.
/// </summary>
codeunit 50211 "PBA Billing Run Mgt."
{
    Access = Internal;

    var
        NoActiveAgentErr: Label 'No active Project Billing Agent was found. Set up and activate the Project Billing Agent first, or choose the Copilot Studio agent.';
        TaskTitleTxt: Label 'Monthly billing %1', Comment = '%1 = billing run No.';
        TaskMessageTxt: Label 'Prepare the draft invoices of billing run %1 (%2 to %3).', Comment = '%1 = billing run No., %2 = period start, %3 = period end';
        RunNoTok: Label 'BR-%1', Locked = true;

    /// <summary>
    /// Creates the run for the month of DateInPeriod and proposes its lines. A run for the Project Billing Agent is sent
    /// to the agent when it has lines; with nothing to invoice the run is closed and no task is created.
    /// </summary>
    procedure StartRun(DateInPeriod: Date; HandledBy: Enum "PBA Billing Handler"; var PBABillingRun: Record "PBA Billing Run")
    var
        PBADispatcherProvider: Codeunit "PBA Dispatcher Provider";
        Dispatcher: Interface "PBA ITask Dispatcher";
    begin
        Dispatcher := PBADispatcherProvider.GetDispatcher();
        if HandledBy = HandledBy::"Project Billing Agent" then
            if not Dispatcher.IsAvailable() then
                Error(NoActiveAgentErr);

        CreateRun(DateInPeriod, HandledBy, PBABillingRun);

        PBABillingRun.CalcFields("No. of Lines");
        if PBABillingRun."No. of Lines" = 0 then begin
            PBABillingRun.Status := PBABillingRun.Status::"Nothing to Invoice";
            PBABillingRun.Modify();
            exit;
        end;

        if HandledBy = HandledBy::"Project Billing Agent" then begin
            PBABillingRun."Agent Task ID" := Dispatcher.SendBillingRun(
                PBABillingRun."No.",
                CopyStr(StrSubstNo(TaskTitleTxt, PBABillingRun."No."), 1, 150),
                StrSubstNo(TaskMessageTxt, PBABillingRun."No.", Format(PBABillingRun."Period Start", 0, 9), Format(PBABillingRun."Period End", 0, 9)));
            PBABillingRun.Modify();
        end;
    end;

    procedure CreateRun(DateInPeriod: Date; HandledBy: Enum "PBA Billing Handler"; var PBABillingRun: Record "PBA Billing Run")
    var
        PBABillingProposal: Codeunit "PBA Billing Proposal";
    begin
        InitRun(DateInPeriod, HandledBy, PBABillingRun);
        PBABillingRun.Insert();
        PBABillingProposal.CreateLines(PBABillingRun);
    end;

    /// <summary>
    /// Fills a new run for the month of DateInPeriod without inserting it (the billingRuns API lets the platform insert).
    /// </summary>
    procedure InitRun(DateInPeriod: Date; HandledBy: Enum "PBA Billing Handler"; var PBABillingRun: Record "PBA Billing Run")
    begin
        PBABillingRun.Init();
        PBABillingRun."Period Start" := CalcDate('<-CM>', DateInPeriod);
        PBABillingRun."Period End" := CalcDate('<CM>', DateInPeriod);
        PBABillingRun."No." := GetNextRunNo(PBABillingRun."Period End");
        PBABillingRun."Posting Date" := PBABillingRun."Period End";
        PBABillingRun."Handled By" := HandledBy;
        PBABillingRun.Status := PBABillingRun.Status::Proposed;
    end;

    local procedure GetNextRunNo(PeriodEnd: Date): Code[20]
    var
        PBABillingRun: Record "PBA Billing Run";
        BaseNo: Code[20];
        Suffix: Integer;
    begin
        BaseNo := CopyStr(StrSubstNo(RunNoTok, Format(PeriodEnd, 0, '<Year4>-<Month,2>')), 1, MaxStrLen(BaseNo));
        if not PBABillingRun.Get(BaseNo) then
            exit(BaseNo);
        Suffix := 2;
        while PBABillingRun.Get(CopyStr(BaseNo + '-' + Format(Suffix), 1, MaxStrLen(BaseNo))) do
            Suffix += 1;
        exit(CopyStr(BaseNo + '-' + Format(Suffix), 1, MaxStrLen(BaseNo)));
    end;
}
