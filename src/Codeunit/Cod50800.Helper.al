codeunit 50800 Helper
{
    //Method that calls GetPostedSalesInvoicePack with the Size and Max parameters. 
    //Max is optional, it is used to obtain a maximum of records, in case you want to bring them all, use Max = 0.
    procedure Generate()
    var
        TempBlob: Codeunit "Temp Blob";
        Confirmed, Out : Boolean;
        Istream: InStream;
        OStream: OutStream;
        SalesInvoicesPack: List of [List of [JsonObject]];
        SalesInvoicesList: List of [JsonObject];
        JsonObject: JsonObject;
        Max, Size, I, J : Integer;
        JsonArray: JsonArray;
        FileContentJson, OutText, OutputFileName : Text;
        Char10: Char;
        Char13: Char;
    begin
        Max := 0;
        Size := 25;

        //These characters represent a line break.
        Char13 := 13;
        Char10 := 10;

        SalesInvoicesPack := GetPostedSalesInvoicePack(Max, Size);

        foreach SalesInvoicesList in SalesInvoicesPack do begin
            J += 1;
            //OutText is used to create the text file to instantiate the result of the chunked list.
            OutText += '[' + format(J) + ']:' + Format(Char13) + Format(Char10);
            foreach JsonObject in SalesInvoicesList do begin
                I += 1;
                JsonArray.Add(JsonObject);
                JsonArray.WriteTo(FileContentJson);
                OutText += '[' + format(I) + ']:' + FileContentJson + Format(Char13) + Format(Char10);
            end;
            I := 0;
            Clear(JsonArray);

            //Here, the procedure in charge of sending the data should be consumed.
            //HttpManagement.WriteinAPI(FileContentJson, URLText);
        end;

        //Optional: To exemplify and be able to visualize how the lists were fragmented, the SalesInvoicesPack is stored in a Text file.
        OutputFileName := 'Output.txt';
        TempBlob.CreateOutStream(OStream, TEXTENCODING::UTF8);
        OStream.WriteText(OutText);
        TempBlob.CreateInStream(Istream);
        DownloadFromStream(Istream, 'Export', '', 'All Files (*.*)|*.*', OutputFileName);
    end;

    //Method that loops through all Posted Sales Invoices and creates the PostedSalesInvoicePack
    local procedure GetPostedSalesInvoicePack(Max: Integer; Size: Integer): List of [List of [JsonObject]]
    var
        SalesInvoices: Record "Sales Invoice Header";
        Window: Dialog;
        I: Integer;
        SalesInvoicesList: List of [JsonObject];
        SalesInvoicesPack: List of [List of [JsonObject]];
    begin

        if GuiAllowed then
            Window.OPEN('Sales Invoices No. #1###########\\');

        SalesInvoices.Reset();
        if SalesInvoices.FindSet then
            repeat

                if GuiAllowed then
                    Window.UPDATE(1, SalesInvoices."No.");

                I += 1;

                SalesInvoicesList.Add(SalesInvoicesToJson(SalesInvoices));

                if I = Max then
                    break;

            until SalesInvoices.Next() = 0;

        if GuiAllowed then
            Window.Close();

        SalesInvoicesPack := SplitList(SalesInvoicesList, Size);

        exit(SalesInvoicesPack);
    end;

    //Method that allows creating a JsonObject of each Posted Sales Invoice
    local procedure SalesInvoicesToJson(var SalesInvoices: Record "Sales Invoice Header") JsonObject: JsonObject
    begin
        Clear(JsonObject);

        SalesInvoices.CalcFields(Amount);
        SalesInvoices.CalcFields("Amount Including VAT");

        JsonObject.Add(SalesInvoices.FieldCaption("No."), SalesInvoices."No.");
        JsonObject.Add(SalesInvoices.FieldCaption("Sell-to Customer Name"), SalesInvoices."Sell-to Customer Name");
        JsonObject.Add(SalesInvoices.FieldCaption("Posting Date"), SalesInvoices."Posting Date");
        JsonObject.Add(SalesInvoices.FieldCaption(Amount), SalesInvoices.Amount);
        JsonObject.Add(SalesInvoices.FieldCaption("Amount Including VAT"), SalesInvoices."Amount Including VAT");
    end;

    //Method that allows creating a List of Lists JsonObject given a Size.
    local procedure SplitList(Input: List of [JsonObject]; Size: Integer): List of [List of [JsonObject]]
    var
        List: List of [List of [JsonObject]];
        I: Integer;
        Math: Codeunit Math;
    begin
        for I := 1 to Input.Count do begin
            List.Add(Input.GetRange(I, Math.Min(Size, Input.Count + 1 - I)));
            I += Size - 1;
        end;

        exit(List);
    end;

}
