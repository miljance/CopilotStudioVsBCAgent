namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;

/// <summary>
/// Home page of the Project Billing Agent (profile "Project Billing Agent"). An agent cannot search for pages, so the
/// menu lists every page the instructions use: the billing runs, the projects with their billing notes, and the draft
/// sales invoices.
/// </summary>
page 50202 "PBA Agent Role Center"
{
    PageType = RoleCenter;
    Caption = 'Project Billing Agent';
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
        }
    }

    actions
    {
        area(Embedding)
        {
            ToolTip = 'Prepare the monthly project invoices and ask the project manager to review them.';

            action(BillingRuns)
            {
                ApplicationArea = Jobs;
                Caption = 'Billing Runs';
                Image = Invoice;
                RunObject = Page "PBA Billing Runs";
                ToolTip = 'Open the billing runs: what each project can invoice for the period, your decisions and the draft invoices.';
            }
            action(Projects)
            {
                ApplicationArea = Jobs;
                Caption = 'Projects';
                Image = Job;
                RunObject = Page "Job List";
                ToolTip = 'Open the projects to read their billing method, invoice cap and billing notes.';
            }
            action(SalesInvoices)
            {
                ApplicationArea = Jobs;
                Caption = 'Sales Invoices';
                Image = SalesInvoice;
                RunObject = Page "Sales Invoice List";
                ToolTip = 'Open the draft sales invoices.';
            }
        }
    }
}
