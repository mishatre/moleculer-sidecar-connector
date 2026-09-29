
Procedure Schema(Schema) Export

	Schema.Name = "tradeElact";
	Schema.Version = 1;      
	                             							  
	Moleculer.SchemaAddAction(Schema, "contract.getErrorInfo", "ContractGetErrorInfo");
	Moleculer.SchemaAddAction(Schema, "contract.getStages"   , "ContractGetStages");
	Moleculer.SchemaAddAction(Schema, "document.editStage"   , "DocumentEditStage");
	
	Moleculer.SchemaAddEvent(Schema, "elact.contract.new"    , "OnNewContract");
	Moleculer.SchemaAddEvent(Schema, "elact.contract.update" , "OnUpdateContract");
	
EndProcedure

// Actions
Function ContractGetErrorInfo(Context) Export  
	
	If Context.RegisterSchema Then                
		RegInfo = Context.Registration;	  
		RegInfo.Description = "Get detalised error description"; 				
		RegInfo.Params.Insert("documentUUID", "string|no-empty|trim");
		Return Context.ContextId;		
	EndIf;   
	
	// Code Removed
	
EndFunction

Function ContractGetStages(Context) Export
	
	If Context.RegisterSchema Then                
		RegInfo = Context.Registration;	  
		RegInfo.Description = "Contract get stages"; 				
		RegInfo.Params.Insert("documentUUID", "string|no-empty|trim");
		Return Context.ContextId;		
	EndIf;             
	
	// Code Removed
	
EndFunction


Function DocumentEditStage(Context) Export
	
	If Context.RegisterSchema Then                
		RegInfo = Context.Registration;	  
		RegInfo.Description = "Edit document contract stage"; 				
		RegInfo.Params.Insert("documentUUID", "string|no-empty|trim");
		RegInfo.Params.Insert("stageUUID"   , "string|no-empty|trim");
		Return Context.ContextId;		
	EndIf;
	
	// Code Removed
	
EndFunction

// Events 

Function OnNewContract(Context) Export
				
	// Code Removed
		
EndFunction 

Function OnUpdateContract(Context) Export 
	
	// Code Removed
	
EndFunction

Функция НовыйПараметрыКонтракта(Параметры)
	
	// Code Removed
	
КонецФункции  

Процедура ПриИзмененииКонтракта(ПараметрыКонтракта)
	
	// Code Removed
		
КонецПроцедуры

