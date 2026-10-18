namespace Contoso.ProjectBilling;

table 50201 "PBA Agent KPI"
{
    Access = Internal;
    Caption = 'Project Billing Agent KPI';
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    DataPerCompany = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the unique identifier of the agent user.';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
        }
        field(10; "Billing Runs Sent"; Integer)
        {
            Caption = 'Billing runs sent';
            ToolTip = 'Specifies how many billing runs were sent to the Project Billing Agent.';
        }
        field(20; "Instructions Version"; Text[30])
        {
            Caption = 'Instructions version';
            ToolTip = 'Specifies the app version whose instructions were last set on the agent. New tasks use these instructions; a task keeps the instructions it was created with.';
            Editable = false;
        }
        field(21; "Instructions Updated At"; DateTime)
        {
            Caption = 'Instructions updated at';
            ToolTip = 'Specifies when the instructions were last set on the agent.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
    }

    procedure AddBillingRunSent(AgentUserSecurityId: Guid)
    begin
        GetOrCreate(AgentUserSecurityId);
        Rec."Billing Runs Sent" += 1;
        Rec.Modify();
    end;

    procedure SetInstructionsVersion(AgentUserSecurityId: Guid; InstructionsVersion: Text[30])
    begin
        GetOrCreate(AgentUserSecurityId);
        Rec."Instructions Version" := InstructionsVersion;
        Rec."Instructions Updated At" := CurrentDateTime();
        Rec.Modify();
    end;

    local procedure GetOrCreate(AgentUserSecurityId: Guid)
    begin
        if Rec.Get(AgentUserSecurityId) then
            exit;
        Rec.Init();
        Rec."User Security ID" := AgentUserSecurityId;
        Rec.Insert();
    end;
}
