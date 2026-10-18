namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using System.TestLibraries.Utilities;

codeunit 50254 "PBA Agent Per Company Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure AgentOfAnotherCompanyDoesNotBlockANewOne()
    var
        PBAAgentSetup: Record "PBA Agent Setup";
        PBAAgentFactory: Codeunit "PBA Agent Factory";
    begin
        // [GIVEN] The only Project Billing agent works in another company
        PBAAgentSetup.DeleteAll();
        PBAAgentSetup."User Security ID" := CreateGuid();
        PBAAgentSetup."Company Name" := 'PBA OTHER COMPANY';
        PBAAgentSetup.Insert();

        // [WHEN] Asked whether this company can create an agent
        // [THEN] It can: every company has its own agent
        Assert.IsTrue(PBAAgentFactory.ShowCanCreateAgent(), 'An agent of another company must not block this company.');
    end;

    [Test]
    procedure SecondAgentInTheSameCompanyIsNotOffered()
    var
        PBAAgentSetup: Record "PBA Agent Setup";
        PBAAgentFactory: Codeunit "PBA Agent Factory";
    begin
        // [GIVEN] This company has a Project Billing agent
        PBAAgentSetup.DeleteAll();
        PBAAgentSetup."User Security ID" := CreateGuid();
        PBAAgentSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(PBAAgentSetup."Company Name"));
        PBAAgentSetup.Insert();

        // [WHEN] Asked whether this company can create an agent
        // [THEN] It cannot: its monthly billing run already has an agent
        Assert.IsFalse(PBAAgentFactory.ShowCanCreateAgent(), 'One agent per company.');
    end;
}
