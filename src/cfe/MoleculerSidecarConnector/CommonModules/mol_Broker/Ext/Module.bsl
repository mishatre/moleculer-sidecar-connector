
#Region Public

#Region Requests

// Call an action 
//
// Parameters:
//  ActionName - String            - name of action
//  Params     - Any, Undefined    - params of action
//  Opts       - Object, Undefined - options of call  
//
// Returns - Any - service action response
//
Function Call(ActionName, Val Params = Undefined, Opts = Undefined) Export
	
	If Params = Undefined Then
		Params = New Structure();
	EndIf;
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;  
	
	ParentSpan = New Structure(); 
	ParentSpan.Insert("id"     , mol_Broker.GenerateUid());
	ParentSpan.Insert("traceID", ParentSpan.Id);
	ParentSpan.Insert("sampled", True);
	Opts.Insert("parentSpan", ParentSpan);
	
	Context = Undefined;
	If Opts.Property("Context") And Opts.Context <> Undefined Then		
		Context = Opts.Context;
		Context.Action = New Structure();
		Context.Action.Insert("name", ActionName);
	Else              
		Context = mol_ContextFactory.Create(mol_Broker, Params, Opts);
		Context.Action = New Structure();
		Context.Action.Insert("name", ActionName);		
	EndIf;  
	
	If False Then // For future
		mol_Logger.Debug("Call", 
			"Call action locally.",
			New Structure(
				"Action, RequestID",
				Context.Action.Name,
				Context.RequestID
			),
			This()
		);     
		If mol_Helpers.Has(Opts, "Stream") Then
			Context.Stream = Opts.Stream;
		EndIf;
	Else 
		mol_Logger.Debug("Call", 
			"Call action through sidecar node.",
			New Structure(
				"Action, RequestID",
				Context.Action.Name,
				Context.RequestID
			),
			This()
		);
	EndIf;      
	
	Connection = Moleculer.AdaptConnectionParams(mol_Helpers.Get(Opts, "Connection"));
	Response   = mol_Transport.ExecuteRequest(Context, Connection);
	
	mol_ContextFactory.SetCurrentContext(Context);
	
	Return Response;
	
EndFunction 

// Emit an event (grouped & balanced global event)
//
// Parameters:
//  EventName - String                             - event name
//  Payload   - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Procedure Emit(EventName, Payload = Undefined, Val Opts = Undefined) Export
	
	If mol_Helpers.IsArray(Opts) Or mol_Helpers.IsString(Opts) Then
		_Opts = Opts;
		Opts = New Structure();
		Opts.Insert("groups", _Opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();
		Opts.Insert("groups", New Array);
	EndIf;
	
	If Opts.Property("Groups") And Not mol_Helpers.IsArray(Opts.Groups) Then
		_Groups = New Array();
		_Groups.Add(Opts.Groups);
		Opts.Groups = _Groups;
	EndIf;
	
	Context = mol_ContextFactory.Create(mol_Broker, Payload, Opts);
	
	Context.EventName   = EventName;
	Context.EventType   = "emit";
	Context.EventGroups = Opts.Groups;

	mol_Logger.Debug("Broker.Emit",
		StrTemplate(
			"Emit '%1' event%2.",
			EventName, 
			?(Opts.Property("Groups"),
				StrTemplate(
					" to %1 groups(s)",
					StrConcat(Opts.Groups, ", ")
				),
				""
			)			
		),
		Undefined,
		This()
	);            
	
	Connection = Moleculer.AdaptConnectionParams(mol_Helpers.Get(Opts, "Connection"));
	Response   = mol_Transport.ExecuteRequest(Context, Connection);
	
	mol_ContextFactory.SetCurrentContext(Context);
	
	Return;
		
EndProcedure 

// Broadcast an event for all local & remote services
//
// Parameters:
//  EventName - String                             - event name
//  Payload   - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
//
Procedure Broadcast(EventName, Payload = Undefined, Val Opts = Undefined) Export
	
	If mol_Helpers.IsArray(Opts) Or mol_Helpers.IsString(Opts) Then
		_Opts = Opts;
		Opts = New Structure();
		Opts.Insert("groups", _Opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();
		Opts.Insert("groups", New Array);
	EndIf;
	
	If Opts.Property("Groups") And Not mol_Helpers.IsArray(Opts.Groups) Then
		_Groups = New Array();
		_Groups.Add(Opts.Groups);
		Opts.Groups = _Groups;
	EndIf;
	
	mol_Logger.Debug("Broker.Emit",
		StrTemplate(
			"Broadcast '%1' event%2.",
			EventName, 
			?(Opts.Property("Groups"),
				StrTemplate(
					" to %1 groups(s)",
					StrConcat(Opts.Groups, ", ")
				),
				""
			)			
		),
		Undefined,
		Metadata.CommonModules.mol_Broker
	);
	
	Context = mol_ContextFactory.Create(mol_Broker, Payload, Opts);
	
	Context.EventName   = EventName;
	Context.EventType   = "broadcast";
	Context.EventGroups = Opts.Groups; 
	
	Connection = Moleculer.AdaptConnectionParams(mol_Helpers.Get(Opts, "Connection"));
	Response   = mol_Transport.ExecuteRequest(Context, Connection);
	
	mol_ContextFactory.SetCurrentContext(Context);
	
	Return;
	
EndProcedure

#EndRegion

Function NodeID() Export
	Return Moleculer.GetConfig().NodeID;	
EndFunction

Function GenerateUid() Export
	Return String(New UUID());
EndFunction

#EndRegion

#Region Protected

#Region Publications

Function RegisterPublications() Export 
	
	Publications = Moleculer.GetPublications();	
	For Each Publication In Publications Do		
		Result = RegisterPublication(Publication);
	EndDo;
	
EndFunction

Function RegisterPublication(Publication) Export 
			
	Opts = New Structure();	
	If Publication.Connection <> Undefined Then
		Opts.Insert("connection", Publication.Connection);
	EndIf;            
	
	Connection = New Structure(New FixedStructure(Publication));
	Connection.Delete("Connection");
			
	Params = New Structure();
	Params.Insert("connection", Publication);

	Try
		Result = Call("$sidecar.register", Params, Opts);
	Except 
		
		Error = mol_Errors.GetCurrentError();
		If Error = Undefined Then
			Error = mol_Errors.FromErrorInfo(ErrorInfo());
		EndIf;           
		
		Template = NStr("
		|	ru = 'Не удалось зарегистрировать сервисную публикацию ""%1"" (%2)
		|По причине:
		|%3';
		|	en = 'Couldnt register service publication ""%1"" (%2).
		|Reason:
		|%3';");
		Message = StrTemplate(Template, 
			Publication.Description, 
			Publication.Id, 
			Error.Message
		);
		Error.Message = Message;  	
		mol_Logger.Error("Register", mol_Errors.ToString(Error), , ThisMetadata());
			
	EndTry;
	
EndFunction

Function UnregisterPublications() Export 
	
	Publications = Moleculer.GetPublications();
	For Each Publication In Publications Do
		
		Result = UnregisterPublication(Publication);
		
	EndDo; 
	
EndFunction

Function UnregisterPublication(Publication) Export 
	
	Params = New Structure();
	Params.Insert("publicationID", Publication.Id);

	Opts = New Structure();
	If Publication.Connection <> Undefined Then
		Opts.Insert("connection", Publication.Connection);	
	EndIf;
	
	Try
		Result = Call("$sidecar.unregister", Params, Opts);
	Except 
		
		Error = mol_Errors.GetCurrentError();
		If Error = Undefined Then
			Error = mol_Errors.FromErrorInfo(ErrorInfo());
		EndIf;
		
		Template = NStr("
		|	ru = 'Не удалось удалить регистрацию сервисной публикации ""%1"" (%2)
		|По причине:
		|%3';
		|	en = 'Cannot unregister service publication ""%1"" (%2).
		|Reason:
		|%3';"); 
		Message = StrTemplate(Template,      
			Publication.Description, 
			Publication.Id, 
			Error.Message
		);
		Error.Message = Message;		
		mol_Logger.Error("Unregister", mol_Errors.ToString(Error), , ThisMetadata());
			
	EndTry;

EndFunction

#EndRegion

Function GetSidecarNodeServices(Val Connection = Undefined) Export
	
	Connection = Moleculer.AdaptConnectionParams(Connection);
	
	Params = New Structure();
	Params.Insert("onlyLocal"    , True );
	Params.Insert("skipInternal" , False);
	Params.Insert("withActions"  , False);
	Params.Insert("onlyAvailable", True );
	
	Opts = New Structure();
	Opts.Insert("Connection", Connection);
	
	Return mol_Broker.Call("$node.services", Params, Opts);
	
EndFunction 

Function GetPublicationValidationCode(Publication) Export 
	
	Opts = New Structure();
	If Publication.Connection <> Undefined Then
		Opts.Insert("Connection", Publication.Connection);
		Publication.Delete("Connection");
	EndIf;
	
	Params = New Structure();
	Params.Insert("action"  , "$internal.wellknown");
	Params.Insert("nodeInfo", Publication); 
	
	Return mol_Broker.Call("$sidecar.callLocalNode", Params, Opts);
		
EndFunction


Function Delete_FindInternalHandler(ActionName) Export
	
	Schema = Undefined;
	Try
		Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal");
	Except 
		// Error already processed. Just skipping
		Return Undefined;
	EndTry;
	
	For Each KeyValue In mol_Helpers.Get(Schema, "Actions", New Map()) Do
		Name   = Schema.FullName + "." + KeyValue.Key;
		Action = KeyValue.Value;
		If Name = ActionName Then
			Return Action.Handler;
		EndIf;		
	EndDo;
	
	Return Undefined;
	
EndFunction
 
#Region ServiceDiscovery

Function Delete_EmitLocalServices(Context) Export 
	
	//BroadcastTypes = New Array();
	//BroadcastTypes.Add("broadcast");
	//BroadcastTypes.Add("broadcastLocal");
	//
	//IsBroadcast = BroadcastTypes.Find(Context.EventType) <> Undefined;
	//Sender = Context.NodeID;
	//
	//SchemasInfo = GetSchemasInfo(); 
	//
	//For Each Service In SchemasInfo.Specs Do
	//	For Each KeyValue In Service.Events Do 
	//		Event = KeyValue.Value;
	//		If Not mol_Helpers.Match(Context.EventName, Event.Name) Then
	//			Continue;
	//		EndIf;
	//		IsArray = mol_Helpers.IsArray(Context.EventGroups);
	//		If Context.EventGroups = Undefined Or 
	//			(IsArray And Context.EventGroups.Count() = 0) Or
	//			(IsArray And Context.EventGroups.Find(Event.Group) <> Undefined) Then
	//			
	//			If IsBroadcast Then
	//				// Unimplemented
	//			Else 
	//				Try
	//					HandlerParts = StrSplit(Event.Handler, ".");      
	//					Parameters = New Array();
	//					Parameters.Add(Context);
	//					mol_Helpers.ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters);
	//				Except           
	//					mol_Logger.Error("EmitLocalServices", "Error while handling event", ErrorInfo(), Metadata.CommonModules.mol_Broker);
	//				EndTry;	
	//			EndIf;
	//		EndIf;
	//	EndDo;
	//EndDo;

	                             
EndFunction

#EndRegion 

#EndRegion

#Region Private

Function This()
	Return mol_Broker;	
EndFunction 

Function ThisMetadata()
	Return Metadata.CommonModules.mol_Broker;	
EndFunction

#EndRegion     


