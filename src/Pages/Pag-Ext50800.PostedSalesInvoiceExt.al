pageextension 50800 "Posted Sales Invoice Ext" extends "Posted Sales Invoices"
{
    actions
    {
        addafter("Update Document")
        {
            action(GenerateJson)
            {
                ApplicationArea = All;
                Visible = true;
                Image = ExportToExcel;
                Caption = 'Generate Json';
                trigger OnAction()
                var
                    Helper: Codeunit Helper;
                begin
                    Helper.Generate();
                end;
            }
        }
        addfirst(Category_Process)
        {
            actionref(GenerateJson_Promoted; GenerateJson)
            {
            }
        }
    }

}
