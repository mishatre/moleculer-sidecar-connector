
#Region Public

// TODO: Add correct description. Should it be generic for constuctor
// or specific for service?
//
// Parameters:
//  TODO: Connect parameter descriptions with types
//
Procedure Constructor(Builder, Schema) Export
	
	// TODO: This part didn't trick 1C to infer type. But don't remove it
	#If Server And Not Server Then
		Builder = mol_SchemaFactory;
	#EndIf

	// Add option to choose constructor type

	// Ideal - YAML

	Builder.FromString("
	|name: shipments
	|version: 1
	|
	|metadata:
	|  $name: shipments
	|  $description: shipments
	|  $official: false
	|
	|actions:
	|  getInfo:
	|    description: Get shipment info
	|    handler: ShipmentsGetInfo
	|    params:
	|      $$root: true
	|      type: object
	|      strict: true
	|      minProps: 1
	|      maxProps: 1
	|      props: 
	|        externalUUID: string|optional
	|        number: string|optional
	|  getShippmentsInfo:
	|    description: Get shippments info by product uids
	|    handler: ShipmentsGetInfo
	|    params:
	|      startDate: string|no-empty
	|      endDate: string|no-empty
	|      productUids: array
	|
	|");

	// Normal - JSON
	
	// Worst - Builder

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

Function ActionHandler(Context) Export
	
	// Code Removed
	
EndFunction 

#EndRegion

#Region Events

Function EventHandler(Context) Export
	
	// Code Removed
	
EndFunction 

#EndRegion

#EndRegion

#Region Private

// Shared or private code 

#EndRegion
