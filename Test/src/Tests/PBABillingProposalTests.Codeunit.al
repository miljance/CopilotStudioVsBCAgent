namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using System.TestLibraries.Utilities;

codeunit 50250 "PBA Billing Proposal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PBATestLibrary: Codeunit "PBA Test Library";

    [Test]
    procedure TimeAndMaterialProposesUsageUpToPeriodEnd()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        InPeriod: Record "Job Planning Line";
        AfterPeriod: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Time and Material project with usage on 15 September and on 2 October
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(15, 9, 2026), 'Configuration', 2, 1000, InPeriod);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(2, 10, 2026), 'Training', 1, 1000, AfterPeriod);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] Only the September usage is proposed, OK, with Business Central's amount
        Assert.IsTrue(PBATestLibrary.FindLine(PBABillingRun, InPeriod, PBABillingLine), 'September usage must be proposed.');
        Assert.AreEqual(PBABillingLine.Check::OK, PBABillingLine.Check, 'Check');
        Assert.AreEqual(2000, PBABillingLine.Amount, 'Amount');
        Assert.AreEqual(2, PBABillingLine.Quantity, 'Quantity');
        Assert.AreEqual(Job."Bill-to Customer No.", PBABillingLine."Customer No.", 'Customer');
        Assert.IsFalse(PBATestLibrary.FindLine(PBABillingRun, AfterPeriod, PBABillingLine), 'October usage must wait for the October run.');
    end;

    [Test]
    procedure TimeAndMaterialIgnoresPlannedLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Planned: Record "Job Planning Line";
        BudgetOnly: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Time and Material project with a planned billable line and a budget line, but no usage
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreatePlanningLine(JobTask, DMY2Date(10, 9, 2026), 'Planned work', 5, 1000, Planned."Line Type"::"Both Budget and Billable", false, Planned);
        PBATestLibrary.CreatePlanningLine(JobTask, DMY2Date(10, 9, 2026), 'Budget', 5, 1000, BudgetOnly."Line Type"::Budget, true, BudgetOnly);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] Nothing is proposed: Time and Material invoices only usage
        Assert.IsFalse(PBATestLibrary.FindLine(PBABillingRun, Planned, PBABillingLine), 'A planned line is not usage.');
        Assert.IsFalse(PBATestLibrary.FindLine(PBABillingRun, BudgetOnly, PBABillingLine), 'A budget line is not billable.');
    end;

    [Test]
    procedure ProjectWithoutBillingMethodIsLeftAlone()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Usage: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A project without a billing method that has billable usage
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::" ");
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(15, 9, 2026), 'Configuration', 2, 1000, Usage);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] The project is not in the run
        Assert.IsFalse(PBATestLibrary.FindLine(PBABillingRun, Usage, PBABillingLine), 'A project without billing method is not invoiced by the run.');
    end;

    [Test]
    procedure FixedPriceProposesReachedMilestone()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Milestone: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Fixed Price milestone planned for October, reached on 28 September
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Fixed Price");
        PBATestLibrary.CreateTask(Job, 'M1', JobTask);
        PBATestLibrary.CreateMilestoneLine(JobTask, DMY2Date(15, 10, 2026), 'Milestone 1: design sign-off', 12000, Milestone);
        PBATestLibrary.SetMilestoneReached(JobTask, DMY2Date(28, 9, 2026));

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] The milestone is proposed, OK
        Assert.IsTrue(PBATestLibrary.FindLine(PBABillingRun, Milestone, PBABillingLine), 'A reached milestone must be proposed.');
        Assert.AreEqual(PBABillingLine.Check::OK, PBABillingLine.Check, 'Check');
        Assert.AreEqual(12000, PBABillingLine.Amount, 'Amount');
    end;

    [Test]
    procedure FixedPriceFlagsDueMilestoneNotReached()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Milestone: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Fixed Price milestone planned for 30 September and not reached
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Fixed Price");
        PBATestLibrary.CreateTask(Job, 'M2', JobTask);
        PBATestLibrary.CreateMilestoneLine(JobTask, DMY2Date(30, 9, 2026), 'Milestone 2: go-live', 20000, Milestone);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] It is proposed as Milestone Not Reached, with the task in the note
        Assert.IsTrue(PBATestLibrary.FindLine(PBABillingRun, Milestone, PBABillingLine), 'A due milestone must be reported.');
        Assert.AreEqual(PBABillingLine.Check::"Milestone Not Reached", PBABillingLine.Check, 'Check');
        Assert.IsTrue(StrPos(PBABillingLine."Check Note", 'M2') > 0, 'Expected ' + 'M2');
    end;

    [Test]
    procedure FixedPriceIgnoresFutureMilestone()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Milestone: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Fixed Price milestone planned for December and not reached
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Fixed Price");
        PBATestLibrary.CreateTask(Job, 'M3', JobTask);
        PBATestLibrary.CreateMilestoneLine(JobTask, DMY2Date(15, 12, 2026), 'Milestone 3: hypercare', 8000, Milestone);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] It is not in the run: it is not due yet
        Assert.IsFalse(PBATestLibrary.FindLine(PBABillingRun, Milestone, PBABillingLine), 'A milestone that is not due is not reported.');
    end;

    [Test]
    procedure FixedPriceFlagsMilestoneReachedAfterPeriod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Milestone: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Fixed Price milestone planned for September, reached on 3 October
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Fixed Price");
        PBATestLibrary.CreateTask(Job, 'M1', JobTask);
        PBATestLibrary.CreateMilestoneLine(JobTask, DMY2Date(25, 9, 2026), 'Milestone 1', 12000, Milestone);
        PBATestLibrary.SetMilestoneReached(JobTask, DMY2Date(3, 10, 2026));

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] It is flagged: it belongs to the October run
        Assert.IsTrue(PBATestLibrary.FindLine(PBABillingRun, Milestone, PBABillingLine), 'The milestone must be reported.');
        Assert.AreEqual(PBABillingLine.Check::"Milestone Not Reached", PBABillingLine.Check, 'Check');
    end;

    [Test]
    procedure InvoiceCapFlagsLineThatGoesOverAndLaterLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        First: Record "Job Planning Line";
        Second: Record "Job Planning Line";
        Third: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A Time and Material project with an invoice cap of 5,000 and usage of 3,000, 3,000 and 1,000 in date order
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        Job."PBA Invoice Cap" := 5000;
        Job.Modify();
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(5, 9, 2026), 'Week 1', 3, 1000, First);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(12, 9, 2026), 'Week 2', 3, 1000, Second);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(19, 9, 2026), 'Week 3', 1, 1000, Third);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] The first line is OK; the line that goes over the cap and every later line are flagged
        PBATestLibrary.FindLine(PBABillingRun, First, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::OK, PBABillingLine.Check, 'First line');
        PBATestLibrary.FindLine(PBABillingRun, Second, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Check, 'Second line');
        Assert.IsTrue(StrPos(PBABillingLine."Check Note", '6,000.00') > 0, 'Expected ' + '6,000.00');
        PBATestLibrary.FindLine(PBABillingRun, Third, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Check, 'Third line');
    end;

    [Test]
    procedure HoldingALineBringsLaterLinesUnderTheCap()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        First: Record "Job Planning Line";
        Second: Record "Job Planning Line";
        Third: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] Cap 5,000 and usage of 3,000, 3,000 and 1,000: the second and third line are over the cap
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        Job."PBA Invoice Cap" := 5000;
        Job.Modify();
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(5, 9, 2026), 'Week 1', 3, 1000, First);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(12, 9, 2026), 'Week 2 (warranty)', 3, 1000, Second);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(19, 9, 2026), 'Week 3', 1, 1000, Third);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);
        PBATestLibrary.SetAgentSession(true);

        // [WHEN] The agent holds the second line
        PBATestLibrary.Decide(PBABillingRun, Second, Enum::"PBA Billing Decision"::Hold);

        // [THEN] The third line fits under the cap again (3,000 + 1,000) and the agent may invoice it
        PBATestLibrary.FindLine(PBABillingRun, Third, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::OK, PBABillingLine.Check, 'Third line after the hold');
        PBATestLibrary.Decide(PBABillingRun, Third, Enum::"PBA Billing Decision"::Invoice);

        // [WHEN] The project manager invoices the held line after all
        PBATestLibrary.SetAgentSession(false);
        PBATestLibrary.Decide(PBABillingRun, Second, Enum::"PBA Billing Decision"::Invoice);

        // [THEN] The second line is over the cap again, and so is the third
        PBATestLibrary.FindLine(PBABillingRun, Second, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Check, 'Second line invoiced by a person');
        Assert.IsTrue(PBABillingLine."Decided By Person", 'Decided By Person');
        PBATestLibrary.FindLine(PBABillingRun, Third, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Check, 'Third line');
    end;

    [Test]
    procedure LineCarriesBillingNotesAndDiscountedAmount()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Usage: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A project with billing notes and a usage line of 3 x 1,000 with 10 % line discount
        PBATestLibrary.Initialize();
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        Job."PBA Billing Notes" := 'Warranty work is not billed.';
        Job.Modify();
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(15, 9, 2026), 'Fix of the sales report (warranty)', 3, 1000, Usage);
        Usage.Validate("Line Discount %", 10);
        Usage.Modify(true);

        // [WHEN] The September run is created
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [THEN] The line shows the notes, the description and the amount after discount
        PBATestLibrary.FindLine(PBABillingRun, Usage, PBABillingLine);
        Assert.AreEqual('Warranty work is not billed.', PBABillingLine."Billing Notes", 'Billing Notes');
        Assert.AreEqual('Fix of the sales report (warranty)', PBABillingLine.Description, 'Description');
        Assert.AreEqual(2700, PBABillingLine.Amount, 'Amount');
    end;
}
