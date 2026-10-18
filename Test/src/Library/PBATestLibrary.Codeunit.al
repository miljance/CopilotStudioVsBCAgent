namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;

/// <summary>
/// Test data on top of the company's own setup (CRONUS sample data): projects, tasks and billable planning lines.
/// Initialize takes every existing project out of the billing runs, so a test sees only its own projects; the test
/// runner rolls everything back after each test codeunit.
/// </summary>
codeunit 50260 "PBA Test Library"
{
    var
        PBAMockTaskDispatcher: Codeunit "PBA Mock Task Dispatcher";
        PBADispatcherProvider: Codeunit "PBA Dispatcher Provider";
        PBASessionContext: Codeunit "PBA Session Context";
        ProjectCounter: Integer;

    procedure Initialize()
    var
        Job: Record Job;
        PBABillingRun: Record "PBA Billing Run";
    begin
        Job.ModifyAll("PBA Billing Method", Job."PBA Billing Method"::" ");
        PBABillingRun.DeleteAll(true);
        PBAMockTaskDispatcher.Reset(true);
        PBADispatcherProvider.SetDispatcher(PBAMockTaskDispatcher);
        PBASessionContext.SetAgentSession(false);
    end;

    procedure SetAgentSession(IsAgent: Boolean)
    begin
        PBASessionContext.SetAgentSession(IsAgent);
    end;

    procedure GetCustomer(Index: Integer): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.SetFilter("Customer Posting Group", '<>%1', '');
        Customer.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        Customer.SetRange("Currency Code", '');
        Customer.FindSet();
        if Index > 1 then
            Customer.Next(Index - 1);
        exit(Customer."No.");
    end;

    procedure GetResource(): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        Resource.SetFilter("Base Unit of Measure", '<>%1', '');
        Resource.SetRange(Blocked, false);
        Resource.FindFirst();
        exit(Resource."No.");
    end;

    procedure CreateProject(var Job: Record Job; CustomerNo: Code[20]; BillingMethod: Enum "PBA Billing Method")
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        ProjectCounter += 1;
        JobPostingGroup.FindFirst();
        Job.Init();
        Job."No." := CopyStr('PBATEST' + Format(ProjectCounter) + Format(Random(9999)), 1, MaxStrLen(Job."No."));
        Job.Insert(true);
        Job.Validate(Description, 'Billing test project');
        Job.Validate("Sell-to Customer No.", CustomerNo);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Validate(Status, Job.Status::Open);
        Job."PBA Billing Method" := BillingMethod;
        Job.Modify(true);
    end;

    procedure CreateTask(Job: Record Job; TaskNo: Code[20]; var JobTask: Record "Job Task")
    begin
        JobTask.Init();
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := TaskNo;
        JobTask.Insert(true);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.Validate(Description, 'Task ' + TaskNo);
        JobTask.Validate("Job Posting Group", Job."Job Posting Group");
        JobTask.Modify(true);
    end;

    /// <summary>
    /// A billable line as posting usage creates it (System-Created Entry).
    /// </summary>
    procedure CreateUsageLine(JobTask: Record "Job Task"; PlanningDate: Date; Description: Text[100]; Qty: Decimal; UnitPrice: Decimal; var JobPlanningLine: Record "Job Planning Line")
    begin
        CreatePlanningLine(JobTask, PlanningDate, Description, Qty, UnitPrice, JobPlanningLine."Line Type"::Billable, true, JobPlanningLine);
    end;

    /// <summary>
    /// A planned billable line, as a fixed price milestone is entered.
    /// </summary>
    procedure CreateMilestoneLine(JobTask: Record "Job Task"; PlanningDate: Date; Description: Text[100]; Amount: Decimal; var JobPlanningLine: Record "Job Planning Line")
    begin
        CreatePlanningLine(JobTask, PlanningDate, Description, 1, Amount, JobPlanningLine."Line Type"::Billable, false, JobPlanningLine);
    end;

    procedure CreatePlanningLine(JobTask: Record "Job Task"; PlanningDate: Date; Description: Text[100]; Qty: Decimal; UnitPrice: Decimal; LineType: Enum "Job Planning Line Line Type"; SystemCreated: Boolean; var JobPlanningLine: Record "Job Planning Line")
    var
        LastJobPlanningLine: Record "Job Planning Line";
        LineNo: Integer;
    begin
        LastJobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        LastJobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        if LastJobPlanningLine.FindLast() then
            LineNo := LastJobPlanningLine."Line No.";
        LineNo += 10000;

        JobPlanningLine.Init();
        JobPlanningLine."Job No." := JobTask."Job No.";
        JobPlanningLine."Job Task No." := JobTask."Job Task No.";
        JobPlanningLine."Line No." := LineNo;
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Validate("Line Type", LineType);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate("No.", GetResource());
        JobPlanningLine.Validate(Description, Description);
        JobPlanningLine.Validate(Quantity, Qty);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine."System-Created Entry" := SystemCreated;
        JobPlanningLine.Modify(true);
    end;

    procedure SetMilestoneReached(var JobTask: Record "Job Task"; ReachedDate: Date)
    begin
        JobTask.Validate("PBA Milestone Reached", true);
        JobTask.Validate("PBA Milestone Reached Date", ReachedDate);
        JobTask.Modify(true);
    end;

    procedure CreateRun(DateInPeriod: Date; var PBABillingRun: Record "PBA Billing Run")
    var
        PBABillingRunMgt: Codeunit "PBA Billing Run Mgt.";
    begin
        PBABillingRunMgt.CreateRun(DateInPeriod, Enum::"PBA Billing Handler"::"Copilot Studio Agent", PBABillingRun);
    end;

    procedure FindLine(PBABillingRun: Record "PBA Billing Run"; JobPlanningLine: Record "Job Planning Line"; var PBABillingLine: Record "PBA Billing Line"): Boolean
    begin
        PBABillingLine.SetRange("Billing Run No.", PBABillingRun."No.");
        PBABillingLine.SetRange("Job No.", JobPlanningLine."Job No.");
        PBABillingLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        PBABillingLine.SetRange("Planning Line No.", JobPlanningLine."Line No.");
        exit(PBABillingLine.FindFirst());
    end;

    procedure Decide(PBABillingRun: Record "PBA Billing Run"; JobPlanningLine: Record "Job Planning Line"; Decision: Enum "PBA Billing Decision")
    var
        PBABillingLine: Record "PBA Billing Line";
    begin
        FindLine(PBABillingRun, JobPlanningLine, PBABillingLine);
        PBABillingLine.Validate(Decision, Decision);
        PBABillingLine.Modify(true);
    end;

    procedure GetMockDispatcher(var MockTaskDispatcher: Codeunit "PBA Mock Task Dispatcher")
    begin
        MockTaskDispatcher := PBAMockTaskDispatcher;
    end;
}
