namespace Contoso.ProjectBilling;

using System.Security.AccessControl;

/// <summary>
/// Every new version of the app brings the instructions from .resources/Instructions/InstructionsV1.txt, the profile
/// and the permissions to all Project Billing agents. Change the instructions in that file, raise the app version and
/// publish.
/// </summary>
codeunit 50205 "PBA Agent Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
        User: Record User;
        PBAAgentSetup: Codeunit "PBA Agent Setup";
        AgentUserMissingTxt: Label 'A Project Billing agent user no longer exists; its instructions were not updated.', Locked = true;
    begin
        PBAAgentSetup.RegisterCapability();

        if not PBAAgentSetupRecord.FindSet() then
            exit;

        repeat
            // An agent whose user was deleted must not block the upgrade of the app.
            if User.Get(PBAAgentSetupRecord."User Security ID") then begin
                PBAAgentSetup.UpdateInstructions(PBAAgentSetupRecord."User Security ID");
                PBAAgentSetup.UpdateAccessControls(PBAAgentSetupRecord."User Security ID");
            end else
                Session.LogMessage('PBA0001', AgentUserMissingTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                    TelemetryScope::ExtensionPublisher, 'Category', 'Project Billing Agent');
        until PBAAgentSetupRecord.Next() = 0;
    end;

    /// <summary>
    /// The profile is part of the agent's user settings, which Business Central reads per company. A publish can also
    /// leave the monthly billing job in Error, so it is started again.
    /// </summary>
    trigger OnUpgradePerCompany()
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
        PBAAgentSetup: Codeunit "PBA Agent Setup";
        PBAMonthlyBillingJob: Codeunit "PBA Monthly Billing Job";
    begin
        AssignCompany();
        PBAAgentSetupRecord.SetRange("Company Name", CompanyName());
        if PBAAgentSetupRecord.FindSet() then
            repeat
                PBAAgentSetup.UpdateProfile(PBAAgentSetupRecord."User Security ID");
            until PBAAgentSetupRecord.Next() = 0;
        PBAMonthlyBillingJob.RepairJobQueueEntry();
    end;

    /// <summary>
    /// Agents created before 1.0.1 have no company. An agent belongs to the company where it got its permissions.
    /// </summary>
    local procedure AssignCompany()
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
        AccessControl: Record "Access Control";
    begin
        PBAAgentSetupRecord.SetRange("Company Name", '');
        if not PBAAgentSetupRecord.FindSet(true) then
            exit;
        repeat
            AccessControl.SetRange("User Security ID", PBAAgentSetupRecord."User Security ID");
            AccessControl.SetRange("Company Name", CompanyName());
            if not AccessControl.IsEmpty() then begin
                PBAAgentSetupRecord."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(PBAAgentSetupRecord."Company Name"));
                PBAAgentSetupRecord.Modify();
            end;
        until PBAAgentSetupRecord.Next() = 0;
    end;
}
