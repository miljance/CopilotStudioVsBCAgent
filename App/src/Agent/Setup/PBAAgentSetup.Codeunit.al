namespace Contoso.ProjectBilling;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

/// <summary>
/// Identity, profile, permissions and instructions of the Project Billing Agent.
/// </summary>
codeunit 50203 "PBA Agent Setup"
{
    Access = Internal;

    var
        Agent: Codeunit Agent;
        BaseApplicationAppIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        DefaultPermissionSetTok: Label 'D365 READ', Locked = true;
        AgentEditPermissionSetTok: Label 'PBA AGENT EDIT', Locked = true;
        DefaultProfileTok: Label 'PROJECT BILLING AGENT', Locked = true;
        InstructionsResourceTok: Label 'Instructions/InstructionsV1.txt', Locked = true;
        AgentInitialsLbl: Label 'PB', MaxLength = 4;
        AgentNameLbl: Label 'PROJECT BILLING AGENT', Locked = true;
        DefaultDisplayNameLbl: Label 'Project Billing Agent';
        AgentSummaryLbl: Label 'Prepares the monthly project invoices and asks the project manager to review them.';

    procedure GetInitials(): Text[4]
    begin
        exit(AgentInitialsLbl);
    end;

    procedure GetSetupPageId(): Integer
    begin
        exit(Page::"PBA Agent Setup");
    end;

    procedure GetSummaryPageId(): Integer
    begin
        exit(Page::"PBA Agent KPI");
    end;

    [NonDebuggable]
    procedure GetInstructions(): SecretText
    var
        Instructions: Text;
    begin
        Instructions := NavApp.GetResourceAsText(InstructionsResourceTok);
        exit(Instructions);
    end;

    /// <summary>
    /// The agent starts on its own home page (profile "Project Billing Agent"), whose menu has every page the
    /// instructions use: an agent cannot search for pages.
    /// </summary>
    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Agent.PopulateDefaultProfile(DefaultProfileTok, CurrentModuleInfo.Id(), TempAllProfile);
    end;

    procedure UpdateProfile(AgentUserSecurityId: Guid)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Agent.SetProfile(AgentUserSecurityId, DefaultProfileTok, CurrentModuleInfo.Id());
    end;

    /// <summary>
    /// D365 READ to read projects, planning lines and invoices, and PBA Agent Edit to record its decisions on the
    /// billing lines and to create the draft invoices through the Billing Run card.
    /// </summary>
    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        TempAccessControlBuffer.Reset();
        TempAccessControlBuffer.DeleteAll();
        AddAccessControl(TempAccessControlBuffer, GetBaseApplicationAppId(), DefaultPermissionSetTok);
        AddAccessControl(TempAccessControlBuffer, CurrentModuleInfo.Id(), AgentEditPermissionSetTok);
    end;

    procedure UpdateAccessControls(AgentUserSecurityId: Guid)
    var
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
    begin
        GetDefaultAccessControls(TempAccessControlBuffer);
        Agent.UpdateAccessControl(AgentUserSecurityId, TempAccessControlBuffer);
    end;

    local procedure AddAccessControl(var TempAccessControlBuffer: Record "Access Control Buffer" temporary; AppId: Guid; RoleId: Code[20])
    begin
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := AppId;
        TempAccessControlBuffer."Role ID" := RoleId;
        TempAccessControlBuffer.Insert();
    end;

    procedure GetAgentMetadataProvider(): Enum "Agent Metadata Provider"
    begin
        exit(Enum::"Agent Metadata Provider"::"Project Billing Agent");
    end;

    procedure GetAgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentNameLbl + ' - ' + CompanyName(), 1, 50));
    end;

    procedure GetDefaultDisplayName(): Text[80]
    begin
        exit(DefaultDisplayNameLbl);
    end;

    procedure GetAgentSummary(): Text
    begin
        exit(AgentSummaryLbl);
    end;

    /// <summary>
    /// Returns the active Project Billing agent of the current company, if there is one.
    /// </summary>
    procedure TryGetActiveAgent(var AgentUserSecurityId: Guid): Boolean
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
    begin
        Clear(AgentUserSecurityId);
        PBAAgentSetupRecord.SetRange("Company Name", CompanyName());
        if not PBAAgentSetupRecord.FindSet() then
            exit(false);

        repeat
            if Agent.IsActive(PBAAgentSetupRecord."User Security ID") then begin
                AgentUserSecurityId := PBAAgentSetupRecord."User Security ID";
                exit(true);
            end;
        until PBAAgentSetupRecord.Next() = 0;

        exit(false);
    end;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/ai-development-toolkit-landing-page', Locked = true;
    begin
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Project Billing Agent") then
            CopilotCapability.UnregisterCapability(Enum::"Copilot Capability"::"Project Billing Agent");

        CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"Project Billing Agent",
            Enum::"Copilot Availability"::Preview,
            "Copilot Billing Type"::"Microsoft Billed",
            LearnMoreUrlTxt);
    end;

    procedure UpdateInstructions(AgentUserSecurityId: Guid)
    var
        PBAAgentKPI: Record "PBA Agent KPI";
        CurrentModuleInfo: ModuleInfo;
    begin
        Agent.SetInstructions(AgentUserSecurityId, GetInstructions());
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        PBAAgentKPI.SetInstructionsVersion(AgentUserSecurityId, CopyStr(Format(CurrentModuleInfo.AppVersion()), 1, 30));
    end;

    procedure InitializeSetupRecord(var TempPBAAgentSetup: Record "PBA Agent Setup" temporary)
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
    begin
        if not IsNullGuid(TempPBAAgentSetup."User Security ID") then
            if PBAAgentSetupRecord.Get(TempPBAAgentSetup."User Security ID") then
                TempPBAAgentSetup.TransferFields(PBAAgentSetupRecord, false);

        if TempPBAAgentSetup.IsEmpty() then
            TempPBAAgentSetup.Insert();
    end;

    /// <summary>
    /// Saves the agent and schedules the monthly billing job in this company, so the agent gets its first task on the
    /// first day of the next month.
    /// </summary>
    procedure SaveSetupRecord(var TempPBAAgentSetup: Record "PBA Agent Setup" temporary; var TempAgentSetupBuffer: Record "Agent Setup Buffer")
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
        AgentSetup: Codeunit "Agent Setup";
        PBAMonthlyBillingJob: Codeunit "PBA Monthly Billing Job";
        IsNewAgent: Boolean;
    begin
        IsNewAgent := IsNullGuid(TempAgentSetupBuffer."User Security ID");

        if AgentSetup.GetChangesMade(TempAgentSetupBuffer) then begin
            TempPBAAgentSetup."User Security ID" := AgentSetup.SaveChanges(TempAgentSetupBuffer);
            if IsNewAgent then
                UpdateInstructions(TempPBAAgentSetup."User Security ID");
        end;

        if IsNullGuid(TempPBAAgentSetup."User Security ID") then
            exit;

        RestrictUsersToCompany(TempPBAAgentSetup."User Security ID", CopyStr(CompanyName(), 1, 30));
        PBAMonthlyBillingJob.EnsureJobQueueEntry();

        if PBAAgentSetupRecord.Get(TempPBAAgentSetup."User Security ID") then
            exit;

        PBAAgentSetupRecord.Init();
        PBAAgentSetupRecord."User Security ID" := TempPBAAgentSetup."User Security ID";
        PBAAgentSetupRecord."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(PBAAgentSetupRecord."Company Name"));
        PBAAgentSetupRecord.Insert();
    end;

    /// <summary>
    /// The setup dialog gives the users of the agent access in all companies (blank Company Name), so the agent showed up
    /// in every company. A Project Billing agent works in one company: every user entry is limited to that company.
    /// </summary>
    procedure RestrictUsersToCompany(AgentUserSecurityId: Guid; AgentCompanyName: Text[30])
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        TempCompanyAccessControl: Record "Agent Access Control" temporary;
        Changed: Boolean;
    begin
        Agent.GetAgentAccessControl(AgentUserSecurityId, TempAgentAccessControl);
        if not TempAgentAccessControl.FindSet() then
            exit;
        repeat
            Changed := Changed or (TempAgentAccessControl."Company Name" <> AgentCompanyName);
            if TempCompanyAccessControl.Get(TempAgentAccessControl."Agent User Security ID", TempAgentAccessControl."User Security ID", AgentCompanyName) then begin
                TempCompanyAccessControl."Can Configure Agent" := TempCompanyAccessControl."Can Configure Agent" or TempAgentAccessControl."Can Configure Agent";
                TempCompanyAccessControl.Modify();
            end else begin
                TempCompanyAccessControl := TempAgentAccessControl;
                TempCompanyAccessControl."Company Name" := AgentCompanyName;
                TempCompanyAccessControl.Insert();
            end;
        until TempAgentAccessControl.Next() = 0;

        if Changed then
            Agent.UpdateAgentAccessControl(AgentUserSecurityId, TempCompanyAccessControl);
    end;

    local procedure GetBaseApplicationAppId(): Guid
    var
        BaseApplicationAppId: Guid;
    begin
        Evaluate(BaseApplicationAppId, BaseApplicationAppIdTok);
        exit(BaseApplicationAppId);
    end;
}
