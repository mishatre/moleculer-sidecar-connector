
#Region Public

// Returns the sidecar configuration overrides.
//
// Parameters:
//  Config - Map - Configuration parameters to be filled in by the overridable module.
Procedure GetConfig(Config) Export
	
	If Not Moleculer.IsStandalone() Then
		Return;
	EndIf;


EndProcedure
			   
// Returns the connections to be registered by the sidecar.
// In case of using this module as internal modules (instead of extension)
// use this function to set default connection parameters.
//
// Parameters:
//  Connections - Array of MoleculerConnectionParams - Collection to be filled with connection parameters.
Procedure GetConnections(Connections) Export

	If Not Moleculer.IsStandalone() Then
		Return;
	EndIf;
			
	NewParams = Moleculer.NewConnectionParams();
	NewParams.Id      = "UUID";
	NewParams.Default = True;
	
	Connections.Add(NewParams);

	
EndProcedure

// Returns the publications to be registered by the sidecar.
//
// Parameters:
//  Publications - Array of MoleculerPublicationParams - Collection to be filled with publication parameters.
Procedure GetPublications(Publications) Export

	If Not Moleculer.IsStandalone() Then
		Return;
	EndIf;
	
	NewParams = Moleculer.NewPublicationParams();
	NewParams.Id = "UUID";
	
	Publications.Add(NewParams);
	
EndProcedure

// Returns the list of service modules to be loaded.
//
// Parameters:
//  Modules - Array of String - Collection to be filled with service module names.
Procedure GetServiceModules(Modules) Export
	
	If Not Moleculer.IsStandalone() Then
		Return;
	EndIf;

EndProcedure

// Returns the services to be registered by the sidecar.
//
// Parameters:
//  Services - Array - Collection to be filled with service definitions.
Procedure GetServices(Services) Export 
	
	If Not Moleculer.IsStandalone() Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion