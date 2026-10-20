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
            group(Review)
            {
                Caption = 'Review Summary';
                Visible = not IsAgentSession;

                field(ReviewSummary; ReviewSummaryHtml)
                {
                    Caption = 'Review Summary';
                    ToolTip = 'Specifies the draft invoices, what is on hold and what the project manager must decide. Business Central writes it after creating the invoices; the agent sends it as its review request.';
                    ShowCaption = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    Editable = false;
                }
            }
            group(Invoices)
            {
                Caption = 'Draft Invoices';
                Visible = not IsAgentSession;

                field(InvoiceSummary; InvoiceSummaryHtml)
                {
                    Caption = 'Invoice Summary';
                    ToolTip = 'Specifies the draft invoices of the run, one per customer, with their numbers, amounts and projects.';
                    ShowCaption = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    Editable = false;
                }
            }
            // The agent copies the Review Summary into its review request. It gets the plain text: from the rich content
            // above it copied the HTML (task 150).
            group(SummariesForAgent)
            {
                Caption = 'Summaries';
                Visible = IsAgentSession;

                field("Review Summary"; Rec."Review Summary")
                {
                    MultiLine = true;
                }
                field("Invoice Summary"; Rec."Invoice Summary")
                {
                    MultiLine = true;
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

    var
        ReviewSummaryHtml: Text;
        InvoiceSummaryHtml: Text;
        IsAgentSession: Boolean;

    trigger OnOpenPage()
    var
        PBASessionContext: Codeunit "PBA Session Context";
    begin
        IsAgentSession := PBASessionContext.IsAgentSession();
    end;

    trigger OnAfterGetRecord()
    begin
        ReviewSummaryHtml := ToHtml(Rec."Review Summary");
        InvoiceSummaryHtml := ToHtml(Rec."Invoice Summary");
    end;

    /// <summary>
    /// Shows a summary as one paragraph per line, full width (rich content). The stored text stays plain, for the agent
    /// and the API.
    /// </summary>
    local procedure ToHtml(PlainText: Text) Html: Text
    var
        Line: Text;
        LineBreak: Text[1];
    begin
        LineBreak[1] := 10;
        PlainText := PlainText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;');
        foreach Line in PlainText.Split(LineBreak) do
            if Line.Trim() <> '' then
                Html += '<p>' + Line + '</p>';
    end;

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
