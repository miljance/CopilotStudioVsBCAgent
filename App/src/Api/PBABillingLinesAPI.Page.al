namespace Contoso.ProjectBilling;

/// <summary>
/// Billing lines for an agent outside Business Central. Only decision and decisionNote can be changed. A person's
/// decision (for example from a Teams approval card) goes through billingLineDecisions instead. Like the Project
/// Billing Agent, a caller of this API may set Invoice only on lines whose check is OK: flagged lines are decided by a
/// person on the Billing Run card.
/// /api/contoso/projectBilling/v1.0/companies({id})/billingLines
/// </summary>
page 50207 "PBA Billing Lines API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'projectBilling';
    APIVersion = 'v1.0';
    EntityName = 'billingLine';
    EntitySetName = 'billingLines';
    EntityCaption = 'Billing Line';
    EntitySetCaption = 'Billing Lines';
    SourceTable = "PBA Billing Line";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
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
                field(billingRunNumber; Rec."Billing Run No.")
                {
                    Caption = 'Billing Run No.';
                    Editable = false;
                }
                field(lineNumber; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }
                field(customerNumber; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                    Editable = false;
                }
                field(customerName; Rec."Customer Name")
                {
                    Caption = 'Customer Name';
                    Editable = false;
                }
                field(projectNumber; Rec."Job No.")
                {
                    Caption = 'Project No.';
                    Editable = false;
                }
                field(projectDescription; Rec."Job Description")
                {
                    Caption = 'Project Description';
                    Editable = false;
                }
                field(projectTaskNumber; Rec."Job Task No.")
                {
                    Caption = 'Project Task No.';
                    Editable = false;
                }
                field(projectTaskDescription; Rec."Job Task Description")
                {
                    Caption = 'Project Task Description';
                    Editable = false;
                }
                field(billingMethod; Rec."Billing Method")
                {
                    Caption = 'Billing Method';
                    Editable = false;
                }
                field(planningDate; Rec."Planning Date")
                {
                    Caption = 'Planning Date';
                    Editable = false;
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                    Editable = false;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    Editable = false;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                    Editable = false;
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    Editable = false;
                }
                field(billingNotes; Rec."Billing Notes")
                {
                    Caption = 'Billing Notes';
                    Editable = false;
                }
                field(check; Rec.Check)
                {
                    Caption = 'Check';
                    Editable = false;
                }
                field(checkNote; Rec."Check Note")
                {
                    Caption = 'Check Note';
                    Editable = false;
                }
                field(decision; Rec.Decision)
                {
                    Caption = 'Decision';

                    trigger OnValidate()
                    begin
                        Rec.CheckAgentMayDecide();
                        Rec."Decided By Person" := false;
                        Rec."Decided By" := '';
                    end;
                }
                field(decisionNote; Rec."Decision Note")
                {
                    Caption = 'Decision Note';
                }
                field(salesInvoiceNumber; Rec."Sales Invoice No.")
                {
                    Caption = 'Sales Invoice No.';
                    Editable = false;
                }
                field(decidedByPerson; Rec."Decided By Person")
                {
                    Caption = 'Decided By Person';
                    Editable = false;
                }
                field(decidedBy; Rec."Decided By")
                {
                    Caption = 'Decided By';
                    Editable = false;
                }
            }
        }
    }
}
