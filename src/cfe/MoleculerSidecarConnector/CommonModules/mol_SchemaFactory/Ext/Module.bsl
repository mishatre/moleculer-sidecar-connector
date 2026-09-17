
#Region Public

// Fill service schema from text definition (YAML or JSON)
//
// Parameters:
//  TextDefinition - String - Text service schema definition. Conforms to moleculer service schema structure
//
Procedure FromString(TextDefinition) Export
	
	Context = GetServiceBuildingContext();	
	
	If Not mol_Helpers.IsString(TextDefinition) Then
		mol_Errors.RaiseTypeError("TextDefinition", TextDefinition, Type("String"));	
	EndIf; 
	
	Try
		ObjectDefinition = ParseServiceDefinition(TextDefinition);
	Except     
		Message = NStr("
		|	ru = 'TextDefinition должна быть корректной строкой типа ""YAML"" или ""JSON""';
		|	en = 'TextDefinition should be contain valid ""YAML"" or ""JSON"" string';");
		mol_Errors.RaiseCustomError("ServiceSchema", Message, , ErrorInfo());
	EndTry;
		
	FillServiceSchema(Context, ObjectDefinition);
		
EndProcedure

#Region ServiceBuilderOptions

Procedure OnStarted(Handler = "Started") Export
	
	Context = GetServiceBuildingContext();
	CreateElement(Context, "OnStarted", Handler);	
	
EndProcedure

Procedure OnStopped(Handler = "Stopped") Export
	
	Context = GetServiceBuildingContext();
	CreateElement(Context, "OnStopped", Handler);	
	
EndProcedure

// Define new meta field in service schema
//
// Parameters:
//  Name  - String - Field name
//  Value - Any    - Field value
//
Procedure Meta(Name, Value) Export
	
	Context = GetServiceBuildingContext();
	CreateElement(Context, "Metadata", Name, Value);
	
EndProcedure

// Define new action in service schema
//
// Parameters:
//  Name    - String - New action name
//  Handler - String - Function name in service module that will be executed on action call
//
// Returns:
//  NewAction - Structure - See. mol_Helpers.NewActionSchema()
Function Action(Name, Handler) Export
	
	Context = GetServiceBuildingContext();
	Return CreateElement(Context, "Action", Name, Handler);
		
EndFunction

// Define new event in service schema
//
// Parameters:
//  Name    - String - New event name
//  Handler - String - Function name in service module that will be executed on event call
//
// Returns:
//  NewEvent - Structure - See. mol_Helpers.NewEventSchema()
Function Event(Name, Handler) Export
	
	Context = GetServiceBuildingContext();
	Return CreateElement(Context, "Event", Name, Handler);
	
EndFunction

// Define new channel in service schema
//
// Parameters:
//  Name    - String - New channel name
//  Handler - String - Function name in service module that will be executed on channel call
//
// Returns:
//  NewEvent - Structure - See. mol_Helpers.NewEventSchema()
Function Channel(Name, Handler) Export
	
	Context = GetServiceBuildingContext();
	Return CreateElement(Context, "Channel", Name, Handler);
	
EndFunction

#EndRegion                    

#Region Parameters

Function TypeString(Optional = False) Export

	Result = New Structure();
	Result.Insert("type"    , "string");
	Result.Insert("optional", Optional);
	
	Return Result;
	
EndFunction

Function TypeBoolean(Default = False, Optional = True, Convert = True) Export

	Result = New Structure();
	Result.Insert("type"    , "boolean");
	Result.Insert("optional", Optional);
	Result.Insert("convert" , Convert);
	Result.Insert("default" , Default);
	
	Return Result;
	
EndFunction

Function TypeArray(Items, Optional = False) Export

	Result = New Structure();
	Result.Insert("type"    , "array"); 
	Result.Insert("items"   , Items);
	Result.Insert("optional", Optional);
	
	Return Result;
	
EndFunction

Function TypeMulti(Rules, Optional = True) Export

	Result = New Structure();
	Result.Insert("type"    , "multi");
	Result.Insert("rules"   , Rules);
	Result.Insert("optional", Optional);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Protected

Function CompileServiceSchema(ModuleOrRef, Prefix = "") Export

	Context = Constructor(ModuleOrRef, Prefix);
	mol_Helpers.PushToStack(ThisMetadata().Name, Context);
	
	Try                            
		SetSafeMode(True);
		If Context.Type = Upper("Module") Then
			Parameters = New Array();      
			Parameters.Add(mol_SchemaFactory);
			Parameters.Add(Context.Schema);
			mol_Helpers.ExecuteModuleProcedure(Context.Module, "Constructor", Parameters); 
		ElsIf Context.Type = Upper("Dynamic") Then
			EvaluateServiceConstructor(Context);	
		EndIf;
       	SetSafeMode(False);		
	Except      
		Error = mol_Errors.GetCurrentError();
		If Error = Undefined Then
			Error = mol_Errors.FromErrorInfo(ErrorInfo());
		EndIf;  
		
		Template = NStr("
		|	ru = 'Не удалось скомпилировать схему сервиса - %1. По причине: 
		|%2';
		|	en = 'Couldnt compile service schema - %1. Reason:
		|%2';");		
		Error.Message = StrTemplate(Template, ModuleOrRef, Error.Message);  
		
		mol_Logger.Error("CompileServiceSchema", mol_Errors.ToString(Error), , ThisMetadata());
		
		mol_Helpers.ClearStack(ThisMetadata().Name);  
		
		Return Undefined;
		
	EndTry;
	
	Schema = Context.Schema;    
	
	If mol_Helpers.IsNumber(Schema.Version) OR mol_Helpers.CanBeNumber(Schema.Version) Then
		Schema.Version = Number(Schema.Version);
	EndIf;
		
	If Not IsBlankString(Prefix) Then // And mol_Helpers.GetConfigOption("DontPrefixServices") = False And Not StrStartsWith(Schema.Name, "$") Then
		Schema.Name = StrTemplate("%1.%2", Prefix, Schema.Name);
	EndIf;          
	
	If Schema.Settings.Get("$noVersionPrefix") <> True Then
		Schema.FullName = mol_Helpers.GetVersionedFullName(
			Schema.Name,
			Schema.Version
		);         
	Else
		Schema.FullName = Schema.Name;
	EndIf;     
	
	Schema.Metadata.Insert("$dynamic", Context.Type = "Dynamic");
	
	mol_Helpers.RemoveEmptyProperties(Schema, "name,version,metadata,settings");
	
	mol_Helpers.PopFromStack(ThisMetadata().Name);
	
	Return Schema;
	
EndFunction 

Function EvaluateServiceConstructor(__Context__)

	Schema  = __Context__.Schema;
	Builder = mol_SchemaFactory;
	Execute(__Context__.Constructor);
	
EndFunction

Function GetDynamicServiceConstructor(ServiceRef)
	
	Query = New Query("
	|SELECT
	|	Element.ServiceConstructor As ServiceConstructor
	|FROM
	|	Catalog.mol_Services AS Element
	|WHERE TRUE
	|	AND Element.Ref     = &Ref
	|	AND Element.Enabled = True");
	Query.SetParameter("Ref", ServiceRef);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Message = NStr("
		|	ru = 'Сервис не найден или выключен';
		|	en = 'Service not found or disabled';");
		mol_Errors.RaiseCustomError("ServiceSchemaError", Message);	
	EndIf;
	
	Return QueryResult.Unload()[0].ServiceConstructor;
	
EndFunction

#Region ServiceBuilderOptions

Procedure FillServiceSchema(Context, ObjectDefinition)
	
	SetProperty(ObjectDefinition, Context.Schema, "name");
	SetProperty(ObjectDefinition, Context.Schema, "version");
	
	Elements = mol_Helpers.Get(ObjectDefinition, "metadata", New Array());
	For Each KeyValue In Elements Do
		CreateElement(Context, "Metadata", KeyValue.Key, KeyValue.Value);	
	EndDo;
	
	Elements = mol_Helpers.Get(ObjectDefinition, "settings", New Array());
	For Each KeyValue In Elements Do
		mol_Helpers.Set(Context.Schema.Settings, KeyValue.Key, KeyValue.Value);	
	EndDo;
	
	Elements = mol_Helpers.Get(ObjectDefinition, "actions", New Array());
	ProcessElements(Context, Elements, "Actions");
	
	Elements = mol_Helpers.Get(ObjectDefinition, "events", New Array());
	ProcessElements(Context, Elements, "Events");
	
	Elements = mol_Helpers.Get(ObjectDefinition, "channels", New Array());
	ProcessElements(Context, Elements, "Channels");
		
EndProcedure 

Procedure ProcessElements(Context, Elements, Type)

	For Each Element In Elements Do
		Name  = Undefined;
		Value = Undefined;
		ExcludeProperties = New Array();
		ExcludeProperties.Add("handler");
		If TypeOf(Element) = Type("KeyAndValue") Then 
			Name  = Element.Key;
			Value = Element.Value;
		Else
			Name = mol_Helpers.Get(Element, "name");
			Value = Element;      
			ExcludeProperties.Add("name");
		EndIf;                                     
		
		If Not mol_Helpers.IsString(Name) Or IsBlankString(Name) Then
			Message = NStr("
			|	ru = 'Name должно быть типа ""Строка"" и содержать значение';
			|	en = 'Name should be type of ""String"" and contain value';");
			mol_Errors.RaiseCustomError("ServiceSchemaError", Message);	
		EndIf;
		
		Handler = mol_Helpers.Get(Value, "handler");
		If Not mol_Helpers.IsString(Handler) Or IsBlankString(Handler) Then
			Message = NStr("
			|	ru = 'Handler должно быть типа ""Строка"" и содержать значение';
			|	en = 'Handler should be type of ""String"" and contain value';");
			mol_Errors.RaiseCustomError("ServiceSchemaError", Message);	
		EndIf;
		
		NewElement = Undefined;
		If Upper(Type) = Upper("Actions") Then
			NewElement = CreateElement(Context, "Action", Name, Handler);
		ElsIf Upper(Type) = Upper("Events") Then
			NewElement = CreateElement(Context, "Event", Name, Handler);
		ElsIf Upper(Type) = Upper("Channels") Then
			NewElement = CreateElement(Context, "Channel", Name, Handler);
		Else   
			Template = NStr("
			|	ru = 'Передано неподдерживаемое значение реквизита Type - ""%1""';
			|	en = 'Received unsupported value of property Type - ""%1""';");
			Message = StrTemplate(Template, Type);
			mol_Errors.RaiseCustomError("ServiceSchemaError", Message);	
		EndIf;
		
		For Each KeyValue In Value Do
			If ExcludeProperties.Find(KeyValue.Key) <> Undefined And NewElement.Property(KeyValue.Key) Then
				Continue;
			EndIf;
			NewElement.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
		
		mol_Helpers.RemoveEmptyProperties(NewElement);
		
	EndDo;	
	
EndProcedure

Function CreateElement(Context, Element, Value1 = Undefined, Value2 = Undefined)
	
	NewElement = Undefined;
	
	If Upper(Element) = Upper("OnStarted") Then
		Context.Schema.Started = NewHandler(Context, Value1);
	ElsIf Upper(Element) = Upper("OnStopped") Then
		Context.Schema.Stopped = NewHandler(Context, Value1); 
	ElsIf Upper(Element) = Upper("Metadata") Then
		Context.Schema.Metadata.Insert(Value1, Value2);
	ElsIf Upper(Element) = Upper("Action") Then
		NewElement = NewActionSchema();
		NewElement.Name    = Value1;
		NewElement.Handler = NewHandler(Context, Value2); 
		Context.Schema.Actions.Insert(Value1, NewElement);
	ElsIf Upper(Element) = Upper("Event") Then
		NewElement = NewEventSchema();
		NewElement.Name    = Value1;
		NewElement.Handler = NewHandler(Context, Value2); 
		Context.Schema.Events.Insert(Value1, NewElement);
	ElsIf Upper(Element) = Upper("Channel") Then
		NewElement = NewEventSchema();
		NewElement.Name    = Value1;
		NewElement.Handler = NewHandler(Context, Value2); 
		Context.Schema.Channels.Insert(Value1, NewElement);
	EndIf;

	Return NewElement;
		
EndFunction

#EndRegion

#EndRegion

#Region Private

Function This()
	Return mol_SchemaFactory;	
EndFunction

Function ThisMetadata()
	Return Metadata.CommonModules.mol_SchemaFactory;	
EndFunction  

#Region Constructors

Function NewContext()

	Result = New Structure();
	Result.Insert("schema"     );
	Result.Insert("type"       );
	Result.Insert("module"     );
	Result.Insert("reference"  );
	Result.Insert("constructor");
	Result.Insert("prefix"     );
	
	Return Result;
	
EndFunction

Function NewSchema()
	
	// Map is used to allow internal settings ($noVersionPrefix)

	Result = New Structure;
	Result.Insert("name"         , ""       ); 
	Result.Insert("fullName"     , ""       );
	Result.Insert("version"      , Undefined);
	Result.Insert("settings"     , New Map  );
	Result.Insert("dependencies" , New Array);
	Result.Insert("metadata"     , New Map  );
	Result.Insert("actions"      , New Map  );
	Result.Insert("methods"      , New Array);
	Result.Insert("hooks"        , New Array); 
	
	Result.Insert("events"       , New Map);     
	Result.Insert("created"      , Undefined);
	Result.Insert("started"      , Undefined);
	Result.Insert("stopped"      , Undefined);

	Result.Insert("channels"     , New Map  ); 
	
	Return Result;
	
EndFunction

Function NewActionSchema()
	
	Result = New Structure();
	Result.Insert("name"          , ""       ); // name?: string;
	Result.Insert("rest"          , Undefined); // rest?: RestSchema | RestSchema[] | string | string[]; 
	// Visibility property to control the visibility & callability of service actions.
	// - published, null - public action. It can be called locally, remotely and can be published via API Gateway
	// - public          - public action, can be called locally & remotely but not published via API GW
	// - protected       - can be called only locally (from local services)
	// - private         - can be called only internally (via this.actions.xy() inside service)
	Result.Insert("visibility"    , Undefined); // visibility?: "published" | "public" | "protected" | "private";
	Result.Insert("params"        , New Structure()); // params?: ActionParams;
	Result.Insert("cache"         , Undefined); // cache?: boolean | ActionCacheOptions;
	Result.Insert("handler"       , ""       );      
	Result.Insert("tracing"       , Undefined); // boolean | TracingActionOptions;
	Result.Insert("bulkhead"      , Undefined); // bulkhead?: BulkheadOptions;
	Result.Insert("circuitBreaker", Undefined); // circuitBreaker?: BrokerCircuitBreakerOptions;
	Result.Insert("retryPolicy"   , Undefined); // retryPolicy?: RetryPolicyOptions;
	Result.Insert("fallback"      , Undefined); // fallback?: string | FallbackHandler;
	Result.Insert("hooks"         , Undefined); // hooks?: ActionHooks;
	Result.Insert("version"       , Undefined);
	
	Result.Insert("description"   , ""       );
	
	Return Result;
	
EndFunction
                         
Function NewEventSchema()

	Result = New Structure();
	Result.Insert("name"       , ""       ); // name?: string;
	Result.Insert("group"      , Undefined); // group?: string;
	Result.Insert("params"     , Undefined); // params?: ActionParams;
	Result.Insert("tracing"    , Undefined); // tracing?: boolean | TracingEventOptions;
	Result.Insert("bulkhead"   , Undefined); // bulkhead?: BulkheadOptions;
	Result.Insert("handler"    , ""       );
	Result.Insert("context"    , True     ); // context?: boolean;
		
	Result.Insert("description", ""       );

	Return Result;
	
EndFunction

Function NewRestSchema()
	
	Result = New Structure();
	Result.Insert("path"    , Undefined); // path?: string;
	Result.Insert("method"  , Undefined); // method?: "GET" | "POST" | "DELETE" | "PUT" | "PATCH";
	Result.Insert("fullPath", Undefined); // fullPath?: string;
	Result.Insert("basePath", Undefined); // basePath?: string;
	
	Return Result;
	
EndFunction

Function NewHandler(Context, Handler)
	
	If Context.Type = Upper("Module") Then
		Return StrTemplate("%1.%2", Context.Module, Handler);
	ElsIf Context.Type = Upper("Dynamic") Then
		Return Handler;
	EndIf; 
	
	Template = NStr("
	|	ru = 'Передано неподдерживаемое значение реквизита Context.Type - ""%1""';
	|	en = 'Received unsupported value of property Context.Type - ""%1""';");
	Message = StrTemplate(Template, Context.Type);
	mol_Errors.RaiseCustomError("ServiceSchemaError", Message);   		
	
EndFunction

#EndRegion

Function ParseServiceDefinition(Val Text)
	
	If StrStartsWith(Text, "{") Or StrStartsWith(Text, "[") Then
		Return mol_Helpers.FromJSONString(Text);
	Else                                     
		Params = New Structure();
		Params.Insert("string", StrReplace(Text, Chars.Tab, "    "));
		Return Moleculer.Call("$sidecar.utils.parseYAML", Params);
		Definition = StrReplace(Text, Chars.Tab, "    ");
		Return YAML.ToObject(Text);	
	EndIf;  
	
	Return Undefined;
	
EndFunction

#Region Context

Function GetServiceBuildingContext()
	
	Context = mol_Helpers.LastFromStack(ThisMetadata().Name);
	If Context = Undefined Then
		Message = NStr("
		|	ru = 'Функция вызвана вне контекста создания сервиса';
		|	en = 'Function called outside of service building context';");
		mol_Errors.RaiseCustomError("ServiceSchema", Message);
	EndIf;	
	
	Return Context;
	
EndFunction

#EndRegion

Function SetProperty(Src, Dst, Property)

	If Not mol_Helpers.IsString(Property) Then 
		mol_Errors.RaiseTypeError("Property", Property, Type("String"));	
	EndIf;
	
	Value = mol_Helpers.Get(Src, Property);
	If Value <> Undefined Then                       
		mol_Helpers.Set(Dst, Property, Value);
	EndIf;
	
EndFunction

Function Constructor(ModuleOrReference, Prefix)
	
	Context = NewContext(); 
	Context.Schema = NewSchema();
	
	If TypeOf(ModuleOrReference) = Type("String") Then
		CommonModule = Metadata.CommonModules.Find(ModuleOrReference);
		If CommonModule = Undefined Then               
			Template = NStr("
			|	ru = 'Модуль сервиса ""%1"" не найден';
			|	en = 'Service module ""%1"" not found';");
			Message = StrTemplate(Template, ModuleOrReference);
			mol_Errors.RaiseCustomError("ServiceSchema", Message);
		EndIf;
		If Not CommonModule.Server Then
			Template = NStr("
			|	ru = 'Модуль сервиса ""%1"" должен иметь установленный флаг ""Сервер""';
			|	en = 'Service module ""%1"" should have ""Server"" flag set';");
			Message = StrTemplate(Template, ModuleOrReference);
			mol_Errors.RaiseCustomError("ServiceSchema", Message);
		EndIf; 
		Context.Type   = Upper("Module");
		Context.Module = ModuleOrReference; 
	ElsIf TypeOf(ModuleOrReference) = Type("CommonModule") Then
		Context.Type   = Upper("Module");
		Context.Module = ModuleOrReference;
	ElsIf Not Moleculer.IsStandalone() And TypeOf(ModuleOrReference) = Type("CatalogRef.mol_Services") Then
		Context.Type        = Upper("Dynamic");
		Context.Reference   = ModuleOrReference;
		Context.Constructor = GetDynamicServiceConstructor(ModuleOrReference);
	Else                  
		mol_Errors.RaiseTypeError("ModuleOrReference", ModuleOrReference, 
			Type("String"), 
			?(Not Moleculer.IsStandalone(), Type("CatalogRef.mol_Services"), Undefined)
		);	
	EndIf; 
	
	Return Context;
	
EndFunction

#EndRegion 
