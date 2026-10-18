namespace Contoso.ProjectBilling;

page 50201 "PBA Agent KPI"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Project Billing Agent Summary';
    SourceTable = "PBA Agent KPI";
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            cuegroup(KeyMetrics)
            {
                Caption = 'Key Performance Indicators';

                field(BillingRunsSent; Rec."Billing Runs Sent")
                {
                }
            }
            group(Instructions)
            {
                Caption = 'Instructions';

                field(InstructionsVersion; Rec."Instructions Version")
                {
                }
                field(InstructionsUpdatedAt; Rec."Instructions Updated At")
                {
                }
            }
        }
    }

    var
        AgentDoesNotExistErr: Label 'The agent does not exist. Please check the configuration.';

    trigger OnOpenPage()
    var
        UserSecurityIDFilter: Text;
    begin
        if IsNullGuid(Rec."User Security ID") then begin
            UserSecurityIDFilter := Rec.GetFilter("User Security ID");
            if not Evaluate(Rec."User Security ID", UserSecurityIDFilter) then
                Error(AgentDoesNotExistErr);
        end;

        if not Rec.Get(Rec."User Security ID") then
            Rec.Insert();
    end;
}
