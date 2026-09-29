
#Region Public

#Region Requests 

// Call an action 
//
// Parameters:
//  ActionName - String                                - name of action
//  Params     - Array, Structure, Map, Any, Undefined - params of action
//  Opts       - Object, Undefined                     - options of call  
//
// Returns:
//  Any - service action response
//
Function Call(ActionName, Val Params = Undefined, Opts = Undefined) Export
	If mol_Helpers.IsObject(Opts) And mol_Helpers.Has(Opts, "Connection") Then
		Message = NStr("
		|	ru = 'Opts.Connection не должен использоваться при вызове метода через общий модуль Moleculer!
		|Используйте mol_Broker вместо него';
		|	en = 'Opts.Connection should't be used when executing call from Moleculer common module!
		|Use mol_Broker instead';");
		mol_Errors.RaiseCustomError("Error", Message);
	EndIf;
	Return mol_Broker.Call(ActionName, Params, Opts);
EndFunction 

// Emit an event (grouped & balanced global event)
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Procedure Emit(EventName, Data = Undefined, Val Opts = Undefined) Export
	If mol_Helpers.IsObject(Opts) And mol_Helpers.Has(Opts, "Connection") Then
		Message = NStr("
		|	ru = 'Opts.Connection не должен использоваться при вызове метода через общий модуль Moleculer!
		|Используйте mol_Broker вместо него';
		|	en = 'Opts.Connection should't be used when executing call from Moleculer module!
		|Use mol_Broker instead';");
		mol_Errors.RaiseCustomError("Error", Message);
	EndIf;
    mol_Broker.Emit(EventName, Data, Opts);	
EndProcedure 

// Broadcast an event for all local & remote services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
//
Procedure Broadcast(EventName, Data = Undefined, Val Opts = Undefined) Export
	If mol_Helpers.IsObject(Opts) And mol_Helpers.Has(Opts, "Connection") Then
		Message = NStr("
		|	ru = 'Opts.Connection не должен использоваться при вызове метода через общий модуль Moleculer!
		|Используйте mol_Broker вместо него';
		|	en = 'Opts.Connection should't be used when executing call from Moleculer module!
		|Use mol_Broker instead';");
		mol_Errors.RaiseCustomError("Error", Message);
	EndIf; 
	mol_Broker.Broadcast(EventName, Data, Opts);	
EndProcedure

#EndRegion

#Region Utils

Function Namespace() Export
	Return GetConfig().Namespace;
EndFunction

Function GetCurrentContext() Export
	Return mol_ContextFactory.GetCurrentContext();
EndFunction

#Region Errors

Function GetCurrentError() Export
	Return mol_Errors.GetCurrentError();
EndFunction

Procedure RaiseError(Error) Export
	mol_Errors.RaiseError(Error);
EndProcedure

Procedure RaiseCustomError(Type, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	mol_Errors.RaiseCustomError(Type, Message, Data, ErrorInfo);	
EndProcedure

#EndRegion

Function Broker() Export
	Return mol_Broker;
EndFunction

#EndRegion

#EndRegion

#Region Protected

#Region Constructors 

Function NewConfigParams() Export 

	Result = New Structure(); 
	Result.Insert("UUID");
	Result.Insert("NodeID");
	Result.Insert("Name");
	Result.Insert("Caption");
	
	Result.Insert("Namespace");
	Result.Insert("ModulePrefix");
	
	Result.Insert("LogLevel");
	
	Result.Insert("ExtVersion");
	Result.Insert("ExtAdminRole");  
	
	LaunchParameters = New Structure();  
	LaunchParameters.Insert("Enable");
	LaunchParameters.Insert("SkipRolesCheck");
	
	Result.Insert("LaunchParameters", LaunchParameters);
		
	Return Result;
	
EndFunction

Function NewConnectionParams() Export

	Result = New Structure();
	Result.Insert("Id");
	Result.Insert("Description");
	Result.Insert("Default");
	Result.Insert("Type");
	Result.Insert("Endpoint");
	Result.Insert("Port");
	Result.Insert("UseSSL");
	Result.Insert("AccessKey");
	Result.Insert("SecretKey");
	Result.Insert("Timeout");
	Result.Insert("Proxy");
	
	Return Result;
	
EndFunction

Function NewPublicationParams() Export

	Result = New Structure(); 
	Result.Insert("id"); 
	Result.Insert("description");
	Result.Insert("endpoint");
	Result.Insert("port");
	Result.Insert("useSSL");
	Result.Insert("path");
	// NewPublicationAuthParams()
	Result.Insert("auth");
	
	Result.Insert("connection");
	
	Return Result;
	
EndFunction

Function NewPublicationAuthParams(Type) Export
	
	Result = New Structure();  
	
	If Type = AuthTypes().UsingAccessToken Then	
		Result.Insert("token");
	ElsIf Type = AuthTypes().UsingPassword Then	
		Result.Insert("username");
		Result.Insert("password");
	ElsIf Type = AuthTypes().NoAuth Then
		Result = Undefined;
	Else 
		Raise "Unknown auth type";
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Enums

Function AuthTypes() Export

	Result = New Structure();
	Result.Insert("UsingAccessToken");
	Result.Insert("UsingPassword");
	Result.Insert("NoAuth"); 
	
	If Not IsStandalone() Then
		Result.UsingAccessToken = PredefinedValue("Enum.mol_AuthorizationType.UsingAccessToken");
		Result.UsingPassword    = PredefinedValue("Enum.mol_AuthorizationType.UsingPassword");
		Result.NoAuth           = PredefinedValue("Enum.mol_AuthorizationType.NoAuth");
	Else
		Result.UsingAccessToken = "UsingAccessToken";
		Result.UsingPassword    = "UsingPassword";
		Result.NoAuth           = "NoAuth";	
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

Function IsStandalone() Export

	Return Metadata.FindByFullName("Catalog.mol_Services") = Undefined;		
	
EndFunction

Function GetConfig(ForceUpdate = False) Export

	If ForceUpdate = False Then
		Return mol_Reuse.GetConfig();
	EndIf;
	
	Result = NewConfigParams();    
	Result.UUID         = "387932e5-0305-4849-b099-d51868d31ef4";
	Result.NodeID       = "387932e5-0305-4849-b099-d51868d31ef4";
	Result.Name         = "MoleculerSidecarConnector";
	Result.Caption      = "Moleculer sidecar connector";
	
	Result.ModulePrefix = "Service";
	Result.LogLevel     = mol_Logger.LogLevels().Info;                           
	
	Result.LaunchParameters.Enable         = StrTemplate("%1_Enable"        , Result.Name);
	Result.LaunchParameters.SkipRolesCheck = StrTemplate("%1_SkipRolesCheck", Result.Name);
	
	If Not IsStandalone() Then    
		SetPrivilegedMode(True);
		Result.Namespace    = Constants["mol_Namespace"].Get();
		Result.LogLevel     = Constants["mol_LogLevel"].Get();
		Result.ExtAdminRole = "mol_Administrator";
		Result.ExtVersion   = mol_Helpers.GetExtensionVersion(Result.Name);
		SetPrivilegedMode(False);
	EndIf;
	
	MoleculerOverridable.GetConfig(Result);
	
	Return Result;
	
EndFunction

Function GetConnections(ForceUpdate = False) Export
	
	If Not ForceUpdate Then
		Return mol_Reuse.GetConnections();
	EndIf;
	
	Result = New Array(); 
	
	If Not IsStandalone() Then
		Query = New Query(
		"SELECT
		|	UUID(Elements.Ref)   AS Id,   
		|	Elements.Description AS Description,
		|	Elements.Predefined  AS Default,
		|	""HTTP""             AS Type,
		|	Elements.Endpoint    AS Endpoint,
		|	Elements.Port        AS Port,
		|	Elements.UseSSL      AS UseSSL,
		|	Elements.AccessKey   AS AccessKey,
		|	Elements.SecretKey   AS SecretKey,
		|	Elements.Timeout     AS Timeout
		|FROM
		|	Catalog.mol_Connections AS Elements
		|WHERE
		|	Elements.Enabled = True");				
		Selection = Query.Execute().Select();
		While Selection.Next() Do	
			NewConnection = NewConnectionParams();
			FillPropertyValues(NewConnection, Selection);
			Result.Add(NewConnection);
		EndDo;
	EndIf; 
	
	MoleculerOverridable.GetConnections(Result);
	
	Return Result;
		
EndFunction

Function GetPublications(ForceUpdate = False) Export
	
	If Not ForceUpdate Then
		Return mol_Reuse.GetPublications();		
	EndIf;     
	
	Config = GetConfig(ForceUpdate);
	
	Result = New Array();
	
	If Not IsStandalone() Then
		Query = New Query(
		"SELECT
		|	UUID(Elements.Ref)   AS UUID,  
		|	Elements.Description AS Description,
		|	Elements.Endpoint    AS Endpoint,
		|	Elements.Port        AS Port,
		|	Elements.UseSSL      AS UseSSL,
		|	Elements.Path        AS Path,
		|	Elements.AuthType    AS AuthType,
		|	Elements.User        AS UserUUID,
		|	Elements.Password    AS Password,
		|	Elements.Connection  AS Connection
		|FROM
		|	Catalog.mol_Publications AS Elements
		|WHERE
		|	Elements.Enabled = True");
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			NewParams = NewPublicationParams();		
			NewParams.Id          = String(Selection.UUID);
			NewParams.Description = Selection.Description;
			NewParams.Endpoint    = Selection.Endpoint;
			NewParams.Port        = Selection.Port;
			NewParams.UseSSL      = Selection.UseSSL;
			NewParams.Path        = Selection.Path;
			
			NewParams.Auth = NewPublicationAuthParams(Selection.AuthType);
			User = InfoBaseUsers.FindByUUID(Selection.UserUUID);
			If Selection.AuthType = AuthTypes().UsingAccessToken Then			
				NewParams.Auth.Token = mol_Helpers.GenereteAccessToken(
					Selection.Password, 
					User.Name, 
					Config.Name
				);
			ElsIf Selection.AuthType = AuthTypes().UsingPassword Then		
				NewParams.Auth.Username = User.Name;
				NewParams.Auth.Password = Selection.Password;
			Else
				Message = NStr("
				|	ru = 'Неизвестный тип авторизации';
				|	en = 'Unknown auth type';");
				mol_Errors.RaiseCustomError("Error", Message);
			EndIf;
			
			If ValueIsFilled(Selection.Connection) Then
				NewParams.Connection = AdaptConnectionParams(Selection.Connection); 
			EndIf;
			
			Result.Add(NewParams);
			
		EndDo; 
	EndIf;   
	
	MoleculerOverridable.GetPublications(Result);
		
	Return Result;
	
EndFunction

Function GetServiceModules(ForceUpdate = False, ModulePrefix) Export

	If ForceUpdate = False Then
		Return mol_Reuse.GetServiceModules(ModulePrefix);
	EndIf;
	
	Result = New Array();
	
	For Each Module In Metadata.CommonModules Do
		If Not StrStartsWith(Module.Name, ModulePrefix) Then
			Continue;
		EndIf;
		If Not Module.Server Then			
			Message = NStr("
			|	ru = 'У модуля сервиса ""%1"" не включена директива выполнения - ""Сервер"" и поэтому этот модуль был пропущен';
			|	en = 'Service module ""%1"" does not have ""Server"" flag and was skipped';");
			mol_Logger.Warn("GetServiceModules", StrTemplate(Message, Module.Name), Undefined, ThisMetadata());
			Continue;
		EndIf;
		Result.Add(Module.Name);		
	EndDo;  
	
	If Not Moleculer.IsStandalone() Then
		Query = New Query(
		"SELECT
		|	Services.Ref AS Ref
		|FROM
		|	Catalog.mol_Services AS Services
		|WHERE
		|	Services.Enabled = True");
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Result.Add(Selection.Ref);	
		EndDo;
	EndIf;

	MoleculerOverridable.GetServiceModules(Result);
	
	Return Result;

EndFunction
	
Function GetServices(ForceUpdate = False) Export

	If ForceUpdate = False Then
		Return mol_Reuse.GetServices();
	EndIf;
	
	Result = New Array();
	
	Config = GetConfig(ForceUpdate);
	
	ServiceModuleNames = GetServiceModules(ForceUpdate, Config.ModulePrefix);
	For Each ModuleOrReference In ServiceModuleNames Do
		Schema = mol_SchemaFactory.CompileServiceSchema(ModuleOrReference, Config.Namespace);
		If Schema = Undefined Then
			Continue;
		EndIf;
		     	
		ServiceInfo = NewServiceInfo();
		FillPropertyValues(ServiceInfo, Schema);
		ServiceInfo.Module      = ModuleOrReference;
		ServiceInfo.Settings    = GetPublicSettings(Schema.Settings);
		ServiceInfo.Description = Schema.Metadata.Get("$description");
		
		NoServiceNamePrefix = Schema.Settings.Get("$noServiceNamePrefix") = True;
		
		For Each KeyValue In mol_Helpers.Get(Schema, "Actions", New Map()) Do
			Name   = KeyValue.Key;
			Action = KeyValue.Value;
			If Not NoServiceNamePrefix Then
				Name = ServiceInfo.FullName + "." + Action.Name;
			EndIf;                                   
			ServiceInfo.Actions.Insert(Name, Action);	
		EndDo;
		
		For Each KeyValue In mol_Helpers.Get(Schema, "Events", New Map()) Do
			Name  = KeyValue.Key;
			Event = New Structure(New FixedStructure(KeyValue.Value));     		
			If Not Event.Property("Group") Or Event.Group = Undefined Then
				Event.Insert("group", Schema.Name);
			EndIf;	
			ServiceInfo.Events.Insert(Name, Event);	
		EndDo;
		
		Result.Add(ServiceInfo);
	EndDo;                          
	
	Return Result;
	
EndFunction

Function AdaptConnectionParams(Connection) Export
	
	If Connection = Undefined Or mol_Helpers.IsObject(Connection) Then
		Return Connection;
	EndIf;   
	
	If mol_Helpers.IsString(Connection) Then
		Connections = GetConnections();
		For Each ConnectionInfo In Connections Do
			If ConnectionInfo.Id = Connection Then
				Return ConnectionInfo;
			EndIf;
		EndDo;                                        
		Template = NStr("
		|	ru = 'Не удалось найти подключение с идентификатором ""%1""';
		|	en = 'Couldn't found connection with id ""%1""';");
		mol_Errors.RaiseCustomError("NotFoundError", StrTemplate(Template, Connection)); 
	EndIf;
	
	If Not IsStandalone() And TypeOf(Connection) = Type("CatalogRef.mol_Connections") Then
		Query = New Query(
		"SELECT
		|	UUID(Elements.Ref)   AS Id,   
		|	Elements.Description AS Description,
		|	Elements.Predefined  AS Default,
		|	""HTTP""             AS Type,
		|	Elements.Endpoint    AS Endpoint,
		|	Elements.Port        AS Port,
		|	Elements.UseSSL      AS UseSSL,
		|	Elements.AccessKey   AS AccessKey,
		|	Elements.SecretKey   AS SecretKey,
		|	Elements.Timeout     AS Timeout
		|FROM
		|	Catalog.mol_Connections AS Elements
		|WHERE TRUE
		|	AND Elements.Ref     = &Ref
		|	AND Elements.Enabled = True");
		Query.SetParameter("Ref", Connection);

		Selection = Query.Execute().Select();
		If Selection.Next() Then	
			Result = NewConnectionParams();
			FillPropertyValues(Result, Selection);
			Return Result;
		EndIf;
	EndIf;
	
	Return Undefined;
		
EndFunction

#EndRegion

#Region Private

// Returns the current Moleculer common module instance
//
// Returns:
//  CommonModule.Moleculer - current Moleculer common module instance
//
// BSLLS:UnusedLocalMethod-off
Function This()
	Return Moleculer;	
EndFunction

Function ThisMetadata()
	Return Metadata.CommonModules.Moleculer;	
EndFunction

#Region Constructors

Function NewServiceInfo()
	
	Result = New Structure();
	Result.Insert("Module");
	Result.Insert("Name");
	Result.Insert("Version");
	Result.Insert("FullName");
	Result.Insert("Settings");
	Result.Insert("Metadata", New Map());
	Result.Insert("Description");
	
	Result.Insert("Actions", New Map());
	Result.Insert("Events" , New Map());
	
	Result.Insert("Schema");		
		
	Return Result;
	
EndFunction

#EndRegion

Function GetPublicSettings(Val Settings)
    SecureSettings = Settings.Get("$secureSettings"); 
	If mol_Helpers.IsArray(SecureSettings) Then
		For Each SecureSetting In SecureSettings Do
			Parts = StrSplit(SecureSetting, ".");
			If Parts.Count = 1 Then
				Settings.Delete(Parts[0]);				
			Else      
				CurrentLeaf = Settings;
				Index = -1;
				For Each Part In Parts Do
					Index = Index + 1;
					LeafType = TypeOf(CurrentLeaf);
					IsLast = Index = Parts.UBound();
					LeafExists = False
						OR (LeafType = Type("Structure") AND CurrentLeaf.Property(Part))
						OR (LeafType = Type("Map") And CurrentLeaf.Get(Part) <> Undefined);
					If LeafExists Then
						If IsLast Then
							CurrentLeaf.Delete(Part);
						Else
							CurrentLeaf = CurrentLeaf[Part];
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;                                
	
	Return Settings;
	
EndFunction

#EndRegion
