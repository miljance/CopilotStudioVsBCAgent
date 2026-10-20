namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using System.Agents;
using System.Security.AccessControl;

/// <summary>
/// Read-only view of the Project Billing agents: the company in the setup record, who may use the agent in which
/// company, and in which companies the agent has permissions. Developer aid for the one-agent-per-company setup.
/// </summary>
page 50263 "PBA Agent Diagnostics API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'projectBillingDev';
    APIVersion = 'v1.0';
    EntityName = 'agentDiagnostic';
    EntitySetName = 'agentDiagnostics';
    SourceTable = "PBA Agent Setup";
    ODataKeyFields = "User Security ID";
    Editable = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(userSecurityId; Rec."User Security ID")
                {
                    Caption = 'User Security ID';
                }
                field(companyName; Rec."Company Name")
                {
                    Caption = 'Company Name';
                }
                field(userAccess; UserAccess)
                {
                    Caption = 'User Access';
                }
                field(permissions; Permissions)
                {
                    Caption = 'Permissions';
                }
            }
        }
    }

    var
        UserAccess: Text;
        Permissions: Text;

    trigger OnAfterGetRecord()
    var
        AgentAccessControl: Record "Agent Access Control";
        AccessControl: Record "Access Control";
        UserAccessTok: Label '%1 [%2] configure=%3; ', Locked = true;
        PermissionTok: Label '%1 [%2]; ', Locked = true;
    begin
        UserAccess := '';
        AgentAccessControl.SetRange("Agent User Security ID", Rec."User Security ID");
        if AgentAccessControl.FindSet() then
            repeat
                UserAccess += StrSubstNo(UserAccessTok, AgentAccessControl."User Security ID", AgentAccessControl."Company Name", AgentAccessControl."Can Configure Agent");
            until AgentAccessControl.Next() = 0;

        Permissions := '';
        AccessControl.SetRange("User Security ID", Rec."User Security ID");
        if AccessControl.FindSet() then
            repeat
                Permissions += StrSubstNo(PermissionTok, AccessControl."Role ID", AccessControl."Company Name");
            until AccessControl.Next() = 0;
    end;
}
