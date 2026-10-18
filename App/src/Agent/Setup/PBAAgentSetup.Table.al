namespace Contoso.ProjectBilling;

/// <summary>
/// One record per Project Billing agent. Links the agent user created by the platform to this app and to the company it
/// works in: every company can have its own agent, with its own monthly billing job.
/// </summary>
table 50200 "PBA Agent Setup"
{
    Access = Internal;
    Caption = 'Project Billing Agent Setup';
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    DataPerCompany = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the unique identifier of the agent user.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            ToolTip = 'Specifies the company the agent works in.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
        key(Company; "Company Name")
        {
        }
    }
}
