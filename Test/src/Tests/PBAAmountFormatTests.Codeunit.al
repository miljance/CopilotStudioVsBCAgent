namespace Contoso.ProjectBilling.Test;

using Contoso.ProjectBilling;
using System.TestLibraries.Utilities;

codeunit 50255 "PBA Amount Format Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure AmountsLookTheSameInEverySession()
    var
        PBAAmountFormat: Codeunit "PBA Amount Format";
    begin
        // [GIVEN] Amounts as they appear in check notes and summaries
        // [WHEN] They are formatted
        // [THEN] Always with a comma for thousands and a point for decimals, whatever the language of the session
        //        (the agent's session showed 11.500,00 where the user's showed 11,500.00)
        Assert.AreEqual('11,500.00', PBAAmountFormat.FormatAmount(11500), '11500');
        Assert.AreEqual('1,234,567.50', PBAAmountFormat.FormatAmount(1234567.5), '1234567.5');
        Assert.AreEqual('640.00', PBAAmountFormat.FormatAmount(640), '640');
        Assert.AreEqual('0.00', PBAAmountFormat.FormatAmount(0), '0');
        Assert.AreEqual('-1,400.25', PBAAmountFormat.FormatAmount(-1400.25), '-1400.25');
        Assert.AreEqual('12.35', PBAAmountFormat.FormatAmount(12.345), 'rounded to cents');
    end;
}
