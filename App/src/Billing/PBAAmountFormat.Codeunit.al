namespace Contoso.ProjectBilling;

/// <summary>
/// Amounts in check notes and summaries, the same in every session: comma for thousands, point for decimals
/// (11,500.00). Format with the standard format follows the session's language, and the agent's session wrote 11.500,00
/// into a note where the user's wrote 11,500.00.
/// </summary>
codeunit 50213 "PBA Amount Format"
{
    Access = Internal;

    procedure FormatAmount(Amount: Decimal): Text
    var
        Rounded: Decimal;
        IntegerPart: Decimal;
        Cents: Integer;
        Digits: Text;
        Grouped: Text;
        Position: Integer;
        Sign: Text;
    begin
        Rounded := Round(Abs(Amount), 0.01);
        if Amount < 0 then
            Sign := '-';
        IntegerPart := Round(Rounded, 1, '<');
        Cents := Round((Rounded - IntegerPart) * 100, 1);
        Digits := Format(IntegerPart, 0, 9);
        for Position := 1 to StrLen(Digits) do begin
            if (Position > 1) and ((StrLen(Digits) - Position + 1) mod 3 = 0) then
                Grouped += ',';
            Grouped += CopyStr(Digits, Position, 1);
        end;
        exit(Sign + Grouped + '.' + PadStr('', 2 - StrLen(Format(Cents, 0, 9)), '0') + Format(Cents, 0, 9));
    end;
}
