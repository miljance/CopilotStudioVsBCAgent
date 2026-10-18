namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 50253 "PBA Draft Invoice Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PBATestLibrary: Codeunit "PBA Test Library";

    [Test]
    procedure OneDraftInvoicePerCustomerAcrossProjects()
    var
        FirstProject: Record Job;
        SecondProject: Record Job;
        OtherCustomerProject: Record Job;
        Line1: Record "Job Planning Line";
        Line2: Record "Job Planning Line";
        Line3: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
        SalesLine: Record "Sales Line";
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
        FirstInvoiceNo: Code[20];
    begin
        // [GIVEN] Two projects of customer A and one of customer B, each with September usage decided as Invoice
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(FirstProject, PBATestLibrary.GetCustomer(1), 2, Line1);
        CreateProjectWithUsage(SecondProject, PBATestLibrary.GetCustomer(1), 3, Line2);
        CreateProjectWithUsage(OtherCustomerProject, PBATestLibrary.GetCustomer(2), 1, Line3);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);
        PBATestLibrary.Decide(PBABillingRun, Line1, Enum::"PBA Billing Decision"::Invoice);
        PBATestLibrary.Decide(PBABillingRun, Line2, Enum::"PBA Billing Decision"::Invoice);
        PBATestLibrary.Decide(PBABillingRun, Line3, Enum::"PBA Billing Decision"::Invoice);

        // [WHEN] The draft invoices are created
        Assert.AreEqual(2, PBADraftInvoices.CreateDraftInvoices(PBABillingRun), 'Number of invoices');

        // [THEN] Customer A's two projects share one invoice, customer B has its own, and nothing is posted
        PBATestLibrary.FindLine(PBABillingRun, Line1, PBABillingLine);
        FirstInvoiceNo := PBABillingLine."Sales Invoice No.";
        Assert.AreNotEqual('', FirstInvoiceNo, 'Line 1 invoiced');
        PBATestLibrary.FindLine(PBABillingRun, Line2, PBABillingLine);
        Assert.AreEqual(FirstInvoiceNo, PBABillingLine."Sales Invoice No.", 'Same customer, same invoice');
        PBATestLibrary.FindLine(PBABillingRun, Line3, PBABillingLine);
        Assert.AreNotEqual(FirstInvoiceNo, PBABillingLine."Sales Invoice No.", 'Other customer, other invoice');

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", FirstInvoiceNo);
        SalesLine.SetFilter("Job No.", '%1|%2', FirstProject."No.", SecondProject."No.");
        Assert.AreEqual(2, SalesLine.Count(), 'Both projects on the invoice');

        PBABillingRun.Get(PBABillingRun."No.");
        Assert.AreEqual(PBABillingRun.Status::"Invoices Created", PBABillingRun.Status, 'Status');
        Assert.IsTrue(StrPos(PBABillingRun."Invoice Summary", FirstInvoiceNo) > 0, 'Summary names the invoice');
        Assert.IsTrue(StrPos(PBABillingRun."Invoice Summary", '5,000.00') > 0, 'Expected ' + '5,000.00');
    end;

    [Test]
    procedure HeldLineStaysInTheProject()
    var
        Job: Record Job;
        Usage: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
    begin
        // [GIVEN] A line decided as Hold
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(Job, PBATestLibrary.GetCustomer(1), 2, Usage);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);
        PBATestLibrary.Decide(PBABillingRun, Usage, Enum::"PBA Billing Decision"::Hold);

        // [WHEN] The draft invoices are created
        Assert.AreEqual(0, PBADraftInvoices.CreateDraftInvoices(PBABillingRun), 'Number of invoices');

        // [THEN] The line is not invoiced and is still to be invoiced on the project
        PBATestLibrary.FindLine(PBABillingRun, Usage, PBABillingLine);
        Assert.AreEqual('', PBABillingLine."Sales Invoice No.", 'Held line not invoiced');
        Usage.Get(Usage."Job No.", Usage."Job Task No.", Usage."Line No.");
        Assert.AreEqual(2, Usage."Qty. to Transfer to Invoice", 'Still to invoice');
    end;

    [Test]
    procedure UndecidedLinesBlockTheInvoices()
    var
        Job: Record Job;
        Usage: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
    begin
        // [GIVEN] A run with a line without a decision
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(Job, PBATestLibrary.GetCustomer(1), 2, Usage);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);

        // [WHEN] The draft invoices are created
        asserterror PBADraftInvoices.CreateDraftInvoices(PBABillingRun);

        // [THEN] It is refused
        Assert.ExpectedError('lines without a decision');
    end;

    [Test]
    procedure SecondRoundAddsToTheCustomersInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        First: Record "Job Planning Line";
        Second: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] Two lines of one customer: one invoiced, one held by the agent
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(Job, PBATestLibrary.GetCustomer(1), 2, First);
        JobTask.Get(First."Job No.", First."Job Task No.");
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(20, 9, 2026), 'Workshop', 1, 1000, Second);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);
        PBATestLibrary.Decide(PBABillingRun, First, Enum::"PBA Billing Decision"::Invoice);
        PBATestLibrary.Decide(PBABillingRun, Second, Enum::"PBA Billing Decision"::Hold);
        PBADraftInvoices.CreateDraftInvoices(PBABillingRun);
        PBATestLibrary.FindLine(PBABillingRun, First, PBABillingLine);
        InvoiceNo := PBABillingLine."Sales Invoice No.";

        // [WHEN] The project manager invoices the held line and the invoices are created again
        PBATestLibrary.Decide(PBABillingRun, Second, Enum::"PBA Billing Decision"::Invoice);
        PBADraftInvoices.CreateDraftInvoices(PBABillingRun);

        // [THEN] The line goes to the same draft invoice
        PBATestLibrary.FindLine(PBABillingRun, Second, PBABillingLine);
        Assert.AreEqual(InvoiceNo, PBABillingLine."Sales Invoice No.", 'Same invoice');
    end;

    [Test]
    procedure ReviewSummaryIsShort()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Invoiced: Record "Job Planning Line";
        Travel: Record "Job Planning Line";
        OverCap: Record "Job Planning Line";
        PBABillingRun: Record "PBA Billing Run";
        PBABillingLine: Record "PBA Billing Line";
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
        CustomerName: Text;
    begin
        // [GIVEN] One line invoiced (2,000), one held per contract (1,000), one over the cap and held for the project manager (3,000)
        PBATestLibrary.Initialize();
        CreateProjectWithUsage(Job, PBATestLibrary.GetCustomer(1), 2, Invoiced);
        Job."PBA Invoice Cap" := 4000;
        Job.Modify();
        JobTask.Get(Invoiced."Job No.", Invoiced."Job Task No.");
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(16, 9, 2026), 'Travel to the customer', 1, 1000, Travel);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(20, 9, 2026), 'Gift card extension', 3, 1000, OverCap);
        PBATestLibrary.CreateRun(DMY2Date(1, 9, 2026), PBABillingRun);
        PBATestLibrary.SetAgentSession(true);
        PBATestLibrary.Decide(PBABillingRun, Invoiced, Enum::"PBA Billing Decision"::Invoice);
        PBATestLibrary.Decide(PBABillingRun, Travel, Enum::"PBA Billing Decision"::Hold);
        PBATestLibrary.Decide(PBABillingRun, OverCap, Enum::"PBA Billing Decision"::Hold);
        PBATestLibrary.FindLine(PBABillingRun, OverCap, PBABillingLine);
        Assert.AreEqual(PBABillingLine.Check::"Exceeds Invoice Cap", PBABillingLine.Check, 'Precondition: over the cap');

        // [WHEN] The draft invoices are created
        PBADraftInvoices.CreateDraftInvoices(PBABillingRun);

        // [THEN] The review summary names the invoice, the held total and only the line the project manager must decide
        PBABillingRun.Get(PBABillingRun."No.");
        CustomerName := Job."Bill-to Name";
        Assert.IsTrue(StrPos(PBABillingRun."Review Summary", '1 draft invoice: ' + CustomerName + ' 2,000.00') > 0, PBABillingRun."Review Summary");
        Assert.IsTrue(StrPos(PBABillingRun."Review Summary", 'On hold: 2 lines, 4,000.00.') > 0, PBABillingRun."Review Summary");
        Assert.IsTrue(StrPos(PBABillingRun."Review Summary", 'Your decision: Gift card extension (' + Job."No." + ', 3,000.00), over the invoice cap.') > 0, PBABillingRun."Review Summary");
        Assert.IsTrue(StrPos(PBABillingRun."Review Summary", 'Travel') = 0, 'A line held per contract needs no decision.');
    end;

    local procedure CreateProjectWithUsage(var Job: Record Job; CustomerNo: Code[20]; Qty: Decimal; var Usage: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
    begin
        PBATestLibrary.CreateProject(Job, CustomerNo, Enum::"PBA Billing Method"::"Time and Material");
        PBATestLibrary.CreateTask(Job, 'T100', JobTask);
        PBATestLibrary.CreateUsageLine(JobTask, DMY2Date(15, 9, 2026), 'Configuration', Qty, 1000, Usage);
    end;
}
