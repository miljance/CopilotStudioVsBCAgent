namespace Contoso.ProjectBilling;

codeunit 50201 "PBA Agent Install"
{
    Subtype = Install;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
        PBAAgentSetup: Codeunit "PBA Agent Setup";
    begin
        PBAAgentSetup.RegisterCapability();

        if not PBAAgentSetupRecord.FindSet() then
            exit;

        repeat
            PBAAgentSetup.UpdateInstructions(PBAAgentSetupRecord."User Security ID");
        until PBAAgentSetupRecord.Next() = 0;
    end;
}
