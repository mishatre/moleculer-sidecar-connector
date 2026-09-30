
#Region Public 

Function Broker() Export
	Return mol_Broker;	
EndFunction

Function Call(ActionName, Params = Undefined, Opts = Undefined) Export 
	
	Context = mol_Helpers.LastFromStack(ThisMetadata().Name);
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	Opts.Insert("parentCtx", Context);
		                          
	Response = mol_Broker.Call(ActionName, Params, Opts);
	
	If Response.Property("Context") Then
		If Response.Context.Meta <> Undefined Then
			For Each KeyValue In Response.Context.Meta Do
				Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
			EndDo;
		EndIf;
	EndIf; 
	
	Return Response;
	
EndFunction 

Procedure Emit(EventName, Data = Undefined, Opts = Undefined) Export

	Context = mol_Helpers.LastFromStack(ThisMetadata().Name);
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	Opts.Insert("parentCtx", Context);
		
	mol_Broker.Emit(EventName, Data, Opts);

EndProcedure

#EndRegion

#Region Protected

Function Create(Broker, Params = Undefined, Opts = Undefined) Export
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;

	Context = Constructor(Broker);
	
	If Params <> Undefined Then
		SetParams(Context, Params);	
	EndIf; 
	
	If Opts <> Undefined Then
		For Each KeyValue In Opts Do
			Context.Options.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	// RequestID
	If Opts.Property("RequestID") And Opts.RequestID <> Undefined Then
		Context.RequestID = Opts.RequestID;
	ElsIf Opts.Property("ParentCtx") And mol_Helpers.IsStructure(Opts.ParentCtx) 
			And Opts.ParentCtx.Property("RequestID") And Opts.ParentCtx.RequestID <> Undefined Then
		Context.RequestID = Opts.ParentCtx.RequestID;
	EndIf;

	// Meta          
	If Opts.Property("ParentCtx") And mol_Helpers.IsStructure(Opts.ParentCtx)
			And Opts.ParentCtx.Property("Meta") And Opts.ParentCtx.Meta <> Undefined Then
		For Each KeyValue In Opts.ParentCtx.Meta Do 
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;     
	EndIf;
		
	If Opts.Property("Meta") And (mol_Helpers.IsStructure(Opts.Meta) Or mol_Helpers.IsMap(Opts.Meta)) Then
		For Each KeyValue In Opts.Meta Do 
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;            
	EndIf;
	
	// ParentID, Level, Caller, Tracing
	If Opts.Property("ParentCtx") And mol_Helpers.IsStructure(Opts.ParentCtx) Then
		Context.Tracing = Opts.ParentCtx.Tracing;
		Context.Level = Opts.ParentCtx.Level + 1;
		
		If Opts.ParentCtx.Property("Span") And mol_Helpers.IsStructure(Opts.ParentCtx.Span) Then
			Context.ParentID = Opts.ParentCtx.Span.Id;
		Else
			Context.ParentID = Opts.ParentCtx.Id;
		EndIf;
		
		If Opts.ParentCtx.Property("Service") And mol_Helpers.IsStructure(Opts.ParentCtx.Service) Then 
			Context.Caller = Opts.ParentCtx.Service.FullName;
		EndIf;
	EndIf;
			
	// caller
	If Opts.Property("Caller") Then
		Context.Caller = Opts.Caller;
	EndIf;

	// Parent span            
	If Opts.Property("ParentSpan") And mol_Helpers.IsStructure(Opts.ParentSpan) Then 
		Context.ParentID = Opts.ParentSpan.Id;
		Context.RequestID = Opts.ParentSpan.TraceID;
		Context.Tracing = Opts.ParentSpan.Sampled;
	EndIf;

	// Event acknowledgement
	If Opts.Property("NeedAck") Then
		Context.NeedAck = Opts.NeedAck;
	EndIf;    
	
	If Opts.Property("RaiseOnError") Then
		Context.RaiseOnError = Opts.RaiseOnError;
		Context.Options.Delete("RaiseOnError");
	EndIf;
	
	Return Context;
	
EndFunction

Procedure SetEndpoint(Context, Endpoint) Export

	Context.Endpoint = Endpoint;
	If mol_Helpers.IsStructure(Endpoint) Then
		Context.NodeID = Endpoint.Id;
		If Endpoint.Property("Action") And mol_Helpers.IsStructure(Endpoint.Action) Then
			Context.Action = Endpoint.Action;
			Context.Service = Context.Action.Service;
			Context.Event = Undefined;
		ElsIf Endpoint.Property("Event") And mol_Helpers.IsStructure(Endpoint.Event) Then
			Context.Event = Endpoint.Event;
			Context.Service = Context.Event.Service;
			Context.Action = Undefined;
		EndIf;
	EndIf;
	
EndProcedure 
                                                       
Procedure SetParams(Context, Params) Export
	
	If Params <> Undefined Then      
		// WHY?
		//Context.Params = New Structure();
		//For Each KeyValue In Params Do
		//	Context.Params.Insert(KeyValue.Key, KeyValue.Value);
		//EndDo;    
		Context.Params = Params;
	EndIf;
	
EndProcedure

#Region Payload

Function FromPayload(Payload) Export

	Context = Create(mol_Broker);
	If Payload.Property("action") Then
		Context.Id        = Payload.Id;      
		Context.Action    = mol_ContextFactory.NewActionReference(Payload.Action);
		mol_ContextFactory.SetParams(Context, Payload.Params);
		Context.ParentID  = Payload.ParentID;
		Context.RequestID = Payload.RequestID;
		Context.Caller    = Payload.Caller;
		Context.Meta      = PayloadMeta(Payload);
		Context.Locals    = Payload.Locals;
		Context.Level     = Payload.Level;
		Context.Tracing   = Payload.Tracing;	
	ElsIf Payload.Property("event") Then 
		Context = mol_ContextFactory.Create(mol_Broker);
		Context.Id           = Payload.Id;    
		mol_ContextFactory.SetParams(Context, Payload.Params);
		Context.EventName    = Payload.Event; 
		Context.EventGroups  = Payload.Groups;
		Context.EventType    = ?(Payload.Broadcast, "broadcast", "emit");
		Context.Meta         = PayloadMeta(Payload);
		Context.Locals       = Payload.Locals;
		Context.Level        = Payload.Level;
		Context.Tracing      = Payload.Tracing;
		Context.ParentID     = Payload.ParentID;
		Context.RequestID    = Payload.RequestID;
		Context.Caller       = Payload.Caller;	
	EndIf;   
	
	Return Context;
	
EndFunction

Function ToPayload(Context) Export
	
	Payload = New Structure();
	If Context.Property("Action") And Context.Action <> Undefined Then	  
		IsStream = mol_Helpers.IsStream(Context.Options.Stream) Or mol_Helpers.IsBinaryData(Context.Options.Stream);
		Payload.Insert("id"       , Context.Id);
		Payload.Insert("action"   , Context.Action.Name);
		Payload.Insert("params"   , Context.Params);
		Payload.Insert("meta"     , Context.Meta);
		Payload.Insert("timeout"  , Context.Options.Timeout);
		Payload.Insert("locals"   , Context.Locals);
		Payload.Insert("level"    , Context.Level);
		Payload.Insert("tracing"  , Context.Tracing);
		Payload.Insert("parentID" , Context.ParentID);
		Payload.Insert("requestID", Context.RequestID);
		Payload.Insert("caller"   , Context.Caller);
		Payload.Insert("stream"   , IsStream);
	ElsIf Context.Property("EventName") And Context.EventName <> Undefined Then
		Payload.Insert("id"       , Context.Id);
		Payload.Insert("event"    , Context.EventName);
		Payload.Insert("params"   , Context.Params);
		Payload.Insert("groups"   , Context.EventGroups);
		Payload.Insert("broadcast", Context.EventType = "broadcast");
		Payload.Insert("meta"     , Context.Meta);
		Payload.Insert("locals"   , Context.Locals);
		Payload.Insert("level"    , Context.Level);
		Payload.Insert("tracing"  , Context.Tracing);
		Payload.Insert("parentID" , Context.ParentID);
		Payload.Insert("requestID", Context.RequestID);
		Payload.Insert("caller"   , Context.Caller);
		Payload.Insert("needAck"  , Context.NeedAck);
	Else
		Raise "Malformed context";
	EndIf;
	
	Return Payload;
	
EndFunction

#EndRegion

Function Handler(Context) Export
	
	mol_Helpers.PushToStack(ThisMetadata().Name, Context); 
	
	Error  = Undefined;
	Result = Undefined;

	Try
		HandlerParts = StrSplit(Context.Locals.Handler, ".");      
		Parameters = New Array();
		Parameters.Add(Context);                              
		
		// Add protection from calling custom methods. Or better, move handler finding to 
		// client
		If Context.Action <> Undefined Then 
			Result = mol_Helpers.ExecuteModuleFunction(HandlerParts[0], HandlerParts[1], Parameters);
		ElsIf Context.Event <> Undefined Then
			mol_Helpers.ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters);
		Else
			mol_Errors.RaiseCustomError("Error", "Malformed context");	
		EndIf;
	Except              		
		Error = mol_Errors.GetCurrentError();
		If Error = Undefined Then
			Error = mol_Errors.FromErrorInfo(ErrorInfo());	
		EndIf;
	EndTry;     
	
	mol_Helpers.PopFromStack(ThisMetadata().Name);
	// The operation's ambient error ends with the operation: the push in mol_Errors.RaiseError is read
	// by the Except above, and this is the first place that runs after that read.
	mol_Errors.PopCurrentError();
	
	Return mol_Helpers.NewResponse(Error, Result);
	
EndFunction

Function GetCurrentContext() Export
	Return mol_Helpers.LastFromStack(ThisMetadata().Name);	
EndFunction

Procedure SetCurrentContext(Context) Export
	
	mol_Helpers.PushToStack(ThisMetadata().Name, Context);	
	
EndProcedure

Procedure PopCurrentContext() Export
	
	mol_Helpers.PopFromStack(ThisMetadata().Name);	
	
EndProcedure

#EndRegion

#Region Private           

Function This()
	Return mol_ContextFactory;	
EndFunction

Function ThisMetadata()
	Return Metadata.CommonModules.mol_ContextFactory;	
EndFunction  

#Region Constructors

Function NewContext()

	Result = new Structure();          
	Result.Insert("this"  , Undefined);
	Result.Insert("broker", Undefined);
	Result.Insert("nodeID", Undefined);
	Result.Insert("id"    , Undefined);
	
	Result.Insert("endpoint", Undefined);
	Result.Insert("service" , Undefined);
	Result.Insert("action"  , Undefined);
	Result.Insert("event"   , Undefined);
	
	// The emitted event "user.created" because `ctx.event.name` can be "user.**" 
	Result.Insert("eventName"  , Undefined);
	// Type of event ("emit" or "broadcast")
	Result.Insert("eventType"  , Undefined);
	// The groups of event  
	Result.Insert("eventGroups", Undefined);
	
	Result.Insert("options", New Structure());
	Result.Options.Insert("timeout", Undefined);
	Result.Options.Insert("retries", Undefined);
	Result.Options.Insert("stream" , Undefined);

	Result.Insert("parentID", Undefined);
	Result.Insert("caller"  , Undefined);

	Result.Insert("level", 1);
	
	Result.Insert("params", Undefined);
	Result.Insert("meta"  , New Map());
	Result.Insert("locals", New Structure());
	
	Result.Insert("requestID", Undefined);
	
	Result.Insert("tracing"   , Undefined);
	Result.Insert("span"      , Undefined);
	Result.Insert("_spanStack", New Array());

    Result.Insert("needAck", Undefined);
	Result.Insert("ackID"  , Undefined);

	Result.Insert("cachedResult", False);
	
	Result.Insert("raiseOnError", True);
	
	Result.Insert("stream", Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

// An inbound payload's meta, defaulted the way both references default it: Moleculer merges `opts.meta`
// over the parent's, and this project's sidecar reads `payload.meta || {}`. A payload that carries no meta
// at all therefore yields an empty map instead of raising, which is what reading the field directly did.
// The two-step form avoids relying on `И` not evaluating its right operand when the left is false.
Function PayloadMeta(Payload)

	If mol_Helpers.Has(Payload, "meta") Then
		If Payload.Meta <> Undefined Then
			Return Payload.Meta;
		EndIf;
	EndIf;

	Return New Map();

EndFunction

// The action as a context carries it, mirrored from Moleculer: `ctx.action` is the action object and the
// wire carries `ctx.action.name` (transit.js sends `action: ctx.action.name`), so an inbound name becomes
// an object again rather than staying a string. Both places that build an action use this, so the inbound
// and outbound directions describe the same shape and a payload survives the round trip.
Function NewActionReference(Name) Export

	Result = New Structure();
	Result.Insert("name", Name);

	Return Result;

EndFunction

Function Constructor(Broker)
	
	Context = NewContext(); 
	Context.This   = This(); 
	Context.Broker = Broker;

	If Context.Broker <> Undefined Then
		Context.NodeID = Context.Broker.NodeID();
		Context.Id     = Context.Broker.GenerateUid();
		Context.Caller = Context.Broker.NodeID();
	EndIf;                                     
		
	Context.Level     = 1;
	Context.RequestID = Context.Id;

	Return Context;
	
EndFunction

#EndRegion   

