namespace Contoso.ProjectBilling;

/// <summary>
/// What Business Central found when it proposed a billing line. Only a person can invoice a line that is not OK.
/// </summary>
enum 50201 "PBA Billing Check"
{
    Extensible = false;

    value(0; OK)
    {
        Caption = 'OK';
    }
    value(1; "Milestone Not Reached")
    {
        Caption = 'Milestone Not Reached';
    }
    value(2; "Exceeds Invoice Cap")
    {
        Caption = 'Exceeds Invoice Cap';
    }
}
