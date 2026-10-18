namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;

pageextension 50200 "PBA Job Card" extends "Job Card"
{
    layout
    {
        addafter(General)
        {
            group(PBABilling)
            {
                Caption = 'Monthly Billing';

                field("PBA Billing Method"; Rec."PBA Billing Method")
                {
                    ApplicationArea = Jobs;
                }
                field("PBA Invoice Cap"; Rec."PBA Invoice Cap")
                {
                    ApplicationArea = Jobs;
                }
                field("PBA Billing Notes"; Rec."PBA Billing Notes")
                {
                    ApplicationArea = Jobs;
                    MultiLine = true;
                }
            }
        }
    }
}
