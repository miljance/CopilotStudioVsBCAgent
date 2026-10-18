namespace Contoso.ProjectBilling;

using System.Agents;

codeunit 50202 "PBA Agent Metadata" implements IAgentMetadata
{
    Access = Internal;

    var
        PBAAgentSetup: Codeunit "PBA Agent Setup";

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit(PBAAgentSetup.GetInitials());
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(PBAAgentSetup.GetSetupPageId());
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(PBAAgentSetup.GetSummaryPageId());
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid): Integer
    begin
        exit(Page::"Agent Task Message Card");
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    begin
        Clear(Annotations);
    end;
}
