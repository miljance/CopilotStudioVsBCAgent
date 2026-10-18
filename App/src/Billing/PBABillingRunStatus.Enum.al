namespace Contoso.ProjectBilling;

enum 50200 "PBA Billing Run Status"
{
    Extensible = false;

    value(0; Proposed)
    {
        Caption = 'Proposed';
    }
    value(1; "Invoices Created")
    {
        Caption = 'Invoices Created';
    }
    value(2; "Nothing to Invoice")
    {
        Caption = 'Nothing to Invoice';
    }
}
