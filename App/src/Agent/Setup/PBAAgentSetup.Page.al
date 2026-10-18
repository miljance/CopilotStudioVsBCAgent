namespace Contoso.ProjectBilling;

using System.Agents;
using System.AI;

page 50200 "PBA Agent Setup"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = All;
    IsPreview = true;
    Caption = 'Set up Project Billing Agent';
    InstructionalText = 'On the first day of every month the Project Billing Agent goes through what each project can invoice for the past month, creates one draft sales invoice per customer and asks the project manager to review them. It never posts an invoice.';
    AdditionalSearchTerms = 'Project Billing Agent, Agent, Invoice';
    SourceTable = "PBA Agent Setup";
    SourceTableTemporary = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(Instructions)
            {
                Caption = 'Instructions';
                Visible = not IsNewAgent;

                field(InstructionsVersion; InstructionsVersion)
                {
                    Caption = 'Instructions version';
                    ToolTip = 'Specifies the app version whose instructions were last set on the agent. New tasks use these instructions; a task keeps the instructions it was created with.';
                    Editable = false;
                }
                field(InstructionsUpdatedAt; InstructionsUpdatedAt)
                {
                    Caption = 'Instructions updated at';
                    ToolTip = 'Specifies when the instructions were last set on the agent.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                Enabled = IsUpdated;
                ToolTip = 'Apply the changes to the agent setup.';
            }

            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discards the changes and closes the setup page.';
            }
        }
    }

    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AzureOpenAI: Codeunit "Azure OpenAI";
        IsUpdated: Boolean;
        IsNewAgent: Boolean;
        InstructionsVersion: Text[30];
        InstructionsUpdatedAt: DateTime;
        CapabilityNotEnabledErr: Label 'The Project Billing Agent capability is not enabled in Copilot & agent capabilities.\\Enable the capability before you set up the agent.';

    trigger OnOpenPage()
    var
        PBAAgentKPI: Record "PBA Agent KPI";
        PBAAgentSetup: Codeunit "PBA Agent Setup";
        UserSecurityIDFilter: Text;
        UserSecurityID: Guid;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Project Billing Agent") then
            Error(CapabilityNotEnabledErr);

        UserSecurityIDFilter := Rec.GetFilter("User Security ID");
        if not Evaluate(UserSecurityID, UserSecurityIDFilter) then
            Clear(UserSecurityID);

        Rec."User Security ID" := UserSecurityID;
        IsNewAgent := IsNullGuid(UserSecurityID);
        if PBAAgentKPI.Get(UserSecurityID) then begin
            InstructionsVersion := PBAAgentKPI."Instructions Version";
            InstructionsUpdatedAt := PBAAgentKPI."Instructions Updated At";
        end;

        CurrPage.AgentSetupPart.Page.Initialize(
            UserSecurityID,
            PBAAgentSetup.GetAgentMetadataProvider(),
            PBAAgentSetup.GetAgentUserName(),
            PBAAgentSetup.GetDefaultDisplayName(),
            PBAAgentSetup.GetAgentSummary());

        InitializePage();
    end;

    trigger OnAfterGetRecord()
    begin
        InitializePage();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsUpdated := IsUpdated or CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        IsUpdated := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PBAAgentSetup: Codeunit "PBA Agent Setup";
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
        PBAAgentSetup.SaveSetupRecord(Rec, TempAgentSetupBuffer);
        exit(true);
    end;

    local procedure InitializePage()
    var
        PBAAgentSetup: Codeunit "PBA Agent Setup";
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
        PBAAgentSetup.InitializeSetupRecord(Rec);
        IsUpdated := IsUpdated or CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;
}
