
Procedure Schema(Schema) Export
		
	Schema.Name    = "trade.companies";
	Schema.Version = 1;
	
	Moleculer.SchemaAddAction(Schema, "getInfo", "GetCompanyInfo");
	Moleculer.SchemaAddAction(Schema, "bulkGetInfo", "BulkGetCompanyInfo");
		
EndProcedure

// Actions

Function GetCompanyInfo(Context) Export  
	
	If Context.RegisterSchema Then                
		RegInfo = Context.Registration;	  
		RegInfo.Description = "Get company info"; 				
		RegInfo.Params.Insert("uuid", "string|optional|trim");  
		RegInfo.Params.Insert("description", "string|optional|trim");
		RegInfo.Params.Insert("INN", "string|optional|trim");
		RegInfo.Params.Insert("KPP", "string|optional|trim"); 
		Return Context.ContextId;		
	EndIf;   
	
	// Code Removed
	
EndFunction     

Function BulkGetCompanyInfo(Context) Export  
	
	If Context.RegisterSchema Then                
		RegInfo = Context.Registration;	  
		RegInfo.Description = "Get company info";
		Items = New Structure();
		Items.Insert("uuid", "string|optional|trim");
		RegInfo.Params.Insert("items", New Structure(
			"type,items",
			"array",
			New Structure(
				"type,params",
				"object",
				Items,
			)	
		));   
		Return Context.ContextId;		
	EndIf;   
	
	// Code Removed
	
EndFunction     

Function StrConcat(Строки, Разделитель)
	
	// Code Removed
	
EndFunction


	
