namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;

/// <summary>
/// Stands in for the agent task dispatcher, so the tests run without an activated agent. Remembers what was sent.
/// </summary>
codeunit 50261 "PBA Mock Task Dispatcher" implements "PBA ITask Dispatcher"
{
    SingleInstance = true;

    var
        Available: Boolean;
        SentRunNo: Code[20];
        SentTitle: Text;
        SentMessage: Text;
        SendCount: Integer;
        StoppedTaskId: BigInteger;

    procedure Reset(NewAvailable: Boolean)
    begin
        Available := NewAvailable;
        SentRunNo := '';
        SentTitle := '';
        SentMessage := '';
        SendCount := 0;
        StoppedTaskId := 0;
    end;

    procedure IsAvailable(): Boolean
    begin
        exit(Available);
    end;

    procedure SendBillingRun(BillingRunNo: Code[20]; TaskTitle: Text[150]; MessageText: Text): BigInteger
    begin
        SendCount += 1;
        SentRunNo := BillingRunNo;
        SentTitle := TaskTitle;
        SentMessage := MessageText;
        exit(4711);
    end;

    procedure StopBillingRunTask(AgentTaskId: BigInteger)
    begin
        StoppedTaskId := AgentTaskId;
    end;

    procedure GetStoppedTaskId(): BigInteger
    begin
        exit(StoppedTaskId);
    end;

    procedure GetSendCount(): Integer
    begin
        exit(SendCount);
    end;

    procedure GetSentRunNo(): Code[20]
    begin
        exit(SentRunNo);
    end;

    procedure GetSentTitle(): Text
    begin
        exit(SentTitle);
    end;

    procedure GetSentMessage(): Text
    begin
        exit(SentMessage);
    end;
}
