namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;

tableextension 50200 "PBA Job" extends Job
{
    fields
    {
        field(50200; "PBA Billing Method"; Enum "PBA Billing Method")
        {
            Caption = 'Billing Method';
            ToolTip = 'Specifies how the monthly billing run invoices the project. Blank: the run leaves the project alone. Time and Material: it proposes the usage posted as billable. Fixed Price: it proposes the planned billable lines of a milestone task once the milestone is reached.';
            DataClassification = CustomerContent;
        }
        field(50201; "PBA Invoice Cap"; Decimal)
        {
            Caption = 'Invoice Cap';
            ToolTip = 'Specifies the most that may be invoiced on the project in total (not to exceed), in the project currency. Lines that would go over it are flagged in the billing run and only a person can invoice them. 0 means no cap.';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            MinValue = 0;
        }
        field(50202; "PBA Billing Notes"; Text[2048])
        {
            Caption = 'Billing Notes';
            ToolTip = 'Specifies what the contract says about invoicing, in plain words, for example which work is not billed. The Project Billing Agent reads these notes for every line it decides.';
            DataClassification = CustomerContent;
        }
    }
}
