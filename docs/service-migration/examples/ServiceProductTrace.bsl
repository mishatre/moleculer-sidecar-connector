
Procedure Schema(Schema) Export
		
	Schema.Name    = "trade.trace";
	Schema.Version = 1;
	
	Moleculer.SchemaAddAction(Schema, "getVectorBestProductInfoByBarCode", "GetVectorBestProductInfo");
	
EndProcedure

// Actions

Function GetVectorBestProductInfo(Context) Export  
	
	If Context.RegisterSchema Then                
		RegInfo = Context.Registration;	  
		RegInfo.Description = "Get vector best product info by bar code"; 				
		RegInfo.Params.Insert("barcode", "string|trim"); 
		Return Context.ContextId;		
	EndIf; 
	
	// Code Removed
	
EndFunction   

Function ParseBarCode(BarCode) 
	
	// Code Removed
	
EndFunction  

Function FindSupplyDocuments(VendorCode, SerialNumber, ShelfLife = Undefined)
	
	// Code Removed
	
EndFunction 

Function GetSalesInfo(VendorCode, SerialNumber, ShelfLife = Undefined)
	
	// Code Removed
	
EndFunction

#Область РаботаСAPIВБНовосибирск

Функция ПолучитьДанныеСерийНакладной(НомерНакладной, ДатаНакладной) Экспорт

	// Code Removed
	
КонецФункции

Функция НайтиСохраненныеДанныеНакладной(НомерНакладной, ДатаНакладной)

	// Code Removed
	
КонецФункции

Функция СохранитьДанныеНакладной(Данные)
	
	// Code Removed
	
КонецФункции

Функция ПолучитьДанныеНакладнойСAPIСервераВБНовосибирск(НомерНакладной, ДатаВыборки, Формат = "JSON")
	
	// Code Removed
		
КонецФункции 

Function ParseInvoiceData(TextData, Format, Year)
	
	// Code Removed
	
EndFunction

#КонецОбласти

Function StrConcat(Строки, Разделитель)
	
	// Code Removed
	
EndFunction

Function StrTemplate(Val TemplateStr, Arg1 = Undefined, Arg2 = Undefined, Arg3 = Undefined, Arg4 = Undefined, Arg5 = Undefined, Arg6 = Undefined)
	// Code Removed
EndFunction

Function StrSplit(Знач Строка, Разделитель, ВключатьПустые = Истина)
	
	// Code Removed
	
EndFunction

	
