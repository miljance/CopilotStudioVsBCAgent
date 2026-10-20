namespace Contoso.ProjectBilling;

/// <summary>
/// A person's decision on a billing line from outside Business Central, for example the project manager's answer on the
/// Teams approval card of the Copilot Studio workflow. Unlike billingLines it may invoice a flagged line, as a decision in
/// the client may: the line is marked Decided By Person. Not for agents: keep this page out of every MCP server
/// configuration; only the step that handles the person's response calls it.
/// PATCH /api/contoso/projectBilling/v1.0/companies({id})/billingLineDecisions({id}) { "decision", "decisionNote", "decidedBy" }
/// </summary>
page 50209 "PBA Billing Line Decisions API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'projectBilling';
    APIVersion = 'v1.0';
    EntityName = 'billingLineDecision';
    EntitySetName = 'billingLineDecisions';
    EntityCaption = 'Billing Line Decision';
    EntitySetCaption = 'Billing Line Decisions';
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
                field(projectNumber; Rec."Job No.")
                {
                    Caption = 'Project No.';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    Editable = false;
                }
                field(check; Rec.Check)
                {
                    Caption = 'Check';
                    Editable = false;
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
                field(decision; NewDecision)
                {
                    Caption = 'Decision';

                    trigger OnValidate()
                    begin
                        DecisionSet := true;
                    end;
                }
                field(decisionNote; NewDecisionNote)
                {
                    Caption = 'Decision Note';

                    trigger OnValidate()
                    begin
                        DecisionNoteSet := true;
                    end;
                }
                field(decidedBy; NewDecidedBy)
                {
                    Caption = 'Decided By';
                }
            }
        }
    }

    var
        NewDecision: Enum "PBA Billing Decision";
        NewDecisionNote: Text[250];
        NewDecidedBy: Text[100];
        DecisionSet: Boolean;
        DecisionNoteSet: Boolean;

    trigger OnAfterGetRecord()
    begin
        NewDecision := Rec.Decision;
        NewDecisionNote := Rec."Decision Note";
        NewDecidedBy := Rec."Decided By";
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if not DecisionSet then
            NewDecision := Rec.Decision;
        if not DecisionNoteSet then
            NewDecisionNote := Rec."Decision Note";
        Rec.SetPersonDecision(NewDecision, NewDecisionNote, NewDecidedBy);
        exit(true);
    end;
}
