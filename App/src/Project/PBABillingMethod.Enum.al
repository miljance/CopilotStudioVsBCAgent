namespace Contoso.ProjectBilling;

/// <summary>
/// How the monthly billing run invoices a project. Blank: the run leaves the project alone. Time and Material: the
/// usage posted as billable. Fixed Price: the planned billable lines of a milestone task once the milestone is reached.
/// </summary>
enum 50203 "PBA Billing Method"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Time and Material")
    {
        Caption = 'Time and Material';
    }
    value(2; "Fixed Price")
    {
        Caption = 'Fixed Price';
    }
}
