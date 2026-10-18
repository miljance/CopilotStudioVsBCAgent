namespace Contoso.ProjectBilling;

using Microsoft.Sales.Document;

/// <summary>
/// The billing run: what Business Central proposed, the decisions per line and, after Create Draft Invoices, one draft
/// invoice per customer. The Project Billing Agent asks the project manager for review on this page; the project
/// manager checks the invoices, may change decisions, and chooses Continue in the task pane.
/// </summary>
page 50204 "PBA Billing Run"
{
    PageType = Document;
    ApplicationArea = Jobs;
    Caption = 'Billing Run';
    SourceTable = "PBA Billing Run";
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                }
                field("Period Start"; Rec."Period Start")
                {
                }
                field("Period End"; Rec."Period End")
                {
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    Editable = Rec.Status = Rec.Status::Proposed;
                }
                field(Status; Rec.Status)
                {
                }
                field("Handled By"; Rec."Handled By")
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
            group(Invoices)
            {
                Caption = 'Draft Invoices';

                field("Invoice Summary"; Rec."Invoice Summary")
                {
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            part(Lines; "PBA Billing Lines")
            {
                Caption = 'Lines';
                SubPageLink = "Billing Run No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateDraftInvoices)
            {
                Caption = 'Create Draft Invoices';
                Image = CreateDocuments;
                ToolTip = 'Create one draft sales invoice per customer with every line decided as Invoice. Run it again after decisions changed: new Invoice lines go to the customer''s open draft invoice of this run. Nothing is posted.';

                trigger OnAction()
                var
                    PBADraftInvoices: Codeunit "PBA Draft Invoices";
                begin
                    PBADraftInvoices.CreateDraftInvoices(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(SalesInvoices)
            {
                Caption = 'Sales Invoices';
                Image = SalesInvoice;
                ToolTip = 'Open the draft sales invoices of this run.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.SetFilter("No.", GetInvoiceFilter());
                    Page.Run(Page::"Sales Invoice List", SalesHeader);
                end;
            }
        }
        area(Promoted)
        {
            actionref(CreateDraftInvoices_Promoted; CreateDraftInvoices)
            {
            }
            actionref(SalesInvoices_Promoted; SalesInvoices)
            {
            }
        }
    }

    local procedure GetInvoiceFilter() InvoiceFilter: Text
    var
        PBABillingLine: Record "PBA Billing Line";
    begin
        PBABillingLine.SetRange("Billing Run No.", Rec."No.");
        PBABillingLine.SetFilter("Sales Invoice No.", '<>%1', '');
        if PBABillingLine.FindSet() then
            repeat
                if StrPos('|' + InvoiceFilter + '|', '|' + PBABillingLine."Sales Invoice No." + '|') = 0 then
                    if InvoiceFilter = '' then
                        InvoiceFilter := PBABillingLine."Sales Invoice No."
                    else
                        InvoiceFilter += '|' + PBABillingLine."Sales Invoice No.";
            until PBABillingLine.Next() = 0;
        if InvoiceFilter = '' then
            InvoiceFilter := '''''';
    end;
}
