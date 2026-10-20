namespace Contoso.ProjectBilling;

/// <summary>
/// Sends billing runs to the Project Billing Agent. The default implementation creates agent tasks; the tests replace
/// it with a mock so they run without an activated agent.
/// </summary>
interface "PBA ITask Dispatcher"
{
    // Internal: only this app and its test app (internalsVisibleTo) implement it, so it can grow.
    Access = Internal;

    /// <summary>
    /// Returns true when an active Project Billing Agent can take a task.
    /// </summary>
    procedure IsAvailable(): Boolean;

    /// <summary>
    /// Creates the agent task for the billing run and returns its ID. The External ID of the task is the run No.
    /// </summary>
    procedure SendBillingRun(BillingRunNo: Code[20]; TaskTitle: Text[150]; MessageText: Text): BigInteger;

    /// <summary>
    /// Stops the agent task of a billing run that is being deleted, if it can still run.
    /// </summary>
    procedure StopBillingRunTask(AgentTaskId: BigInteger);
}
