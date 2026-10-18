namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;

tableextension 50201 "PBA Job Task" extends "Job Task"
{
    fields
    {
        field(50200; "PBA Milestone Reached"; Boolean)
        {
            Caption = 'Milestone Reached';
            ToolTip = 'Specifies that the milestone of this task is reached. On a Fixed Price project the billing run proposes the billable lines of the task only when the milestone was reached by the end of the billing period.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not Rec."PBA Milestone Reached" then
                    Rec."PBA Milestone Reached Date" := 0D
                else
                    if Rec."PBA Milestone Reached Date" = 0D then
                        Rec."PBA Milestone Reached Date" := WorkDate();
            end;
        }
        field(50201; "PBA Milestone Reached Date"; Date)
        {
            Caption = 'Milestone Reached Date';
            ToolTip = 'Specifies when the milestone of this task was reached. The billing run compares it with the end of the billing period.';
            DataClassification = CustomerContent;
        }
    }
}
