
#Region Public

// Provide nessesary details to build service in sidecar
// and connect it actions/events to current module functions
//
// Parameters:
//  Schema  - New service schema
//  Builder - Schema builder module
//
Procedure Constructor(Builder, Schema) Export
	
	#If Server And Not Server Then
		Builder = mol_SchemaFactory;
	#EndIf
	
	Schema.Name = "$internal"; 
	
	Action = Builder.Action("list", "ListAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params.Insert("withServices" , Builder.TypeBoolean());
	Action.Params.Insert("onlyAvailable", Builder.TypeBoolean());   
	
	Action = Builder.Action("services", "ServicesAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params.Insert("onlyLocal"    , Builder.TypeBoolean());
	Action.Params.Insert("withActions"  , Builder.TypeBoolean()); 
	Action.Params.Insert("withEvents"   , Builder.TypeBoolean());
	Action.Params.Insert("onlyAvailable", Builder.TypeBoolean());
	Action.Params.Insert("grouping"     , Builder.TypeBoolean(True));  
	
	Action = Builder.Action("actions", "ActionsAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params.Insert("onlyLocal"    , Builder.TypeBoolean());
	Action.Params.Insert("skipInternal" , Builder.TypeBoolean()); 
	Action.Params.Insert("withEndpoints", Builder.TypeBoolean());
	Action.Params.Insert("onlyAvailable", Builder.TypeBoolean());
	
	Action = Builder.Action("events", "EventsAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params.Insert("onlyLocal"    , Builder.TypeBoolean());
	Action.Params.Insert("skipInternal" , Builder.TypeBoolean()); 
	Action.Params.Insert("withEndpoints", Builder.TypeBoolean());
	Action.Params.Insert("onlyAvailable", Builder.TypeBoolean()); 
	
	Action = Builder.Action("health", "HealthAction");
	Action.Cache   = False;
	Action.Tracing = False;
	
	Action = Builder.Action("options", "OptionsAction");
	Action.Cache   = False;
	Action.Tracing = False;
	
	Action = Builder.Action("metrics", "MetricsAction");
	Action.Cache   = False;
	Action.Tracing = False; 
	
	Rules = New Array();
	Rules.Add(Builder.TypeString());
	Rules.Add(Builder.TypeArray("string"));
	DefaultParam = Builder.TypeMulti(Rules);
	
	Action.Params = New Structure();
	Action.Params.Insert("types"   , DefaultParam);
	Action.Params.Insert("includes", DefaultParam); 
	Action.Params.Insert("excludes", DefaultParam);
	
	
	Action = Builder.Action("ping", "PingAction");
	Action.Cache   = False;
	Action.Tracing = False;
		
	Action = Builder.Action("wellknown", "WellKnown");
	Action.Cache   = False;
	Action.Tracing = False;
	
EndProcedure

#EndRegion

#Region Protected

#Region Actions

Function ListAction(Context) Export
	
	mol_Logger.Warn(
		"ListAction", 
		"Called $internal.list action",
		Undefined, 
		ThisMetadata()
	);       
	
	Return "Hello. I am example action";
	
EndFunction 

Function ServicesAction(Context) Export
	
	mol_Logger.Warn(
		"ServicesAction", 
		"Called $internal.services action",
		Undefined, 
		ThisMetadata()
	); 
	
	Return Moleculer.GetServices(True);
	
EndFunction

Function ActionsAction(Context) Export
	
	mol_Logger.Warn(
		"ActionsAction", 
		"Called $internal.actions action",
		Undefined, 
		ThisMetadata()
	);
	Return "Hello. I am example action";
	
EndFunction

Function EventsAction(Context) Export
	
	mol_Logger.Warn(
		"EventsAction", 
		"Called $internal.events action",
		Undefined, 
		ThisMetadata()
	);
	Return "Hello. I am example action";
	
EndFunction

Function HealthAction(Context) Export
	
	mol_Logger.Warn(
		"HealthAction", 
		"Called $internal.health action",
		Undefined, 
		ThisMetadata()
	);
	Return "Hello. I am example action";
	
EndFunction

Function OptionsAction(Context) Export
	
	mol_Logger.Warn(
		"OptionsAction", 
		"Called $internal.options action",
		Undefined, 
		ThisMetadata()
	);
	Return "Hello. I am example action";
	
EndFunction

Function MetricsAction(Context) Export
	
	mol_Logger.Warn(
		"MetricsAction", 
		"Called $internal.metrics action",
		Undefined, 
		ThisMetadata()
	);
	Return "Hello. I am example action";
	
EndFunction    

Function PingAction(Context) Export
	Return "pong";	
EndFunction

Function WellKnown(Context) Export
	
	Return String(Constants.mol_TestConnection.Get());		
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function This()
	Return mol_Internal;	
EndFunction 

Function ThisMetadata()
	Return Metadata.CommonModules.mol_Internal;	
EndFunction

#EndRegion
