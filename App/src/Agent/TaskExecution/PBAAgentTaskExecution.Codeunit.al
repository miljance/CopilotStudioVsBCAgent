namespace Contoso.ProjectBilling;

using System.Agents;

/// <summary>
/// Runs in the agent session. The task messages come from the monthly billing job and the Run Billing Now action, not
/// from outside users, so they are not validated. The project manager reviews the draft invoices on the Billing Run
/// card and chooses Continue; there is nothing else to choose, so no suggestions are offered.
/// </summary>
codeunit 50204 "PBA Agent Task Execution" implements IAgentTaskExecution
{
    Access = Internal;

    procedure AnalyzeAgentTaskMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    begin
    end;

    procedure GetAgentTaskUserInterventionSuggestions(AgentTaskUserInterventionRequestDetails: Record "Agent User Int Request Details"; var Suggestions: Record "Agent Task User Int Suggestion")
    begin
    end;

    procedure GetAgentTaskPageContext(AgentTaskPageContextRequest: Record "Agent Task Page Context Req."; var AgentTaskPageContext: Record "Agent Task Page Context")
    begin
    end;
}
