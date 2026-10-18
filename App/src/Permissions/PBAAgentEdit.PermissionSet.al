namespace Contoso.ProjectBilling;

using Microsoft.Finance.Dimension;
using Microsoft.Integration.Entity;
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
        // Business Central keeps these API buffers in step with every sales invoice it creates (seen on BC 29: task
        // 147 stopped on 5475). Users get them from D365 BASIC; the agent has only D365 READ, so they are granted here.
        tabledata "Sales Invoice Entity Aggregate" = RIMD,
        tabledata "Sales Invoice Line Aggregate" = RIMD,
        // A sales line can get a dimension combination that does not exist yet.
        tabledata "Dimension Set Entry" = RI,
        tabledata "Dimension Set Tree Node" = RIM,
        page "PBA Billing Runs" = X,
        page "PBA Billing Run" = X,
        page "PBA Billing Lines" = X,
        page "PBA Agent Role Center" = X,
        codeunit "PBA Draft Invoices" = X;
}
