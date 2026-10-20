namespace Contoso.ProjectBilling;

using System.Agents;

/// <summary>
/// Creates Project Billing Agent tasks with the Tasks AL API: one task per billing run, External ID = run No.
/// </summary>
codeunit 50209 "PBA Agent Task Dispatcher" implements "PBA ITask Dispatcher"
{
    Access = Internal;

    var
        PBAAgentSetup: Codeunit "PBA Agent Setup";
        NoActiveAgentErr: Label 'No active Project Billing Agent was found. Set up and activate the Project Billing Agent first.';

    procedure IsAvailable(): Boolean
    var
        AgentUserSecurityId: Guid;
    begin
        exit(PBAAgentSetup.TryGetActiveAgent(AgentUserSecurityId));
    end;

    procedure SendBillingRun(BillingRunNo: Code[20]; TaskTitle: Text[150]; MessageText: Text): BigInteger
    var
        AgentTaskRecord: Record "Agent Task";
        PBAAgentKPI: Record "PBA Agent KPI";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserSecurityId: Guid;
    begin
        if not PBAAgentSetup.TryGetActiveAgent(AgentUserSecurityId) then
            Error(NoActiveAgentErr);

        // The message comes from Business Central (monthly job or Run Billing Now), not from an outside user, so it
        // needs no approval before the agent starts.
        AgentTaskMessageBuilder
            .Initialize(CopyStr(UserId(), 1, 250), MessageText)
            .SetRequiresReview(false);
        AgentTaskRecord := AgentTaskBuilder
            .Initialize(AgentUserSecurityId, TaskTitle)
            .SetExternalId(BillingRunNo)
            .AddTaskMessage(AgentTaskMessageBuilder)
            .Create();

        PBAAgentKPI.AddBillingRunSent(AgentUserSecurityId);
        exit(AgentTaskRecord.ID);
    end;

    procedure StopBillingRunTask(AgentTaskId: BigInteger)
    var
        AgentTaskRecord: Record "Agent Task";
        AgentTask: Codeunit "Agent Task";
    begin
        if AgentTaskId = 0 then
            exit;
        if not AgentTaskRecord.Get(AgentTaskId) then
            exit;
        if AgentTaskRecord.Status in [AgentTaskRecord.Status::Completed, AgentTaskRecord.Status::"Stopped by User",
                                      AgentTaskRecord.Status::"Stopped by System", AgentTaskRecord.Status::Stopping] then
            exit;
        AgentTask.StopTask(AgentTaskId, false);
    end;
}
