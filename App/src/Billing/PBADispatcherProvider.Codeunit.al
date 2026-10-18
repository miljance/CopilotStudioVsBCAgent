namespace Contoso.ProjectBilling;

/// <summary>
/// Hands out the dispatcher the billing runs use. Tests call SetDispatcher with a mock.
/// </summary>
codeunit 50210 "PBA Dispatcher Provider"
{
    SingleInstance = true;
    Access = Internal;

    var
        OverrideDispatcher: Interface "PBA ITask Dispatcher";
        HasOverride: Boolean;

    procedure GetDispatcher(): Interface "PBA ITask Dispatcher"
    var
        AgentTaskDispatcher: Codeunit "PBA Agent Task Dispatcher";
        Dispatcher: Interface "PBA ITask Dispatcher";
    begin
        if HasOverride then
            exit(OverrideDispatcher);

        Dispatcher := AgentTaskDispatcher;
        exit(Dispatcher);
    end;

    procedure SetDispatcher(NewDispatcher: Interface "PBA ITask Dispatcher")
    begin
        OverrideDispatcher := NewDispatcher;
        HasOverride := true;
    end;

    procedure ResetDispatcher()
    begin
        HasOverride := false;
    end;
}
