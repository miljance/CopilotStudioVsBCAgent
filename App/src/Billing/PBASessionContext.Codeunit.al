namespace Contoso.ProjectBilling;

using System.Agents;

/// <summary>
/// Tells whether the current session is an agent's. Tests set the answer, because they run without an agent.
/// </summary>
codeunit 50212 "PBA Session Context"
{
    SingleInstance = true;
    Access = Internal;

    var
        AgentSessionOverride: Boolean;
        HasOverride: Boolean;

    procedure IsAgentSession(): Boolean
    var
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if HasOverride then
            exit(AgentSessionOverride);
        exit(AgentSession.IsAgentSession(AgentMetadataProvider));
    end;

    procedure SetAgentSession(NewAgentSession: Boolean)
    begin
        AgentSessionOverride := NewAgentSession;
        HasOverride := true;
    end;

    procedure ResetAgentSession()
    begin
        HasOverride := false;
    end;
}
