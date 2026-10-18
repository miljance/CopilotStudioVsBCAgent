namespace Contoso.ProjectBilling;

enum 50202 "PBA Billing Decision"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Invoice)
    {
        Caption = 'Invoice';
    }
    value(2; Hold)
    {
        Caption = 'Hold';
    }
}
