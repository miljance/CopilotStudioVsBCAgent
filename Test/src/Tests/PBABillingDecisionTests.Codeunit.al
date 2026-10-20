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

    [Test]
    procedure PersonApiCanInvoiceAFlaggedLine()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
    begin
        // [GIVEN] A line over the invoice cap, held by the agent
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBATestLibrary.SetAgentSession(true);
        PBABillingLine.Validate(Decision, PBABillingLine.Decision::Hold);
        PBABillingLine.Modify(true);
        PBATestLibrary.SetAgentSession(false);

        // [WHEN] The project manager invoices it from the Teams card, through billingLineDecisions
        PBABillingLine.SetPersonDecision(PBABillingLine.Decision::Invoice, 'Invoiced by Nikola in Teams.', 'Nikola (Teams)');
        PBABillingLine.Modify(true);

        // [THEN] It is a person's decision, named, and Create Draft Invoices puts it on the invoice
        Assert.IsTrue(PBABillingLine."Decided By Person", 'Decided By Person');
        Assert.AreEqual('Nikola (Teams)', PBABillingLine."Decided By", 'Decided By');
        Assert.AreEqual('Invoiced by Nikola in Teams.', PBABillingLine."Decision Note", 'Decision Note');
        PBADraftInvoices.CreateDraftInvoices(PBABillingRun);
        PBABillingLine.Get(PBABillingLine."Billing Run No.", PBABillingLine."Line No.");
        Assert.AreNotEqual('', PBABillingLine."Sales Invoice No.", 'The flagged line is invoiced.');
    end;

    [Test]
    procedure PersonApiCannotChangeAnInvoicedLine()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line that is already on a draft invoice
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBABillingLine."Sales Invoice No." := 'S-INV-TEST';
        PBABillingLine.Modify();

        // [WHEN] A person decision arrives through billingLineDecisions
        asserterror PBABillingLine.SetPersonDecision(PBABillingLine.Decision::Hold, '', 'Nikola (Teams)');

        // [THEN] It is refused
        Assert.ExpectedError('is already on draft invoice S-INV-TEST');
    end;

    [Test]
    procedure PersonApiIsNotForAgents()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line over the invoice cap, in an agent session
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);
        PBATestLibrary.SetAgentSession(true);

        // [WHEN] The agent tries the person door
        asserterror PBABillingLine.SetPersonDecision(PBABillingLine.Decision::Invoice, '', 'Agent');

        // [THEN] It is refused
        Assert.ExpectedError('only for decisions of a person');
    end;

    [Test]
    procedure DecidedByNamesWhoDecided()
    var
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] A line over the invoice cap
        PBATestLibrary.Initialize();
        CreateRunWithCapExceeded(PBABillingRun, PBABillingLine);

        // [WHEN] The agent holds it, and then the project manager invoices it in Business Central
        PBATestLibrary.SetAgentSession(true);
        PBABillingLine.Validate(Decision, PBABillingLine.Decision::Hold);
        // [THEN] The agent's decision names no person
        Assert.AreEqual('', PBABillingLine."Decided By", 'Decided By after the agent');

        PBATestLibrary.SetAgentSession(false);
        PBABillingLine.Validate(Decision, PBABillingLine.Decision::Invoice);
        // [THEN] The person's decision names the user
        Assert.AreNotEqual('', PBABillingLine."Decided By", 'Decided By after the person');
    end;

    [Test]
    procedure RowStyleShowsWhatNeedsAPerson()
    var
        PBABillingLine: Record "PBA Billing Line";
    begin
        // [GIVEN] Lines in every state the project manager has to tell apart
        // [THEN] Undecided: blue; held and waiting for a person (cap, please check): red; held and settled (contract,
        //        milestone): grey; invoiced over a flag by a person: yellow; invoiced and OK: no style
        Assert.AreEqual('StrongAccent', StyleOf(PBABillingLine.Check::OK, PBABillingLine.Decision::" ", '', false), 'Undecided');
        Assert.AreEqual('Unfavorable', StyleOf(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Decision::Hold, 'Over the invoice cap.', false), 'Over the cap');
        Assert.AreEqual('Unfavorable', StyleOf(PBABillingLine.Check::OK, PBABillingLine.Decision::Hold, 'Please check: the PO number.', false), 'Please check');
        Assert.AreEqual('Subordinate', StyleOf(PBABillingLine.Check::OK, PBABillingLine.Decision::Hold, 'Not billed per contract: travel time.', false), 'Per contract');
        Assert.AreEqual('Subordinate', StyleOf(PBABillingLine.Check::"Milestone Not Reached", PBABillingLine.Decision::Hold, 'Milestone not reached.', false), 'Milestone');
        Assert.AreEqual('Ambiguous', StyleOf(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Decision::Invoice, '', true), 'Invoiced by a person over the cap');
        Assert.AreEqual('Standard', StyleOf(PBABillingLine.Check::OK, PBABillingLine.Decision::Invoice, '', false), 'Invoiced');
    end;

    local procedure StyleOf(Check: Enum "PBA Billing Check"; Decision: Enum "PBA Billing Decision"; DecisionNote: Text[250]; DecidedByPerson: Boolean): Text
    var
        PBABillingLine: Record "PBA Billing Line";
    begin
        PBABillingLine.Check := Check;
        PBABillingLine.Decision := Decision;
        PBABillingLine."Decision Note" := DecisionNote;
        PBABillingLine."Decided By Person" := DecidedByPerson;
        exit(PBABillingLine.GetRowStyle());
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
