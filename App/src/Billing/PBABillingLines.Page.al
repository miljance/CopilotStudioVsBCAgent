namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;

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
                }
                field("Customer No."; Rec."Customer No.")
                {
                }
                field("Customer Name"; Rec."Customer Name")
                {
                }
                field("Job No."; Rec."Job No.")
                {
                }
                field("Billing Method"; Rec."Billing Method")
                {
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                }
                field("Job Task Description"; Rec."Job Task Description")
                {
                }
                field("Planning Date"; Rec."Planning Date")
                {
                }
                field("No."; Rec."No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Quantity; Rec.Quantity)
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Unit Price"; Rec."Unit Price")
                {
                }
                field(Amount; Rec.Amount)
                {
                }
                field(Check; Rec.Check)
                {
                    StyleExpr = CheckStyle;
                }
                field("Check Note"; Rec."Check Note")
                {
                }
                field(Decision; Rec.Decision)
                {
                    Editable = Rec."Sales Invoice No." = '';

                    trigger OnValidate()
                    begin
                        // A decision can change the invoice cap check of the project's other lines.
                        CurrPage.Update(true);
                    end;
                }
                field("Decision Note"; Rec."Decision Note")
                {
                }
                field("Decided By Person"; Rec."Decided By Person")
                {
                    Visible = false;
                }
                field("Sales Invoice No."; Rec."Sales Invoice No.")
                {
                    trigger OnDrillDown()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, Rec."Sales Invoice No.") then
                            Page.Run(Page::"Sales Invoice", SalesHeader);
                    end;
                }
                field("Billing Notes"; Rec."Billing Notes")
                {
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
        CheckStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.Check = Rec.Check::OK then
            CheckStyle := 'Favorable'
        else
            CheckStyle := 'Attention';
    end;
}
