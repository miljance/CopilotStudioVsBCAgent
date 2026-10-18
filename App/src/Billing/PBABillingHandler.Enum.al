namespace Contoso.ProjectBilling;

/// <summary>
/// Who decides the lines of a billing run: the Project Billing Agent in Business Central, or an agent outside
/// Business Central (Copilot Studio) that works through the billingRuns and billingLines APIs.
/// </summary>
enum 50204 "PBA Billing Handler"
{
    Extensible = false;

    value(0; "Project Billing Agent")
    {
        Caption = 'Project Billing Agent';
    }
    value(1; "Copilot Studio Agent")
    {
        Caption = 'Copilot Studio Agent';
    }
}
