namespace Contoso.ProjectBilling.Test;

using System.IO;

/// <summary>
/// Read-only list of RapidStart apply errors, so tools/Import-DemoData.ps1 can show why a demo record was not applied.
/// Lives in the test app: it is a developer aid, not part of the agent.
/// </summary>
page 50262 "PBA Config Errors API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'projectBillingDev';
    APIVersion = 'v1.0';
    EntityName = 'configPackageError';
    EntitySetName = 'configPackageErrors';
    SourceTable = "Config. Package Error";
    ODataKeyFields = SystemId;
    Editable = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(packageCode; Rec."Package Code")
                {
                    Caption = 'Package Code';
                }
                field(tableId; Rec."Table ID")
                {
                    Caption = 'Table ID';
                }
                field(recordNumber; Rec."Record No.")
                {
                    Caption = 'Record No.';
                }
                field(fieldId; Rec."Field ID")
                {
                    Caption = 'Field ID';
                }
                field(errorText; Rec."Error Text")
                {
                    Caption = 'Error Text';
                }
            }
        }
    }
}
