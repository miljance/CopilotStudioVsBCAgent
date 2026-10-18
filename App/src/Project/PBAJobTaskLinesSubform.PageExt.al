namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;

pageextension 50201 "PBA Job Task Lines Subform" extends "Job Task Lines Subform"
{
    layout
    {
        addafter("End Date")
        {
            field("PBA Milestone Reached"; Rec."PBA Milestone Reached")
            {
                ApplicationArea = Jobs;
            }
            field("PBA Milestone Reached Date"; Rec."PBA Milestone Reached Date")
            {
                ApplicationArea = Jobs;
            }
        }
    }
}
