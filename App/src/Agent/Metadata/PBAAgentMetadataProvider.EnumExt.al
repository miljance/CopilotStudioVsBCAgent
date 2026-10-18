namespace Contoso.ProjectBilling;

using System.Agents;

enumextension 50201 "PBA Agent Metadata Provider" extends "Agent Metadata Provider"
{
    value(50200; "Project Billing Agent")
    {
        Caption = 'Project Billing Agent';
        Implementation = IAgentFactory = "PBA Agent Factory", IAgentMetadata = "PBA Agent Metadata", IAgentTaskExecution = "PBA Agent Task Execution";
    }
}
