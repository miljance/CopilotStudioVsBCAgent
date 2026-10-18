namespace Contoso.ProjectBilling;

/// <summary>
/// One billing run per month (and per handler): what the projects can invoice for the period, created by
/// PBA Billing Run Mgt. Business Central proposes the lines, an agent decides them, Business Central creates the draft
/// invoices and a person reviews and posts them.
/// </summary>
table 50202 "PBA Billing Run"
{
    Caption = 'Billing Run';
    DataClassification = CustomerContent;
    LookupPageId = "PBA Billing Runs";
    DrillDownPageId = "PBA Billing Runs";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the billing run, made of the month it invoices.';
            Editable = false;
        }
        field(2; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the first day of the month that the run invoices.';
            Editable = false;
        }
        field(3; "Period End"; Date)
        {
            Caption = 'Period End';
            ToolTip = 'Specifies the last day of the month that the run invoices. Usage up to this date and milestones reached by this date are proposed.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date and document date of the draft invoices of the run.';
        }
        field(5; Status; Enum "PBA Billing Run Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies where the run stands: Proposed (lines wait for decisions), Invoices Created (draft invoices wait for the project manager), or Nothing to Invoice.';
            Editable = false;
        }
        field(6; "Handled By"; Enum "PBA Billing Handler")
        {
            Caption = 'Handled By';
            ToolTip = 'Specifies which agent decides the lines of the run: the Project Billing Agent in Business Central, or the Copilot Studio agent through the APIs.';
            Editable = false;
        }
        field(7; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            ToolTip = 'Specifies the task of the Project Billing Agent that works on the run.';
            Editable = false;
        }
        field(10; "Invoice Summary"; Text[2048])
        {
            Caption = 'Invoice Summary';
            ToolTip = 'Specifies the draft invoices of the run, one per customer, with their amounts, as Business Central wrote them after creating the invoices.';
            Editable = false;
        }
        field(20; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            ToolTip = 'Specifies how many billing lines Business Central proposed for the run.';
            FieldClass = FlowField;
            CalcFormula = count("PBA Billing Line" where("Billing Run No." = field("No.")));
            Editable = false;
        }
        field(21; "Lines to Decide"; Integer)
        {
            Caption = 'Lines to Decide';
            ToolTip = 'Specifies how many billing lines have no decision yet.';
            FieldClass = FlowField;
            CalcFormula = count("PBA Billing Line" where("Billing Run No." = field("No."), Decision = const(" ")));
            Editable = false;
        }
        field(22; "Amount to Invoice"; Decimal)
        {
            Caption = 'Amount to Invoice';
            ToolTip = 'Specifies the total amount of the lines decided as Invoice, excluding tax.';
            FieldClass = FlowField;
            CalcFormula = sum("PBA Billing Line".Amount where("Billing Run No." = field("No."), Decision = const(Invoice)));
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Editable = false;
        }
        field(23; "Amount on Hold"; Decimal)
        {
            Caption = 'Amount on Hold';
            ToolTip = 'Specifies the total amount of the lines decided as Hold, excluding tax. They stay in the project and come back in the next run.';
            FieldClass = FlowField;
            CalcFormula = sum("PBA Billing Line".Amount where("Billing Run No." = field("No."), Decision = const(Hold)));
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Period; "Period End")
        {
        }
    }

    trigger OnDelete()
    var
        PBABillingLine: Record "PBA Billing Line";
    begin
        PBABillingLine.SetRange("Billing Run No.", Rec."No.");
        PBABillingLine.DeleteAll();
    end;
}
