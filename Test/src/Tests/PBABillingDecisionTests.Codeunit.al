namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using System.TestLibraries.Utilities;

codeunit 50252 "PBA Billing Decision Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PBATestLibrary: Codeunit "PBA Test Library";

    [Test]
    procedure AgentCannotInvoiceAFlaggedLine()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line over the invoice cap, decided in an agent session
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBATestLibrary.SetAgentSession(true);

        // [WHEN] The agent sets Invoice
        asserterror PBABillingLine.Validate(Decision, PBABillingLine.Decision::Invoice);

        // [THEN] Business Central refuses: only a person can invoice a flagged line
        Assert.ExpectedError('Only a person can decide to invoice it');
    end;

    [Test]
    procedure AgentCanHoldAFlaggedLine()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line over the invoice cap, decided in an agent session
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBATestLibrary.SetAgentSession(true);

        // [WHEN] The agent sets Hold
        PBABillingLine.Validate(Decision, PBABillingLine.Decision::Hold);

        // [THEN] The decision is the agent's
        Assert.AreEqual(PBABillingLine.Decision::Hold, PBABillingLine.Decision, 'Decision');
        Assert.IsFalse(PBABillingLine."Decided By Person", 'Decided By Person');
    end;

    [Test]
    procedure PersonCanInvoiceAFlaggedLine()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line over the invoice cap, decided by the project manager
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBATestLibrary.SetAgentSession(false);

        // [WHEN] The project manager sets Invoice
        PBABillingLine.Validate(Decision, PBABillingLine.Decision::Invoice);

        // [THEN] It is accepted and marked as a person's decision
        Assert.AreEqual(PBABillingLine.Decision::Invoice, PBABillingLine.Decision, 'Decision');
        Assert.IsTrue(PBABillingLine."Decided By Person", 'Decided By Person');
    end;

    [Test]
    procedure ApiCannotInvoiceAFlaggedLine()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line over the invoice cap
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);

        // [WHEN] An outside agent sets Invoice through the billingLines API
        PBABillingLine.Decision := PBABillingLine.Decision::Invoice;
        asserterror PBABillingLine.CheckAgentMayDecide();

        // [THEN] Business Central refuses it as it refuses the Project Billing Agent
        Assert.ExpectedError('Only a person can decide to invoice it');
    end;

    [Test]
    procedure DecisionIsFixedOnceTheLineIsOnAnInvoice()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line that is already on a draft invoice
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBABillingLine."Sales Invoice No." := 'S-INV-TEST';
        PBABillingLine.Modify();

        // [WHEN] Someone changes the decision
        asserterror PBABillingLine.Validate(Decision, PBABillingLine.Decision::Hold);

        // [THEN] It is refused
        Assert.ExpectedError('is already on draft invoice S-INV-TEST');
    end;

    local procedure CreateRunWithCapExceeded(var PBABillingRun: Record "PBA Billing Run"; var PBABillingLine: Record "PBA Billing Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Usage: Record "Job Planning Line";
    begin
        PBATestLibrary.CreateProject(Job, PBATestLibrary.GetCustomer(1), Enum::"PBA Billing Method"::"Time and Material");
        Job."PBA Invoice Cap" := 1000;
        Job.Modify();
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(15, 9, 2026), 'Configuration', 2, 1000, Usage);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);
        PBATestLibrary.FindLine(PBABillingRun, Usage, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Check, 'Precondition: line over the cap');
    end;
}
