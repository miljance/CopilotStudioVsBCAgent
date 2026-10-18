namespace Contoso.ProjectBilling;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

/// <summary>
/// Creates Project Billing agents. Only one can exist: the monthly billing run sends its task to that agent.
/// </summary>
codeunit 50200 "PBA Agent Factory" implements IAgentFactory
{
    Access = Internal;

    var
        PBAAgentSetup: Codeunit "PBA Agent Setup";

    procedure GetDefaultInitials(): Text[4]
    begin
        exit(PBAAgentSetup.GetInitials());
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(PBAAgentSetup.GetSetupPageId());
    end;

    procedure ShowCanCreateAgent(): Boolean
    var
        PBAAgentSetupRecord: Record "PBA Agent Setup";
    begin
        exit(PBAAgentSetupRecord.IsEmpty());
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Project Billing Agent");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    begin
        PBAAgentSetup.GetDefaultProfile(TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlTemplate: Record "Access Control Buffer" temporary)
    begin
        PBAAgentSetup.GetDefaultAccessControls(TempAccessControlTemplate);
    end;
}
