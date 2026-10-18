namespace Contoso.ProjectBilling;

using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using System.Security.AccessControl;

/// <summary>
/// For the Project Billing Agent, next to D365 READ: it records a decision on every billing line and runs Create Draft
/// Invoices on the Billing Run card, which creates sales invoices from project planning lines. It cannot post: posting
/// stays with the project manager.
/// </summary>
permissionset 50201 "PBA Agent Edit"
{
    Caption = 'Project Billing Agent - agent edits';
    Assignable = true;
    IncludedPermissionSets = "D365 SALES DOC, EDIT";

    Permissions =
        tabledata "PBA Billing Run" = RM,
        tabledata "PBA Billing Line" = RM,
        tabledata "Job Planning Line" = RM,
        tabledata "Job Planning Line Invoice" = RI,
        page "PBA Billing Runs" = X,
        page "PBA Billing Run" = X,
        page "PBA Billing Lines" = X,
        page "PBA Agent Role Center" = X,
        codeunit "PBA Draft Invoices" = X;
}
