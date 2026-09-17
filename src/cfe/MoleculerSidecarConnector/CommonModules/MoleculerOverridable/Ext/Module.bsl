
#Region Public

Procedure GetConfig(Config) Export
	
	If Moleculer.IsStandalone() Then
		//Config		
	EndIf;
	
EndProcedure
			   
// In case of using this module as internal modules (instead of extension)
// use this function to set default connection parameters
Procedure GetConnections(Connections) Export
	
	If Moleculer.IsStandalone() Then
		
		NewParams = Moleculer.NewConnectionParams();
		NewParams.Id      = "UUID";
		NewParams.Default = True;
		
		Connections.Add(NewParams);
		
	EndIf;
	
EndProcedure

Procedure GetPublications(Publications) Export
	
	If Moleculer.IsStandalone() Then
		
		NewParams = Moleculer.NewPublicationParams();
		NewParams.Id = "UUID";
		
		Publications.Add(NewParams);
	
	EndIf;
	
EndProcedure

Procedure GetServiceModules(Modules) Export
	
	If Moleculer.IsStandalone() Then
				
	EndIf;
	
	Modules.Clear();	
	Modules.Add("ServiceTsd");
	
EndProcedure

Procedure GetServices(Services) Export 
	
	If Moleculer.IsStandalone() Then
				
	EndIf;
	
EndProcedure

#EndRegion