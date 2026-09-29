
Function ServiceGateway()
	Return "http://192.168.101.219/as/";
EndFunction

Function ServiceSettings()
	
	Settings = New Structure();
	
	Auth = New Structure(
		"username, password",
		"integration",
		"redacted"
	);
	
	Settings.Insert("Auth",    Auth);
	
	Return Settings;
	
EndFunction

Function SidecarGateway()
	//Return "http://192.168.101.219:5103";
	Return "http://192.168.5.243:5103";
EndFunction     

Function ServicePrefix()
	Return "Service";
EndFunction

#Region General

// <Function description>
//
//  Returns:
//   <Type.Subtype> - <returned value description>
//
Function Version() Export
	Return "0.0.4";
EndFunction

#EndRegion

#Region Transit

// Handle incoming request
//
// Parameters:
//   HTTPServiceRequest - HTTPServiceRequest - Service request from HTTP-Service method handler<parameter description>
//
//  Returns:
//   HTTPServiceResponse - Service response
//
Function RequestHandler(HTTPServiceRequest) Export
	
	Request = HTTPConnector.PrepareServiceRequest(HTTPServiceRequest);	
	Payload = ExtractRequestPayload(Request);	
					   	
	Context = CreateServiceContext(Request, Payload);
	
	If Payload = Undefined Then 
		Error = ValidationError("Incorrect service payload provided");
		Return GenerateServiceResponse(Context, Error.Code, , Error);
	EndIf;
		
	If Context.Service = Undefined Or 
		Context.Type = Undefined Or 
		Context.Name = Undefined Then
		Error = ServiceNotFoundError("Incorrect service URL provided");
		Return GenerateServiceResponse(Context, Error.Code, , Error);			
	EndIf;              
	
	CallStringResult = CreateServiceFunctionCallString(Context, "CallArgs");
	
	If Not CallStringResult.Success Then   
		Return GenerateServiceResponse(Context, CallStringResult.Error.Code, , CallStringResult.Error);
	EndIf;   
	
	If Context.Type = "actions" Then
		CallArgs = NewServiceContext(Undefined, True);
		Result = Eval(CallStringResult.String);
		If Result <> CallArgs.ContextId Then
			// LogError
		EndIf;
		
		For Each KeyValue In CallArgs.Registration.Params Do      
			If Context.Params.Property(KeyValue.Key) Then
				Context.Params[KeyValue.Key] = ConvertParameter(KeyValue.Value, Context.Params[KeyValue.Key]);
			EndIf;
		EndDo;	                                  
	EndIf;

	CallArgs = ?(Context.Type = "channels", Context.Payload, Context);  
		
	Try
		Return GenerateServiceResponse(Context, 200, Eval(CallStringResult.String));
	Except
		ErrorInfo = ErrorInfo();			
		Return GenerateServiceCallErrorResponse(Context, ErrorInfo);
	EndTry;
		
EndFunction  

Function ExtractRequestPayload(Request)

	JSONConversionParameters = New Structure;
	JSONConversionParameters.Insert("ReadToMap", False);	
	
	Try	
		Return HTTPConnector.AsJson(Request, JSONConversionParameters);
	Except        
		Return Undefined;
	EndTry;
	
	Return Undefined;
	
EndFunction

Function NewServiceContext(Payload, RegisterSchema = False)
	
	Context = New Structure;       
		
	Context.Insert("ContextId"     , New UUID());
	Context.Insert("RegisterSchema", RegisterSchema);
	
	If RegisterSchema Then
		Context.Insert("Registration"  , NewServiceRegistrationInfo());
		Return Context;
	EndIf;
	
	Context.Insert("RegisterSchema", False); 
	
	Context.Insert("Id"     , Payload.id); 
	Context.Insert("NodeID" , Payload.nodeID);
	
	Context.Insert("Type"     , Undefined); 
	Context.Insert("Name"     , Undefined);
	
	Context.Insert("Service", "");
	Context.Insert("Action" , "");
	Context.Insert("Event"  , "");
	Context.Insert("EventGroups", Payload.eventGroups);
	Context.Insert("EventName"  , Payload.eventName);
	Context.Insert("EventType"  , Payload.eventType);
	
	Context.Insert("Options", 
		New Structure(
			"Timeout, Retries", 
			Payload.options.timeout, 
			Undefined
		)
	); 
	
	If Payload.Property("parentId") Then
		Context.Insert("ParentID", Payload.parentId);	
	EndIf;
	Context.Insert("Caller"  , Payload.caller);
	Context.Insert("Level"   , Payload.level);
	
	Context.Insert("Params"  , New Structure);
	Context.Insert("Meta"    , New Structure);
		
	Context.Insert("RequestID", Context.Id);
	
	If Payload.Property("needAck") Then
		Context.Insert("NeedAck"  , Payload.needAck);
	EndIf;
	If Payload.Property("ackId") Then
		Context.Insert("AckId"    , Payload.ackId);
	EndIf;
		
	Return Context;
	
EndFunction

Function CreateServiceContext(Request, Payload)
	
	Context = NewServiceContext(Payload); 
	
	Context.Service = Request.Parameters.Get("Service");
	Context.Name = Request.Parameters.Get("Name");
	
	Context.Type = Request.Parameters.Get("Type");	
	If Context.Type = "actions" Then
		Context.Action = Context.Name;	
	ElsIf Context.Type = "events" Then
		Context.Event = Context.Name;
	ElsIf Context.Type = "channels" Then
		Context.Event = Context.Name;	
	EndIf;
	
	Context.Params = Payload.params;
	
	For Each KeyValue In Payload.meta Do
		Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
	EndDo;   
	
	Return Context;
	
EndFunction

Function CreateServiceFunctionCallString(Context, ArgsFieldName)   
	
	Result = New Structure;
	Result.Insert("Success", False    );
	Result.Insert("String" , Undefined);
	Result.Insert("Error"  , Undefined);
	
	ModuleInfo = GetServiceModule(Context.Service, True);
	
	If ModuleInfo = Undefined Then
		Result.Error = ServiceNotFoundError(StrTemplate("Couldn't find service with name: %1", Context.Name));
		Return Result;
	EndIf;        
	
	ServiceSchema = MoleculerReuse.GetServiceSchema(ModuleInfo.Name);
	
	If ServiceSchema = Undefined Then
		Result.Error = ServiceNotFoundError(StrTemplate("Couldn't obtain schema for service: %1", Context.Name));
		Return Result;
	EndIf;	                               
	
	Result.String  = StrTemplate("%1.%2(%3)", ModuleInfo.Name, Context.Name, ArgsFieldName);
	Result.Success = True;
	
	Return Result;
	
EndFunction

Function GenerateServiceResponse(Val Context, Val StatusCode = 200, Val Response = Undefined, Error = Undefined)
	
	JsonData = NewServiceResponse(Response, Error, Context);
	
	AdditionalParameters = HTTPConnector.NewServiceParameters();
	AdditionalParameters.Headers.Insert("Content-Type"    , "application/json");
	AdditionalParameters.Headers.Insert("content-encoding", "gzip"            );
	AdditionalParameters.Insert("Json", JsonData);
	
	Return HTTPConnector.ServiceResponse(StatusCode, Undefined, AdditionalParameters);
	
EndFunction

Function GenerateServiceCallErrorResponse(Context, ErrorInfo)
	ErrorDescription = BriefErrorDescription(ErrorInfo);   
	StackTrace       = DetailErrorDescription(ErrorInfo);
	//If StrStartsWith(ErrorDescription, "Метод объекта не обнаружен") Then      
	//	
	//	Error = ServiceNotFoundError(
	//		StrTemplate("Couldn't find service %1 with name: %2", Context.Type, Context.Name)
	//	);                
	//	Return GenerateServiceResponse(Context, Error.Code, , Error);
	//Else                     
		ErrorData = New Structure;
		ErrorData.Insert("moduleName", ErrorInfo.ModuleName);
		ErrorData.Insert("sourceLine", ErrorInfo.SourceLine);
		ErrorData.Insert("stack"     , StackTrace);
		Error = RequestRejectedError(
			StrTemplate(
				"An error occured while processing the request in service %1 with name: %2. Error: %3", 
				Context.Type, 
				Context.Name,
				ErrorDescription
			),
			ErrorData
		);                      
		Return GenerateServiceResponse(Context, Error.Code, , Error);
	//EndIf;	
EndFunction

Function NewServiceResponse(Response, Error = Undefined, Context = Undefined)
	
	ResponseBody = New Structure(); 
	
	If Error <> Undefined Then
		ResponseBody.Insert("error", Error);
	Else                                               
		If TypeOf(Response) = Type("Structure") Or TypeOf(Response) = Type("Array") Then
			ResponseBody.Insert("response", Response);
		Else
			ResponseBody.Insert("response", ?(ValueIsFilled(Response), Response, Undefined));
		EndIf;
	EndIf;
	
	If Context <> Undefined And Context.Property("Meta") Then
		ResponseBody.Insert("meta", Context.Meta);
	EndIf;
	
	Return ResponseBody;
	
EndFunction

#EndRegion

#Region Errors

#Region GenericErrors

Function MoleculerClientError(Type, Code = 400, Message = "", Data = Undefined)
	Return MoleculerError(Type, Code, "MoleculerClientError", Message, Data);
EndFunction

Function MoleculerServerError(Type, Code = 500, Message = "", Data = Undefined)
	Return MoleculerError(Type, Code, "MoleculerServerError", Message, Data);
EndFunction

Function MoleculerRetryableError(Type, Code = 500, Message = "", Data = Undefined)
	Return MoleculerError(Type, Code, "MoleculerRetryableError", Message, Data);
EndFunction

Function MoleculerError(Type, Code = 500, Name = "MoleculerError", Message = "", Data = Undefined)
	
	Error = New Structure;
	Error.Insert("name"   , Name);
	Error.Insert("message", Message);
	Error.Insert("code"   , Code);
	Error.Insert("type"   , Type);
	Error.Insert("data"   , Data);
	
	Return Error;
	
EndFunction

#EndRegion

#Region InternalErrors

Function ServiceNotFoundError(Message = "", Data = Undefined)
	Return MoleculerRetryableError("SERVICE_NOT_AVAILABLE", 404, Message, Data);
EndFunction

Function ServiceNotAvailableError(Message = "", Data = Undefined)
	Return MoleculerRetryableError("SERVICE_NOT_AVAILABLE", 404, Message, Data);
EndFunction

Function RequestTimeoutError(Message = "", Data = Undefined)
	Return MoleculerServerError("REQUEST_TIMEOUT", 504, Message, Data);
EndFunction

Function RequestSkippedError(Message = "", Data = Undefined)
	Return MoleculerError("REQUEST_SKIPPED", 514,, Message, Data);
EndFunction

Function RequestRejectedError(Message = "", Data = Undefined)
	Return MoleculerServerError("REQUEST_REJECTED", 503, Message, Data);
EndFunction

Function QueueIsFullError(Message = "", Data = Undefined)
	Return MoleculerError("QUEUE_FULL", 429, , Message,  Data);
EndFunction

Function ValidationError(Message = "", Data = Undefined)
	Return MoleculerClientError("VALIDATION_ERROR", 422, Message, Data);
EndFunction

Function MaxCallLevelError(Message = "", Data = Undefined)
	Return MoleculerError("MAX_CALL_LEVEL", 500, , Message, Data);
EndFunction

Function ServiceSchemaError(Message = "", Data = Undefined)
	Return MoleculerError("SERVICE_SCHEMA_ERROR", 500, , Message, Data);
EndFunction

Function BrokerOptionsError(Message = "", Data = Undefined)
	Return MoleculerError("BROKER_OPTIONS_ERROR", 500, , Message, Data);
EndFunction

Function GracefulStopTimeoutError(Message = "", Data = Undefined)
	Return MoleculerError("GRACEFUL_STOP_TIMEOUT", 500, , Message, Data);
EndFunction

Function ProtocolVersionMismatchError(Message = "", Data = Undefined)
	Return MoleculerError("PROTOCOL_VERSION_MISMATCH", 500, , Message, Data);
EndFunction

Function InvalidPacketDataError(Message = "", Data = Undefined)
	Return MoleculerError("INVALID_PACKET_DATA", 500, , Message, Data);
EndFunction

#EndRegion

#EndRegion

#Region Registry

//// <Function description>
////
////  Returns:
////   <Type.Subtype> - <returned value description>
////
//Function RegisterServices() Export
//	
//	Result = New Map;
//	
//	ServiceSchemas = BuildServiceSchemas();
//	
//	For Each ServiceSchema In ServiceSchemas Do
//		
//		Description = New Structure();
//		Description.Insert("Schema", ServiceSchema);
//		Description.Insert("Registered", False);
//		
//		ActionDescription = CreateSidecarAction("register");
//		Response = ExecuteSidecarCall(ActionDescription, ServiceSchema);
//		If Response.Property("Status") AND Upper(Response.Status) = "OK" Then
//			Description.Registered = True;
//		EndIf;
//		
//		Result.Insert(ServiceSchema.Name, Description);
//		
//	EndDo;
//	
//	Return Result;
//	
//EndFunction

//// Unregister all registered in sidecar gateway services
////
//Procedure UnregisterServices() Export
//	
//	ServicesSchemaArray = BuildServiceSchemas();
//	
//	For Each ServiceSchema In ServicesSchemaArray Do
//		
//		ServiceName = ServiceSchema.Name;
//		
//		If ServiceSchema.Property("version") Then
//			ServiceName = StrTemplate("v%1.", ServiceSchema.version) + ServiceName;
//		EndIf;
//		
//		ActionParams = New Structure();
//		ActionParams.Insert("serviceName", ServiceName);
//		
//		ActionDescription = CreateSidecarAction("unregister", ActionParams);
//		Response = ExecuteSidecarCall(ActionDescription);
//		
//	EndDo;
//	
//EndProcedure

Function GetServicesRegistrationInfo(HTTPServiceRequest) Export
		
	ServiceSchemas = GetServiceSchemas();
		
	AdditionalParameters = HTTPConnector.NewServiceParameters();
	AdditionalParameters.Headers.Insert("Content-Type"    , "application/json");
	AdditionalParameters.Headers.Insert("content-encoding", "gzip"            );
	AdditionalParameters.Insert("Json", ServiceSchemas);
	
	Return HTTPConnector.ServiceResponse(200, Undefined, AdditionalParameters);
	
EndFunction

#Region Registry  

#Region Structure

//Function NewRegistrationContext()
//	
//	Context = New Structure;
//		
//	Registration = NewServiceRegistrationInfo();
//	
//	Context.Insert("ContextId"     , New UUID());
//	Context.Insert("RegisterSchema", True        );
//	Context.Insert("Registration"  , Registration);
//	
//	Return Context;
//	
//EndFunction

Function NewServiceRegistrationInfo()   
	
	Registration = New Structure;
	
	Registration.Insert("Name"       , ""           );
	Registration.Insert("Description", ""           );
	Registration.Insert("Params"     , New Structure);
	
	Return Registration;
	
EndFunction

#EndRegion

Function GetServiceSchemas()
	
	Schemas = New Array;
	
	Modules = GetServiceModules();
	
	For Each ModuleInfo In Modules Do 
		
		NewSchema = GetServiceSchema(ModuleInfo.Name, ModuleInfo.Module);  
		
		If NewSchema <> Undefined Then
			Schemas.Add(NewSchema);
		EndIf;
				
	EndDo;
	
	Return Schemas;
		
EndFunction

Function GetServiceSchema(ModuleName, Module = Undefined) Export
	
	ServiceName = StrReplace(ModuleName, ServicePrefix(), "");
	Schema = CreateDefaultServiceSchema(ServiceName);
	
	If Module = Undefined Then
		ModuleInfo = GetServiceModule(ModuleName, False);
		If ModuleInfo = Undefined Then
			Return Undefined;
		EndIf;
		Module = ModuleInfo.Module;
	EndIf;
		
	Try
		Module.Schema(Schema); 
		
		For Each KeyValue In Schema.Actions Do
			Context = NewServiceContext(Undefined, True);
			SetSafeMode(True);
			Response = Eval(StrTemplate("Module.%1(Context)", KeyValue.Value));
			
			If Response = Context.ContextId Then			
				SchemaAddActionRegistration(Schema.Actions, KeyValue.Key, Context.Registration);	
			Else
				Schema.Actions.Delete(KeyValue.Key);
			EndIf;
		EndDo;
		
		Return Schema;
		
	Except 
		Return ErrorInfo();
		//StrTemplate("Each service module must have exported procedure ""Schema(Schema)"": %1", ServiceName);	
		
	EndTry;	
	
	Return Undefined;
		
EndFunction
	
Function GetServiceModules()

	Modules = New Array;
	
	ServicePrefix = ServicePrefix();
	CommonModules = Metadata.CommonModules;	
	
	For Each ModuleMetadata In CommonModules Do
		If StrStartsWith(ModuleMetadata.Name, ServicePrefix) Then     
			
			ModuleInfo = GetServiceModule(ModuleMetadata.Name, False);
			
			If ModuleInfo <> Undefined Then
				Modules.Add(ModuleInfo);
			EndIf;     
						
		EndIf;
	EndDo;
	
	Return Modules;
		
EndFunction

Function GetServiceModule(Val ModuleName, IncludePrefix = True)
		
	If IncludePrefix Then 	
		ServicePrefix = ServicePrefix();
		ModuleName = Lower(ServicePrefix + ModuleName);
	EndIf;
	
	ModuleMetadata = Metadata.CommonModules.Find(ModuleName);
	
	If ModuleMetadata = Undefined Then
		Return Undefined;
	EndIf;
	
	If Not ModuleMetadata.Server Then
		// Log registration Error
		Return Undefined;
	EndIf;     
		
	SetSafeMode(True);
	Module = Eval(ModuleMetadata.Name);
	
	ModuleInfo = New Structure;
	ModuleInfo.Insert("Name"  , ModuleMetadata.Name);
	ModuleInfo.Insert("Module", Module);
	
	Return ModuleInfo;
	
EndFunction

#EndRegion

#EndRegion

#Region Schema

Function NewServiceSchema()
	
	Schema = New Structure;
	Schema.Insert("name"         , "");
	Schema.Insert("version"      , "");
	Schema.Insert("settings"     , New Map); // Map is used to allow internal settings ($noVersionPrefix)
	Schema.Insert("metadata"     , New Map);
	Schema.Insert("actions"      , New Map);
	Schema.Insert("hooks"        , New Map);
	Schema.Insert("events"       , New Map);
	Schema.Insert("channels"     , New Map);
	//Schema.Insert("created"     , New Map);
	//Schema.Insert("started"     , New Map);
	//Schema.Insert("stopped"     , New Map);
	//Schema.Insert("mixins"      , New Map);
	Schema.Insert("dependencies" , New Array);
	
	Return Schema;
	
EndFunction

Function GetSchemaParametersDescription(ServiceSchema, ServiceCallType, ServiceCallName)
	
	Group = Undefined;
	If Not ServiceSchema.Property(ServiceCallType, Group) Then
		Return Undefined;
	EndIf;
           	
	For Each KeyValue In Group Do
		Handler = KeyValue.Value.Handler;
		If Handler = StrTemplate("/%1/%2", ServiceCallType, ServiceCallName) Then
			ParamsDescription = Undefined;
			If KeyValue.Value.Property("Params", ParamsDescription) Then
				Return ParamsDescription;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function ConvertParameter(Val Description, Val Value)
	
	If TypeOf(Description) = Type("String") Then
		Description = ParseParamsDescription(Description);
	EndIf;
	
	If Description.Type = "date" Then
		// JS Timestamp
		If TypeOf(Value) = Type("Number") Then
			Return ReadJSONDate(Value, JSONDateFormat.JavaScript);
		Else
			Return ReadJSONDate(Value, JSONDateFormat.ISO);
		EndIf;
	EndIf;
	
	Return Value;
	
EndFunction 

Function ParseParamsDescription(Val String)
	
	Schema = New Structure;
	
	Parts = StrSplit(String, "|");
	
	TypePartSeen = False;
	For Each Part In Parts Do
		Part = TrimAll(Part);
		
		If Not TypePartSeen Then
			If StrEndsWith(Part, "[]") Then
				Schema.Insert("type", "array");
			Else
				Schema.Insert("type", Part);
			EndIf;
			TypePartSeen = True;
		EndIf;
		
		Index = StrFind(Part, ":");
		
		If Index <> 0 Then
			Key   = TrimAll(Left(Part, Index));
			Value = TrimAll(Mid(Part, Index + 1));
			If Value = "true" Or Value = "false" Then
				Value = Value = "true";
			ElsIf IsNumber(Value) Then
				Value = Number(Value);
			EndIf;			
			Schema.Insert(Key, Value);
		Else
			If StrStartsWith(Part, "no-") Then
				Schema.Insert(Mid(Part, 4), False);
			Else
				Schema.Insert(Part, True);
			EndIf;
				
		EndIf;
		
	EndDo;    
	
	Return Schema;
	
	
EndFunction

Function CreateDefaultServiceSchema(ModuleName)
	
	Schema = NewServiceSchema();
	Schema.Name = ModuleName;
	Schema.Version = 1;
	
	BaseURL = ServiceGateway();
	BaseURL = ?(StrEndsWith(BaseURL, "/"), BaseURL, BaseURL + "/");
	Schema.Settings.Insert("baseUrl", StrTemplate("%1hs/moleculer/%2", BaseURL, Lower(ModuleName)));
	
	ConnectionSettings = ServiceSettings();
	If ConnectionSettings.Property("Auth") AND ConnectionSettings.Auth <> Undefined Then
		Schema.Settings.Insert("auth", ConnectionSettings.Auth);
	EndIf;
	
	SecureSettings = New Array;
	SecureSettings.Add("baseUrl");
	SecureSettings.Add("auth.username");
	SecureSettings.Add("auth.password");
	
	Schema.Settings.Insert("$secureSettings", SecureSettings);
		
	Schema.Metadata.Insert("$category"  , "external-integration"); 
	Schema.Metadata.Insert("$decription", "External 1C moleculer service"); 
	Schema.Metadata.Insert("$official"  , False); 
	
	Return Schema;
	
EndFunction

Procedure SchemaAddProperty(Schema, PropertyName)
	
	If TypeOf(Schema) <> Type("Structure") Then
		Raise "Cannot add schema property. Incorrect schema provided";
	EndIf;
	
	NewSchema = NewServiceSchema();
	
	If NOT NewSchema.Property(PropertyName) Then
		Raise StrTemplate("Property %1 does not exist in service schema", PropertyName);
	EndIf;
	
	If NOT Schema.Property(PropertyName) Then
		Schema.Insert(PropertyName, NewSchema[PropertyName]);
	EndIf;
	
EndProcedure


// <Procedure description>
//
// Parameters:
//   Schema - <Type.Subtype> - <parameter description>
//   NameOrShortName - <Type.Subtype> - <parameter description>
//   Version - <Type.Subtype> - <parameter description>
//
Procedure SchemaAddDependency(Schema, Val NameOrShortName, Val Version = Undefined) Export
	
	SchemaAddProperty(Schema, "dependencies");
	
	NewDependency = New Structure("name, version");
	
	If Version <> Undefined Then
		NewDependency.Name = NameOrShortName;
		NewDependency.Version = Version;
	Else
		
		Parts = StrSplit(NameOrShortName, ".");
		
		If Parts.Count() = 1 AND NOT StrStartsWith(Version, "v") Then
			NewDependency.Name = NameOrShortName;
		Else
			Version = Parts[0];
			If StrStartsWith(Version, "v") Then
				Try
					Version = Number(Right(Parts[0], StrLen(Parts[0]) - 1));
				Except
				EndTry;
			EndIf;
			NewDependency.Version = Version;
			Parts.Delete(0);
			NewDependency.Name = StrConcat(Parts, ".");
		EndIf;
		
	EndIf;
	
	If NewDependency.Version <> Undefined Then
		Unique = True;
		For Each Dependency In Schema.Dependencies Do
			If Dependency.Name = NewDependency.Name AND Dependency.Version = NewDependency.Version Then
				Unique = False;
				Break;
			EndIf;
		EndDo;
		If Unique Then
			Schema.Dependencies.Add(NewDependency);
		EndIf;
	Else
		If Schema.Dependencies.Find(NewDependency.Name) = Undefined Then
			Schema.Dependencies.Add(NewDependency.Name);
		EndIf;
	EndIf;
	
EndProcedure

// <Procedure description>
//
// Parameters:
//   Schema - <Type.Subtype> - <parameter description>
//   Name - <Type.Subtype> - <parameter description>
//   Value - <Type.Subtype> - <parameter description>
//
Procedure SchemaAddSettings(Schema, Name, Value) Export
	
	SchemaAddProperty(Schema, "settings");
	Schema.Settings.Insert(Name, Value);
	
EndProcedure

// <Procedure description>
//
// Parameters:
//   Schema - <Type.Subtype> - <parameter description>
//   Name - <Type.Subtype> - <parameter description>
//   Handler - <Type.Subtype> - <parameter description>
//   Params - <Type.Subtype> - <parameter description>
//   Rest - <Type.Subtype> - <parameter description>
//
Procedure SchemaAddAction(Schema, Name, Handler) Export
	
	SchemaAddProperty(Schema, "actions");
	
	If Schema.Actions.Get(Name) <> Undefined Then
		Raise StrTemplate("Cannon add action to schema. Action %1 already exitst", Name);
	EndIf;          
			
	Schema.Actions.Insert(Name, Handler);
			
EndProcedure

Function SchemaAddActionRegistration(Actions, Name, Registration)
	
	Description = New Structure();      
	
	For Each KeyValue In Registration Do  
		
		Property = KeyValue.Key;
		Value    = KeyValue.Value;
		
		If Property = "Params" Then			
			If TypeOf(Value) = Type("Structure") OR TypeOf(Value) = Type("Map") Then
				// TODO Validate Params type
				Description.Insert("params", Value);
			EndIf;			
		Else 
			If Lower(Property) = "name" OR Lower(Property) = "handler" Then
				Continue;
			EndIf;	
			Description.Insert(Property, Value);
		EndIf;
		
	EndDo;     
	
	Description.Insert("handler", "/actions/" + Lower(Actions[Name]));  
				
	Actions[Name] = Description;
	
EndFunction

// <Procedure description>
//
// Parameters:
//   Schema - <Type.Subtype> - <parameter description>
//   Name - <Type.Subtype> - <parameter description>
//   Handler - <Type.Subtype> - <parameter description>
//   Rest - <Type.Subtype> - <parameter description>
//
Procedure SchemaAddEvent(Schema, Name, Handler, Rest = Undefined) Export
	
	SchemaAddProperty(Schema, "events");
	
	If Schema.Events.Get(Name) <> Undefined Then
		Raise StrTemplate("Cannon add event to schema. Event %1 already exitst", Name);
	EndIf;
	
	Description = New Structure();
	
	If Rest <> Undefined AND (TypeOf(Rest) = Type("Structure") OR TypeOf(Rest) = Type("Map")) Then
		
		For Each KeyValue In Rest Do
			Key = Lower(KeyValue.Key);
			If Key = "name" OR Key = "handler" Then
				Continue;
			EndIf;
			Description.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
		
	EndIf;
	
	Description.Insert("handler", "/events/" + Lower(Handler));
	
	Schema.Events.Insert(Name, Description);
	
EndProcedure

// <Procedure description>
//
// Parameters:
//   Schema - <Type.Subtype> - <parameter description>
//   Name - <Type.Subtype> - <parameter description>
//   Handler - <Type.Subtype> - <parameter description>
//   Rest - <Type.Subtype> - <parameter description>
//
Procedure SchemaAddChannelEvent(Schema, Name, Handler, Rest = Undefined) Export
	
	SchemaAddProperty(Schema, "channels");
	
	If Schema.Channels.Get(Name) <> Undefined Then
		Raise StrTemplate("Cannon add channel event to schema. Event %1 already exitst", Name);
	EndIf;
	
	Description = New Structure();
	
	If Rest <> Undefined AND (TypeOf(Rest) = Type("Structure") OR TypeOf(Rest) = Type("Map")) Then
		
		For Each KeyValue In Rest Do
			Key = Lower(KeyValue.Key);
			If Key = "name" OR Key = "handler" Then
				Continue;
			EndIf;
			Description.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
		
	EndIf;
	
	Description.Insert("handler", "/channels/" + Lower(Handler));
	
	Schema.Channels.Insert(Name, Description);
	
EndProcedure


#EndRegion

#Region Broker

// <Function description>
//
// Parameters:
//   MethodName - <Type.Subtype> - <parameter description>
//   Params - <Type.Subtype> - <parameter description>
//   Opts - <Type.Subtype> - <parameter description>
//
//  Returns:
//   <Type.Subtype> - <returned value description>
//
Function Call(Val ActionName, Val Params = Undefined, Opts = Undefined, Stats = Undefined) Export
	
	//Val Context;
	//
	//If Params = Undefined Then
	//	Params = New Structure;
	//EndIf;
	//
	//If Opts.Property("Context") Then
	//	
	//	Endpoint = Broker_FindNextActionEndpoint(ActionName, Opts, Opts.Context);    
	//	If IsError(Endpoint) Then
	//		Error = Endpoint;
	//		Return Broker_ErrorHandler(Error, New Structure(
	//			"ActionName, Params, Opts",
	//			ActionName,
	//			Params,
	//			Opts
	//		));
	//	EndIf;
	//	
	//	// Reused context
	//	Context = Opts.Context;
	//	Context.Endpoint = Endpoint;
	//	Context.NodeID   = Endpoint.Id;
	//	Context.Action   = Endpoint.Action;
	//	Context.Service  = Endpoint.Action.Service;
	//	
	//Else
	//	
	//	// New root context
	//	Context = ContextFactory_Create(null, Params, Opts);
	//	
	//	Endpoint = Broker_FindNextActionEndpoint(ActionName, params, opts);
	//	If IsError(Endpoint) Then
	//		Error = Endpoint;
	//		Return Broker_ErrorHandler(Error, New Structure(
	//			"ActionName, Params, Opts",
	//			ActionName,
	//			Params,
	//			Opts
	//		));
	//	EndIf;
	//	
	//	Context_SetEndpoint(Context, Endpoint);	
	//			
	//EndIf;
	//
	//If Context.Endpoint.Local Then
	//	Broker_Logger_Debug("Call action locally.", 
	//		New Structure(
	//			"Action, RequestId", 
	//			Context.Action.Name, 
	//			Context.RequestId
	//		)
	//	);
	//Else
	//	Broker_Logger_Debug("Call action on remote node.", 
	//		New Structure(
	//			"Action, NodeID, RequestId", 
	//			Context.Action.Name, 
	//			Context.NodeID,
	//			Context.RequestId
	//		)
	//	);
	//EndIf;
	//
	//Response = Endpoint_Action_Handler(Endpoint, Context);
	//Response.Insert("Context", Context);
	//
	//Return Response;
	
	ActionParams = New Structure();
	ActionParams.Insert("action", ActionName);
	
	ActionDescription = CreateSidecarAction("call", ActionParams);
	
	Return ExecuteSidecarCall(ActionDescription, Params, Opts, Stats);
	
EndFunction

// <Function description>
//
// Parameters:
//   EventName - <Type.Subtype> - <parameter description>
//   Data - <Type.Subtype> - <parameter description>
//   OptsOrGroups - <Type.Subtype> - <parameter description>
//
//  Returns:
//   <Type.Subtype> - <returned value description>
//
Function Emit(Val EventName, Data = Undefined, OptsOrGroups = Undefined) Export
	
	Return EmitOrBroadcast("emit", EventName, Data, OptsOrGroups);
	
EndFunction

// <Function description>
//
// Parameters:
//   EventName - <Type.Subtype> - <parameter description>
//   Data - <Type.Subtype> - <parameter description>
//   OptsOrGroups - <Type.Subtype> - <parameter description>
//
//  Returns:
//   <Type.Subtype> - <returned value description>
//
Function Broadcast(Val EventName, Data = Undefined, OptsOrGroups = Undefined) Export
	
	Return EmitOrBroadcast("broadcast", EventName, Data, OptsOrGroups);
	
EndFunction

// <Function description>
//
// Parameters:
//   EventName - <Type.Subtype> - <parameter description>
//   Data - <Type.Subtype> - <parameter description>
//   OptsOrGroups - <Type.Subtype> - <parameter description>
//
//  Returns:
//   <Type.Subtype> - <returned value description>
//
Function SendToChannel(Val EventName, Data = Undefined, OptsOrGroups = Undefined) Export
	
	Return EmitOrBroadcast("sendToChannel", EventName, Data, OptsOrGroups);
	
EndFunction

#Region EventsInternal

Function EmitOrBroadcast(Val Type, Val EventName, Data = Undefined, OptsOrGroups = Undefined)
	
	ActionParams = New Structure();
	ActionParams.Insert("event", EventName);
	
	ActionDescription = CreateSidecarAction(Type, ActionParams);
	
	Opts = New Structure();
	
	If TypeOf(OptsOrGroups) = Type("Structure") Then
		Opts = OptsOrGroups;
		If Opts.Property("groups") AND TypeOf(Opts.groups) <> Type("Array") Then
			Groups = Opts.groups;
			Opts.groups = New Array;
			Opts.groups.Add(Groups);
		EndIf;
	ElsIf TypeOf(OptsOrGroups) = Type("Array") Then
		Opts.Insert("groups", New Array);
		For Each Group In OptsOrGroups Do
			Opts.groups.Add(Group);
		EndDo;
	ElsIf TypeOf(OptsOrGroups) = Type("String") Then
		Opts.Insert("groups", OptsOrGroups);
	EndIf;
	
	Return ExecuteSidecarCall(ActionDescription, Data, Opts);
	
EndFunction

#EndRegion

//Function Broker_FindNextActionEndpoint(ActionName, Opts, Context) 
//	
//	If TypeOf(ActionName) <> Type("String") Then
//		Return ActionName;
//	Else
//		If Opts <> Undefined And Opts.Property("NodeID") And ValueIsFilled(Opts.NodeID) Then
//			NodeID = Opts.NodeID;
//			// Direct call
//			Endpoint = Registry_GetActionEndpointByNodeId(ActionName, NodeID);
//			If Endpoint = Undefined Then
//				Text = StrTemplate("Service '%1' is not found on '$2' node.", ActionName, NodeID);
//				Broker_Logger_Warn(Text);
//				Return ServiceNotFoundError(, New Structure("Action, NodeID", ActionName, NodeID));
//			EndIf;
//			Return Endpoint;
//		Else
//			// Get endpoint list by action name
//			EpList = Registry_GetActionEndpoints(ActionName);
//			If EpList = Undefined Then
//				Text = StrTemplate("Service '%1' is not registered.", ActionName);
//				Broker_Logger_Warn(Text);
//				Return ServiceNotFoundError(, New Structure("Action", ActionName));
//			EndIf;
//			
//			// Get the next available endpoint
//			Endpoint = Endpoints_Next(EpList, Context);
//			If Endpoint = Undefined Then
//				Text = StrTemplate("Service '%1' is not available.", ActionName);
//				Broker_Logger_Warn(Text);
//				Return ServiceNotAvailableError(, New Structure("Action", ActionName));
//			EndIf;
//			Return Endpoint;			
//		EndIf;
//	EndIf;	
//	
//EndFunction











#EndRegion 




Function ExecuteSidecarCall(Val ActionDescription, Val Params = Undefined, Opts = Undefined, Stats = Undefined)
	
	AdditionalParameters = HTTPConnector.NewParameters();      
	CombineWithDefaultHeaders(AdditionalParameters, Opts);
	
	AdditionalParameters.JSONConversionParameters.Insert(
		"JSONDateWritingVariant",
		JSONDateWritingVariant.UniversalDate
	);
	
	If ActionDescription.Registry Then
		AdditionalParameters.Json = Params;
	ElsIf Params <> Undefined Then
		AdditionalParameters.Json = NewRequestBody(Params, Opts);
	EndIf;    
	
	Gateway = SidecarGateway();
	If Not ValueIsFilled(Gateway) Then
		Raise "Gateway address is not provided";
	EndIf;
	
	URLParts = HTTPConnector.ParseURL(Gateway);	
	URL = StrTemplate("%1://%2:%3%4", 
		?(URLParts.Scheme = "", "http", URLParts.Scheme), 
		URLParts.Host, 
		?(URLParts.Port = "", "5103", URLParts.Port),
		ActionDescription.ResourceAddress
	);          
	
	Response = Undefined;
	Result   = New Structure;
	
	Try 
		Response = HTTPConnector.CallMethod(ActionDescription.Method, URL, AdditionalParameters);
		
		If TypeOf(Stats) = Type("Structure") Then	
			Stats.Insert("ExecutionTime", Response.ExecutionTime);
		EndIf;
		
		JSONConversionParameters = New Structure;
		JSONConversionParameters.Insert("ReadToMap", False);
		ResponseBody = Undefined;
		Try
			ResponseBody = HTTPConnector.AsJson(Response, JSONConversionParameters);  
		Except
			JSONConversionParameters.Insert("ReadToMap", True);
			ResponseBody = HTTPConnector.AsJson(Response, JSONConversionParameters);
		EndTry;
		
		If TypeOf(ResponseBody) = Type("Map") Then  
			// Very fucking important that response is lowercased
			Response = ResponseBody.Get("response");
			If Response <> Undefined Then
				Result = Response;
			EndIf;
		ElsIf TypeOf(ResponseBody) = Type("Structure") Then 	
			If ResponseBody.Property("Response") And ResponseBody.Response <> Undefined Then
				Result = ResponseBody.Response;
			EndIf;      
		EndIf;  
		
		// ADD THE FUCKING ERROR HANDLER. GOD DAMNED
		
	Except
		Error = ErrorDescription();
		Result.Insert("Error", Error);
	EndTry;
				
	Return Result;
		
EndFunction

Function GetSidecarActions()
	
	ActionsMap = New Map();
	ActionsMap.Insert("call", NewSidecarActionMethod("POST", "/v1/call/:action"));
	ActionsMap.Insert("emit", NewSidecarActionMethod("POST", "/v1/emit/:event"));
	ActionsMap.Insert("broadcast", NewSidecarActionMethod("POST", "/v1/broadcast/:event"));
	ActionsMap.Insert("sendToChannel", NewSidecarActionMethod("POST", "/v1/sendToChannel/:event"));
	
	ActionsMap.Insert("register", NewSidecarActionMethod("POST", "/v1/registry/services/", True));
	ActionsMap.Insert("unregister", NewSidecarActionMethod("DELETE", "/v1/registry/services/:serviceName", True));
	
	// Registry
	ActionsMap.Insert("nodes", NewSidecarActionMethod("GET", "/v1/registry/nodes/", True));
	ActionsMap.Insert("services", NewSidecarActionMethod("GET", "/v1/registry/services/", True));
	ActionsMap.Insert("actions", NewSidecarActionMethod("GET", "/v1/registry/actions/", True));
	ActionsMap.Insert("events", NewSidecarActionMethod("GET", "/v1/registry/events/", True));
	
	Return ActionsMap;
	
EndFunction

Function NewSidecarActionMethod(Val Method, Val Path, Val Registry = False)
	
	Description = New Structure();
	Description.Insert("Method", Upper(Method));
	Description.Insert("Path", Path);
	Description.Insert("Params", New Array);
	Description.Insert("Registry", Registry);
	
	PathParts = StrSplit(Path, "/");
	
	For Each Part In PathParts Do
		If StrStartsWith(Part, ":") Then
			Description.Params.Add(StrReplace(Part, ":", ""));
		EndIf;
	EndDo;
	
	Return Description;
	
EndFunction

Function CreateSidecarAction(Val ActionName, Val ActionParams = Undefined)
	
	ActionsMap = GetSidecarActions();
	Action = ActionsMap.Get(ActionName);
	
	If Action = Undefined Then
		Raise StrTemplate("Unknown action provided: %1", Action);
	EndIf;
	
	ActionDescription = New Structure();
	ActionDescription.Insert("Method", Action.Method);
	ActionDescription.Insert("Registry", Action.Registry);
	
	ResourceAddress = Action.Path;
	
	For Each Param In Action.Params Do
		
		If ActionParams = Undefined OR NOT ActionParams.Property(Param) Then
			Raise StrTemplate("Required action param is not provided: %1", Param);
		EndIf;
		
		ResourceAddress = StrReplace(ResourceAddress, StrTemplate(":%1", Param), ActionParams[Param]);
		
	EndDo;
	
	ActionDescription.Insert("ResourceAddress", ResourceAddress);
	
	Return ActionDescription;
	
EndFunction

Function NewRequestBody(Val Params = Undefined, Val Opts = Undefined)
	
	RequestBody = New Structure();
	RequestBody.Insert("params", ?(Params = Undefined, New Structure, Params));
	RequestBody.Insert("meta", New Structure);
	RequestBody.Insert("options", New Structure);
	
	If Opts <> Undefined Then
		For Each KeyValue In Opts Do
			If Lower(KeyValue.Key) = "meta" Then
				RequestBody.meta = KeyValue.Value;
			Else
				RequestBody.options.Insert(KeyValue.Key, KeyValue.Value);
			EndIf;
		EndDo;
	EndIf;
	
	Return RequestBody;
	
EndFunction 

Function CombineWithDefaultHeaders(AdditionalParameters, Opts) 
	
	AdditionalParameters.Headers.Insert("content-type"    , "application/json");
	AdditionalParameters.Headers.Insert("content-encoding", "gzip"); 
	
	If Opts <> Undefined Then
		
		If Opts.Property("Timeout") And TypeOf(Opts.Timeout) = Type("Number") Then	          
			AdditionalParameters.Headers.Insert("x-request-timeout", Format(Opts.Timeout, "ЧГ="));
			AdditionalParameters.Timeout = Opts.Timeout;
		EndIf;                            
		
	EndIf;                             
	
	AdditionalParameters.Headers.Insert("x-sidecar-module"        , "moleculer-1c");
	AdditionalParameters.Headers.Insert("x-sidecar-module-version", Version());
	
EndFunction

#Region Utils

Function IsNumber(Val Value)
	
	Try
		Value = Number(Value);
		Return True;
	Except
		Return False;
	EndTry;
	
EndFunction

#EndRegion

#Region Compatibility

Function StrTemplate(Val TemplateStr, Arg1 = Undefined, Arg2 = Undefined, Arg3 = Undefined, Arg4 = Undefined, Arg5 = Undefined, Arg6 = Undefined)
	TemplateStr = StrReplace(TemplateStr, "%1", Arg1);
	TemplateStr = StrReplace(TemplateStr, "%2", Arg2);
	TemplateStr = StrReplace(TemplateStr, "%3", Arg3);
	TemplateStr = StrReplace(TemplateStr, "%4", Arg4);
	TemplateStr = StrReplace(TemplateStr, "%5", Arg5);
	TemplateStr = StrReplace(TemplateStr, "%6", Arg6);
	Return TemplateStr;
EndFunction

Function StrStartsWith( String, SearchString )
	Return ( Left( String, StrLen( SearchString ) ) = SearchString );	
EndFunction

Function StrEndsWith( String, SearchString )
	Return ( Right( String, StrLen( SearchString ) ) = SearchString );				
EndFunction      

Function StrSplit(Знач Строка, Разделитель, ВключатьПустые = Истина)
	
	Строка = СтрЗаменить(Строка, Разделитель, Символы.ПС);
	
	Массив = Новый Массив;
	
	Для Индекс = 1 По СтрЧислоСтрок(Строка) Цикл
		Значение = СтрПолучитьСтроку(Строка, Индекс);
		Если ЗначениеЗаполнено(Значение) ИЛИ Не ВключатьПустые Тогда
			Массив.Добавить(Значение);	
		КонецЕсли;				
	КонецЦикла;
	
	Возврат Массив;
	
EndFunction

Function StrConcat(Строки, Разделитель)
	
	Строка = "";
	
	Для Каждого ЧастьСтроки Из Строки Цикл
		Строка = Строка + ЧастьСтроки + Разделитель;
	КонецЦикла;
	
	Если ЗначениеЗаполнено(Строка) Тогда
		Строка = Лев(Строка, СтрДлина(Строка) - СтрДлина(Разделитель));
	КонецЕсли;
	
	Возврат Строка;
	
EndFunction

Function StrFind( Val String, Val SearchString, Val SearchDirection = "SearchDiraction.FromStart", Val InitialPosition = 1, Val EntryNumber = 1)
	
	If Not ValueIsFilled(String) Then
		Return 0;
	EndIf;
	
	НаправлениеПоискаСКонца = SearchDirection = "SearchDiraction.FromEnd";
	
	ТекущаяПозиция = 0;
    ЗнакНаправленияДвижения = 0; 
    ДлинаСтрПоиска = StrLen(SearchString);
    Try
        If InitialPosition <> Undefined Then
            InitialPosition = Number(InitialPosition);    
            If InitialPosition <= 0 Or InitialPosition > СтрДлина(String) Then
                Raise ("");                    
            EndIf;            
        EndIf;        
    Except        
        Raise ("Недопустимое значение параметра (параметр номер '4')");
    EndTry;
    If НаправлениеПоискаСКонца Then 
        InitialPosition = ?(InitialPosition <> Undefined, InitialPosition, StrLen(String));
        ЗнакНаправленияДвижения = -1;
    Else    
        InitialPosition = ?(InitialPosition <> Undefined, InitialPosition, 1);
        ЗнакНаправленияДвижения = 1;
    EndIf;

    // Пассивный оригинал расположенного ниже однострочного кода. Выполняйте изменения синхронно в обоих вариантах.
    #Если Сервер И Не Сервер Тогда
    Пока Истина
        И EntryNumber <> 0
        И (Ложь
            Или (Истина
                И Не НаправлениеПоискаСКонца 
                И InitialPosition <= СтрДлина(Строка)) 
            Или (Истина
                И НаправлениеПоискаСКонца 
                И InitialPosition >= 0)) 
    Цикл    
        Позиция = Найти(Сред(String, InitialPosition, ДлинаСтрПоиска), SearchString); 
        Если Позиция Тогда 
            ТекущаяПозиция = InitialPosition;
            НачальнаяПозиция = ТекущаяПозиция + ДлинаСтрПоиска * ЗнакНаправленияДвижения;
            EntryNumber = EntryNumber - 1;
        Иначе
            InitialPosition = InitialPosition + 1 * ЗнакНаправленияДвижения; 
        КонецЕсли;
    КонецЦикла;
    #КонецЕсли
    // Однострочный код использован для ускорения. Выше расположен оригинал. Выполняйте изменения синхронно в обоих вариантах. Преобразовано консолью кода из подсистемы "Инструменты разработчика" (http://devtool1c.ucoz.ru)
    Пока Истина И EntryNumber <> 0 И (Ложь Или (Истина И Не НаправлениеПоискаСКонца И InitialPosition <= СтрДлина(String)) Или (Истина И НаправлениеПоискаСКонца И InitialPosition >= 0)) Цикл Позиция = Найти(Сред(String, InitialPosition, ДлинаСтрПоиска), SearchString); Если Позиция Тогда ТекущаяПозиция = InitialPosition; InitialPosition = ТекущаяПозиция + ДлинаСтрПоиска * ЗнакНаправленияДвижения; EntryNumber = EntryNumber - 1; Иначе InitialPosition = InitialPosition + 1 * ЗнакНаправленияДвижения;          КонецЕсли;      КонецЦикла;  

    If EntryNumber Then
        ТекущаяПозиция  = 0;
	EndIf;        

    Return ТекущаяПозиция;
	
EndFunction

#EndRegion 