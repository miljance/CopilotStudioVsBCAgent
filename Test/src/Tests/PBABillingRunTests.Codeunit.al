namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using System.TestLibraries.Utilities;

codeunit 50251 "PBA Billing Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PBATestLibrary: Codeunit "PBA Test Library";
        PBAMockTaskDispatcher: Codeunit "PBA Mock Task Dispatcher";

    [Test]
    procedure RunForTheAgentBecomesATask()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
    begin
        // [GIVEN] A project with September usage and an active agent
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(DMY2Date(15, 9, 2026));

        // [WHEN] The September run is started for the Project Billing Agent
        PBABillingRunMgt.StartRun(DMY2Date(20, 9, 2026), Enum::"PBA Billing Handler"::"Project Billing Agent", PBABillingRun);

        // [THEN] The run covers the calendar month, is named after it, and the agent gets one task that names the run
        Assert.AreEqual('BR-2026-09', PBABillingRun."No.", 'Run No.');
        Assert.AreEqual(DMY2Date(1, 9, 2026), PBABillingRun."Period Start", 'Period Start');
        Assert.AreEqual(DMY2Date(30, 9, 2026), PBABillingRun."Period End", 'Period End');
        Assert.AreEqual(DMY2Date(30, 9, 2026), PBABillingRun."Posting Date", 'Posting Date');
        Assert.AreEqual(1, PBAMockTaskDispatcher.GetSendCount(), 'One agent task');
        Assert.AreEqual('BR-2026-09', PBAMockTaskDispatcher.GetSentRunNo(), 'External ID');
        Assert.IsTrue(StrPos(PBAMockTaskDispatcher.GetSentMessage(), 'BR-2026-09') > 0, 'Expected ' + 'BR-2026-09');
        Assert.IsTrue(PBABillingRun."Agent Task ID" = 4711, 'Agent Task ID');
        Assert.AreEqual(PBABillingRun.Status::Proposed, PBABillingRun.Status, 'Status');
    end;

    [Test]
    procedure RunWithNothingToInvoiceSendsNoTask()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
    begin
        // [GIVEN] No project with anything to invoice
        PBATestLibrary.Initialize();

        // [WHEN] The September run is started for the Project Billing Agent
        PBABillingRunMgt.StartRun(DMY2Date(1, 9, 2026), Enum::"PBA Billing Handler"::"Project Billing Agent", PBABillingRun);

        // [THEN] The run is closed and the agent is not bothered
        Assert.AreEqual(PBABillingRun.Status::"Nothing to Invoice", PBABillingRun.Status, 'Status');
        Assert.AreEqual(0, PBAMockTaskDispatcher.GetSendCount(), 'No agent task');
    end;

    [Test]
    procedure RunForTheAgentNeedsAnActiveAgent()
    var
        PBABillingRun: Record "PBA Billing Run";
        Runs: Record "PBA Billing Run";
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
        RunsBefore: Integer;
    begin
        // [GIVEN] No active agent
        // The error rolls back to the start of the test, so the runs are counted before Initialize.
        Runs.SetRange("Period End", DMY2Date(30, 9, 2026));
        RunsBefore := Runs.Count();
        PBATestLibrary.Initialize();
        PBAMockTaskDispatcher.Reset(false);
        CreateProjectWithUsage(DMY2Date(15, 9, 2026));

        // [WHEN] The September run is started for the Project Billing Agent
        asserterror PBABillingRunMgt.StartRun(DMY2Date(1, 9, 2026), Enum::"PBA Billing Handler"::"Project Billing Agent", PBABillingRun);

        // [THEN] It fails before a run is created
        Assert.ExpectedError('No active Project Billing Agent');
        Assert.AreEqual(RunsBefore, Runs.Count(), 'No run without an agent.');
    end;

    [Test]
    procedure RunForCopilotStudioCreatesNoTask()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
    begin
        // [GIVEN] A project with September usage
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(DMY2Date(15, 9, 2026));

        // [WHEN] The September run is started for the Copilot Studio agent
        PBABillingRunMgt.StartRun(DMY2Date(1, 9, 2026), Enum::"PBA Billing Handler"::"Copilot Studio Agent", PBABillingRun);

        // [THEN] The lines are proposed and no Business Central agent task is created
        PBABillingRun.CalcFields("No. of Lines");
        Assert.AreEqual(1, PBABillingRun."No. of Lines", 'Lines');
        Assert.AreEqual(0, PBAMockTaskDispatcher.GetSendCount(), 'No agent task');
        Assert.AreEqual(PBABillingRun."Handled By"::"Copilot Studio Agent", PBABillingRun."Handled By", 'Handled By');
    end;

    [Test]
    procedure SecondRunOfAMonthGetsASuffix()
    var
        FirstRun: Record "PBA Billing Run";
        SecondRun: Record "PBA Billing Run";
    begin
        // [GIVEN] A September run
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), FirstRun);

        // [WHEN] Another September run is created
        PBATestLibrary.CreateRun(DMY2Date(30, 9, 2026), SecondRun);

        // [THEN] It gets its own number
        Assert.AreEqual('BR-2026-09-2', SecondRun."No.", 'Second run No.');
    end;

    [Test]
    procedure MonthlyJobInvoicesThePreviousMonth()
    var
        PBAMonthlyBillingJob: Codeunit "PBA Monthly Billing Job";
    begin
        // [GIVEN] The monthly job runs on 1 November
        // [WHEN] It asks which month to invoice
        // [THEN] It is October
        Assert.AreEqual(DMY2Date(31, 10, 2026), PBAMonthlyBillingJob.GetPeriodToInvoice(DMY2Date(1, 11, 2026)), '1 November');
        Assert.AreEqual(DMY2Date(31, 12, 2026), PBAMonthlyBillingJob.GetPeriodToInvoice(DMY2Date(1, 1, 2027)), '1 January');
    end;

    local procedure CreateProjectWithUsage(UsageDate: Date)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Usage: Record "Job Planning Line";
    begin
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, UsageDate, 'Configuration', 2, 1000, Usage);
    end;
}
