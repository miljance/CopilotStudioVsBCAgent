namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;

/// <summary>
/// One billable project planning line that Business Central proposes in a billing run, with what it found (Check), the
/// decision of the agent or the project manager, and the draft invoice it went to.
/// </summary>
table 50203 "PBA Billing Line"
{
    Caption = 'Billing Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Billing Run No."; Code[20])
        {
            Caption = 'Billing Run No.';
            ToolTip = 'Specifies the billing run of the line.';
            TableRelation = "PBA Billing Run";
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the line in the billing run.';
            Editable = false;
        }
        field(10; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the bill-to customer of the project. Each customer gets one draft invoice per run.';
            TableRelation = Customer;
            Editable = false;
        }
        field(11; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            ToolTip = 'Specifies the name of the bill-to customer.';
            Editable = false;
        }
        field(12; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the project of the line.';
            Editable = false;
        }
        field(13; "Job Description"; Text[100])
        {
            Caption = 'Project Description';
            ToolTip = 'Specifies the description of the project.';
            Editable = false;
        }
        field(14; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the project task of the line.';
            Editable = false;
        }
        field(15; "Job Task Description"; Text[100])
        {
            Caption = 'Project Task Description';
            ToolTip = 'Specifies the description of the project task.';
            Editable = false;
        }
        field(16; "Planning Line No."; Integer)
        {
            Caption = 'Planning Line No.';
            ToolTip = 'Specifies the project planning line that the line invoices.';
            Editable = false;
        }
        field(17; "Billing Method"; Enum "PBA Billing Method")
        {
            Caption = 'Billing Method';
            ToolTip = 'Specifies how the project is invoiced: Time and Material or Fixed Price.';
            Editable = false;
        }
        field(18; "Planning Date"; Date)
        {
            Caption = 'Planning Date';
            ToolTip = 'Specifies the date of the work (usage) or the planned date of the milestone.';
            Editable = false;
        }
        field(19; Type; Enum "Job Planning Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the planning line: resource, item or G/L account.';
            Editable = false;
        }
        field(20; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the resource, item or G/L account of the planning line.';
            Editable = false;
        }
        field(21; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what was done, as it was posted on the project. The agent compares it with the billing notes of the project.';
            Editable = false;
        }
        field(22; Quantity; Decimal)
        {
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity that is still to be invoiced on the planning line.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(23; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure of the quantity.';
            Editable = false;
        }
        field(24; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            ToolTip = 'Specifies the unit price of the planning line.';
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Editable = false;
        }
        field(25; Amount; Decimal)
        {
            Caption = 'Amount';
            ToolTip = 'Specifies the amount to invoice for the line, excluding tax, after the line discount, as Business Central calculated it.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Editable = false;
        }
        field(26; "Billing Notes"; Text[2048])
        {
            Caption = 'Billing Notes';
            ToolTip = 'Specifies the billing notes of the project at the time of the run: what the contract says about invoicing.';
            Editable = false;
        }
        field(30; Check; Enum "PBA Billing Check")
        {
            Caption = 'Check';
            ToolTip = 'Specifies what Business Central found: OK, Milestone Not Reached or Exceeds Invoice Cap. Only a person can invoice a line that is not OK.';
            Editable = false;
        }
        field(31; "Check Note"; Text[250])
        {
            Caption = 'Check Note';
            ToolTip = 'Specifies why Business Central flagged the line.';
            Editable = false;
        }
        field(32; Decision; Enum "PBA Billing Decision")
        {
            Caption = 'Decision';
            ToolTip = 'Specifies whether the line goes on the draft invoice (Invoice) or stays in the project for a later run (Hold). The agent decides every line; the project manager can change a decision until the line is on an invoice.';

            trigger OnValidate()
            var
                PBABillingProposal: Codeunit "PBA Billing Proposal";
                PBASessionContext: Codeunit "PBA Session Context";
            begin
                TestNotInvoiced();
                PBABillingProposal.ApplyInvoiceCap(Rec);
                if PBASessionContext.IsAgentSession() then
                    CheckAgentMayDecide();
                Rec."Decided By Person" := not PBASessionContext.IsAgentSession();
            end;
        }
        field(33; "Decision Note"; Text[250])
        {
            Caption = 'Decision Note';
            ToolTip = 'Specifies why the line is held, or anything the project manager should know about it.';
        }
        field(34; "Decided By Person"; Boolean)
        {
            Caption = 'Decided By Person';
            ToolTip = 'Specifies that a person, not an agent, made the current decision.';
            Editable = false;
        }
        field(35; "Sales Invoice No."; Code[20])
        {
            Caption = 'Sales Invoice No.';
            ToolTip = 'Specifies the draft sales invoice that the line went to.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Billing Run No.", "Line No.")
        {
            Clustered = true;
        }
        key(Customer; "Billing Run No.", "Customer No.", "Job No.")
        {
        }
    }

    var
        AlreadyInvoicedErr: Label 'Line %1 is already on draft invoice %2. Change the invoice instead.', Comment = '%1 = line No., %2 = sales invoice No.';
        OnlyPersonMayInvoiceErr: Label 'Line %1 is flagged (%2). Only a person can decide to invoice it: set it to Hold and ask the project manager.', Comment = '%1 = line No., %2 = check, for example Exceeds Invoice Cap';

    procedure TestNotInvoiced()
    begin
        if Rec."Sales Invoice No." <> '' then
            Error(AlreadyInvoicedErr, Rec."Line No.", Rec."Sales Invoice No.");
    end;

    /// <summary>
    /// An agent, in Business Central or through the API, may invoice only lines that Business Central found OK.
    /// </summary>
    procedure CheckAgentMayDecide()
    begin
        if (Rec.Decision = Rec.Decision::Invoice) and (Rec.Check <> Rec.Check::OK) then
            Error(OnlyPersonMayInvoiceErr, Rec."Line No.", Rec.Check);
    end;

    procedure GetPlanningLine(var JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        exit(JobPlanningLine.Get(Rec."Job No.", Rec."Job Task No.", Rec."Planning Line No."));
    end;
}
