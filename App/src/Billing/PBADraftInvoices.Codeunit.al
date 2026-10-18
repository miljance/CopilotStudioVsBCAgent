namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;

/// <summary>
/// Creates the draft sales invoices of a billing run with the standard project invoicing (Job Create-Invoice): one
/// invoice per customer, with every line decided as Invoice from all of the customer's projects. Lines on Hold stay in
/// the project and come back in the next run. Called again after the project manager changed decisions, it adds the
/// new Invoice lines to the customer's open draft invoice of the run. Invoices are never posted here.
/// </summary>
codeunit 50207 "PBA Draft Invoices"
{
    Access = Internal;
    Permissions = tabledata "Sales Header" = rim,
                  tabledata "Sales Line" = rim,
                  tabledata "Job Planning Line" = rm,
                  tabledata "Job Planning Line Invoice" = ri;

    var
        UndecidedLinesErr: Label 'Billing run %1 has %2 lines without a decision. Decide every line as Invoice or Hold first.', Comment = '%1 = billing run No., %2 = number of lines';
        FlaggedLineErr: Label 'Line %1 is flagged (%2) and was not decided by a person, so it is not invoiced.', Comment = '%1 = line No., %2 = check';
        SummaryLineTxt: Label '%1 for %2 (%3): %4 excl. tax, %5 lines, projects %6', Comment = '%1 = sales invoice No., %2 = customer name, %3 = customer No., %4 = amount, %5 = number of lines, %6 = project numbers';
        NoInvoiceTxt: Label 'No lines are decided as Invoice: no draft invoice was created.';

    /// <summary>
    /// Returns how many draft invoices the run has after the call.
    /// </summary>
    procedure CreateDraftInvoices(var PBABillingRun: Record "PBA Billing Run"): Integer
    var
        PBABillingLine: Record "PBA Billing Line";
        LineNos: List of [Integer];
        LineNo: Integer;
    begin
        PBABillingRun.CalcFields("Lines to Decide");
        if PBABillingRun."Lines to Decide" > 0 then
            Error(UndecidedLinesErr, PBABillingRun."No.", PBABillingRun."Lines to Decide");

        PBABillingLine.SetCurrentKey("Billing Run No.", "Customer No.", "Job No.");
        PBABillingLine.SetRange("Billing Run No.", PBABillingRun."No.");
        PBABillingLine.SetRange(Decision, PBABillingLine.Decision::Invoice);
        PBABillingLine.SetRange("Sales Invoice No.", '');
        // Collected first: invoicing a line changes Sales Invoice No., which is part of the filter.
        if PBABillingLine.FindSet() then
            repeat
                if (PBABillingLine.Check <> PBABillingLine.Check::OK) and not PBABillingLine."Decided By Person" then
                    Error(FlaggedLineErr, PBABillingLine."Line No.", PBABillingLine.Check);
                LineNos.Add(PBABillingLine."Line No.");
            until PBABillingLine.Next() = 0;

        foreach LineNo in LineNos do begin
            PBABillingLine.Get(PBABillingRun."No.", LineNo);
            InvoiceLine(PBABillingRun, PBABillingLine);
        end;

        PBABillingRun.Status := PBABillingRun.Status::"Invoices Created";
        PBABillingRun."Invoice Summary" := CopyStr(BuildSummary(PBABillingRun), 1, MaxStrLen(PBABillingRun."Invoice Summary"));
        PBABillingRun.Modify();
        exit(CountInvoices(PBABillingRun));
    end;

    local procedure InvoiceLine(PBABillingRun: Record "PBA Billing Run"; var PBABillingLine: Record "PBA Billing Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        InvoiceNo: Code[20];
    begin
        PBABillingLine.GetPlanningLine(JobPlanningLine);
        JobPlanningLine.SetRecFilter();
        InvoiceNo := FindOpenInvoiceOfCustomer(PBABillingRun."No.", PBABillingLine."Customer No.");
        JobCreateInvoice.CreateSalesInvoiceLines(
            JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, InvoiceNo = '',
            PBABillingRun."Posting Date", PBABillingRun."Posting Date", false);

        JobPlanningLineInvoice.SetRange("Job No.", PBABillingLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", PBABillingLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", PBABillingLine."Planning Line No.");
        JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice);
        JobPlanningLineInvoice.FindLast();
        PBABillingLine."Sales Invoice No." := JobPlanningLineInvoice."Document No.";
        PBABillingLine.Modify();
    end;

    /// <summary>
    /// The customer's draft invoice from this run that is still open, so a second call adds to it.
    /// </summary>
    local procedure FindOpenInvoiceOfCustomer(BillingRunNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        PBABillingLine: Record "PBA Billing Line";
        SalesHeader: Record "Sales Header";
    begin
        PBABillingLine.SetCurrentKey("Billing Run No.", "Customer No.", "Job No.");
        PBABillingLine.SetRange("Billing Run No.", BillingRunNo);
        PBABillingLine.SetRange("Customer No.", CustomerNo);
        PBABillingLine.SetFilter("Sales Invoice No.", '<>%1', '');
        if PBABillingLine.FindSet() then
            repeat
                if SalesHeader.Get(SalesHeader."Document Type"::Invoice, PBABillingLine."Sales Invoice No.") then
                    if SalesHeader.Status = SalesHeader.Status::Open then
                        exit(SalesHeader."No.");
            until PBABillingLine.Next() = 0;
        exit('');
    end;

    procedure BuildSummary(PBABillingRun: Record "PBA Billing Run") Summary: Text
    var
        PBABillingLine: Record "PBA Billing Line";
        SalesHeader: Record "Sales Header";
        InvoiceNos: List of [Code[20]];
        InvoiceNo: Code[20];
        Projects: Text;
        NewLine: Text[1];
        LineCount: Integer;
    begin
        NewLine[1] := 10;
        PBABillingLine.SetCurrentKey("Billing Run No.", "Customer No.", "Job No.");
        PBABillingLine.SetRange("Billing Run No.", PBABillingRun."No.");
        PBABillingLine.SetFilter("Sales Invoice No.", '<>%1', '');
        if PBABillingLine.FindSet() then
            repeat
                if not InvoiceNos.Contains(PBABillingLine."Sales Invoice No.") then
                    InvoiceNos.Add(PBABillingLine."Sales Invoice No.");
            until PBABillingLine.Next() = 0;

        if InvoiceNos.Count() = 0 then
            exit(NoInvoiceTxt);

        foreach InvoiceNo in InvoiceNos do begin
            PBABillingLine.SetRange("Sales Invoice No.", InvoiceNo);
            LineCount := PBABillingLine.Count();
            Projects := '';
            PBABillingLine.FindSet();
            repeat
                if StrPos(', ' + Projects + ',', ', ' + PBABillingLine."Job No." + ',') = 0 then
                    if Projects = '' then
                        Projects := PBABillingLine."Job No."
                    else
                        Projects += ', ' + PBABillingLine."Job No.";
            until PBABillingLine.Next() = 0;

            if SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo) then begin
                SalesHeader.CalcFields(Amount);
                if Summary <> '' then
                    Summary += NewLine;
                Summary += StrSubstNo(SummaryLineTxt, InvoiceNo, SalesHeader."Bill-to Name", SalesHeader."Bill-to Customer No.",
                    Format(SalesHeader.Amount, 0, '<Precision,2:2><Standard Format,0>'), LineCount, Projects);
            end;
        end;
    end;

    local procedure CountInvoices(PBABillingRun: Record "PBA Billing Run"): Integer
    var
        PBABillingLine: Record "PBA Billing Line";
        InvoiceNos: List of [Code[20]];
    begin
        PBABillingLine.SetRange("Billing Run No.", PBABillingRun."No.");
        PBABillingLine.SetFilter("Sales Invoice No.", '<>%1', '');
        if PBABillingLine.FindSet() then
            repeat
                if not InvoiceNos.Contains(PBABillingLine."Sales Invoice No.") then
                    InvoiceNos.Add(PBABillingLine."Sales Invoice No.");
            until PBABillingLine.Next() = 0;
        exit(InvoiceNos.Count());
    end;
}
