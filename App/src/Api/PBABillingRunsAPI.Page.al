namespace Contoso.ProjectBilling;

using Microsoft.Integration.Entity;

/// <summary>
/// Billing runs for an agent outside Business Central (Copilot Studio through the Business Central MCP server).
/// POST with a periodEnd creates the run of that month and proposes its lines (handledBy Copilot Studio Agent, no BC
/// agent task); the agent reads and decides the billingLines, then calls createDraftInvoices.
/// /api/contoso/projectBilling/v1.0/companies({id})/billingRuns
/// </summary>
page 50206 "PBA Billing Runs API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'projectBilling';
    APIVersion = 'v1.0';
    EntityName = 'billingRun';
    EntitySetName = 'billingRuns';
    EntityCaption = 'Billing Run';
    EntitySetCaption = 'Billing Runs';
    SourceTable = "PBA Billing Run";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(periodStart; Rec."Period Start")
                {
                    Caption = 'Period Start';
                    Editable = false;
                }
                field(periodEnd; Rec."Period End")
                {
                    Caption = 'Period End';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(handledBy; Rec."Handled By")
                {
                    Caption = 'Handled By';
                    Editable = false;
                }
                field(numberOfLines; Rec."No. of Lines")
                {
                    Caption = 'No. of Lines';
                    Editable = false;
                }
                field(linesToDecide; Rec."Lines to Decide")
                {
                    Caption = 'Lines to Decide';
                    Editable = false;
                }
                field(amountToInvoice; Rec."Amount to Invoice")
                {
                    Caption = 'Amount to Invoice';
                    Editable = false;
                }
                field(amountOnHold; Rec."Amount on Hold")
                {
                    Caption = 'Amount on Hold';
                    Editable = false;
                }
                field(invoiceSummary; Rec."Invoice Summary")
                {
                    Caption = 'Invoice Summary';
                    Editable = false;
                }
                field(reviewSummary; Rec."Review Summary")
                {
                    Caption = 'Review Summary';
                    Editable = false;
                }
                part(billingLines; "PBA Billing Lines API")
                {
                    Caption = 'Billing Lines';
                    EntityName = 'billingLine';
                    EntitySetName = 'billingLines';
                    SubPageLink = "Billing Run No." = field("No.");
                }
            }
        }
    }

    var
        PeriodEndRequiredErr: Label 'Specify periodEnd, a date in the month to invoice.';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PBABillingLine: Record "PBA Billing Line";
        PBABillingProposal: Codeunit "PBA Billing Proposal";
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
    begin
        if Rec."Period End" = 0D then
            Error(PeriodEndRequiredErr);
        // The lines are proposed before the platform inserts the run; they only need its No. and period.
        PBABillingRunMgt.InitRun(Rec."Period End", Enum::"PBA Billing Handler"::"Copilot Studio Agent", Rec);
        PBABillingProposal.CreateLines(Rec);
        PBABillingLine.SetRange("Billing Run No.", Rec."No.");
        if PBABillingLine.IsEmpty() then
            Rec.Status := Rec.Status::"Nothing to Invoice";
        exit(true);
    end;

    /// <summary>
    /// Creates one draft sales invoice per customer from the lines decided as Invoice; nothing is posted.
    /// </summary>
    [ServiceEnabled]
    procedure CreateDraftInvoices(var ActionContext: WebServiceActionContext)
    var
        PBADraftInvoices: Codeunit "PBA Draft Invoices";
    begin
        PBADraftInvoices.CreateDraftInvoices(Rec);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"PBA Billing Runs API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
