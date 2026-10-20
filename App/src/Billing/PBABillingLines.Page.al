namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;

/// <summary>
/// The lines of a billing run. The whole row is colored by what it needs (see PBA Billing Line.GetRowStyle): blue
/// undecided, red waiting for a person, grey held and settled, yellow invoiced by a person over a flag. Decision and
/// Decision Note come right after the description, so a held line is seen without scrolling.
/// </summary>
page 50205 "PBA Billing Lines"
{
    PageType = ListPart;
    ApplicationArea = Jobs;
    Caption = 'Billing Lines';
    SourceTable = "PBA Billing Line";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                    StyleExpr = RowStyle;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    StyleExpr = RowStyle;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    StyleExpr = RowStyle;
                }
                field("Job No."; Rec."Job No.")
                {
                    StyleExpr = RowStyle;
                }
                field(Description; Rec.Description)
                {
                    StyleExpr = RowStyle;
                }
                field(Amount; Rec.Amount)
                {
                    StyleExpr = RowStyle;
                }
                field(Decision; Rec.Decision)
                {
                    Editable = Rec."Sales Invoice No." = '';
                    StyleExpr = RowStyle;

                    trigger OnValidate()
                    begin
                        // A decision can change the invoice cap check of the project's other lines.
                        CurrPage.Update(true);
                    end;
                }
                field("Decision Note"; Rec."Decision Note")
                {
                    StyleExpr = RowStyle;
                }
                field(Check; Rec.Check)
                {
                    StyleExpr = RowStyle;
                }
                field("Check Note"; Rec."Check Note")
                {
                    StyleExpr = RowStyle;
                }
                field("Decided By"; Rec."Decided By")
                {
                    StyleExpr = RowStyle;
                }
                field("Sales Invoice No."; Rec."Sales Invoice No.")
                {
                    StyleExpr = RowStyle;

                    trigger OnDrillDown()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Sales Invoice No.") then
                            Page.Run(Page::"Sales Invoice", SalesHeader);
                    end;
                }
                field("Billing Method"; Rec."Billing Method")
                {
                    StyleExpr = RowStyle;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    StyleExpr = RowStyle;
                }
                field("Job Task Description"; Rec."Job Task Description")
                {
                    StyleExpr = RowStyle;
                }
                field("Planning Date"; Rec."Planning Date")
                {
                    StyleExpr = RowStyle;
                }
                field("No."; Rec."No.")
                {
                    StyleExpr = RowStyle;
                }
                field(Quantity; Rec.Quantity)
                {
                    StyleExpr = RowStyle;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    StyleExpr = RowStyle;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    StyleExpr = RowStyle;
                }
                field("Decided By Person"; Rec."Decided By Person")
                {
                    Visible = false;
                    StyleExpr = RowStyle;
                }
                field("Billing Notes"; Rec."Billing Notes")
                {
                    StyleExpr = RowStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenProject)
            {
                Caption = 'Project';
                Image = Job;
                ToolTip = 'Open the project of the line.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    Job.Get(Rec."Job No.");
                    Page.Run(Page::"Job Card", Job);
                end;
            }
        }
    }

    var
        RowStyle: Text;

    trigger OnAfterGetRecord()
    begin
        RowStyle := Rec.GetRowStyle();
    end;
}
