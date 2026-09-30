// Behavioural tests for the payload contract between mol_ContextFactory and the wire.
//
// Source functions exercised, named per test as the acceptance requires:
//   mol_ContextFactory.ToPayload   — context to payload, one shape per direction
//   mol_ContextFactory.FromPayload — payload to context, including key casing
//
// Why this is the first slice of T018: the payload is the boundary every other assertion depends on. The
// two directions agree on one shape, and that shape is mirrored from Moleculer 0.14.35 rather than chosen
// here: the wire carries the action **name** (`transit.js` sends `action: ctx.action.name`) while the
// context holds the action **object** (`context.js` sets `this.action = endpoint.action`). The connector
// now does the same, including on the inbound side. An earlier version of this suite pinned the opposite
// — an inbound string stored where the outbound direction reads an object — and its round-trip test was
// written to be rewritten when the directions agreed, which is what happened.
//
// The golden payload mirrors the one the HTTP integration test sends — the same field names and values —
// so a failure in either place points at the same contract rather than at two fixtures that drifted.
//
// Mode note: canonical only. The standalone variant merges mol_ContextFactory and mol_Transport into
// Moleculer.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Payload contract")
		.ДобавитьСерверныйТест("ToPayloadEmitsTheActionFieldSet")
		.ДобавитьСерверныйТест("ToPayloadEmitsTheEventFieldSet")
		.ДобавитьСерверныйТест("ToPayloadRefusesAContextWithNeitherActionNorEvent")
		.ДобавитьСерверныйТест("FromPayloadReadsLowerCaseKeys")
		.ДобавитьСерверныйТест("FromPayloadKeepsEveryFieldOfTheGoldenPayload")
		.ДобавитьСерверныйТест("AnInboundContextSurvivesTheRoundTrip")
		.ДобавитьСерверныйТест("AnInboundEventSurvivesTheRoundTrip");

EndProcedure

Procedure ToPayloadEmitsTheActionFieldSet() Export

	// mol_ContextFactory.ToPayload — the outbound direction, needing the structure form of Action.
	Payload = mol_ContextFactory.ToPayload(OutboundContext("probe.action"));

	Declared = СтрРазделить("id,action,params,meta,timeout,locals,level,tracing,parentID,requestID,caller,stream", ",");
	ЮТест.ОжидаетЧто(Payload.Количество(), "an action payload carries twelve fields").Равно(Declared.Количество());

	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Payload.Property(Name), "the action payload declares " + Name).ЭтоИстина();
	EndDo;

	ЮТест.ОжидаетЧто(Payload.action, "the action name is taken from the context's action").Равно("probe.action");

EndProcedure

Procedure ToPayloadEmitsTheEventFieldSet() Export

	// mol_ContextFactory.ToPayload — the event direction. Its field set mirrors the event packet of
	// Moleculer 0.14.35 (`transit.js`: id, event, data, groups, broadcast, meta, level, tracing, parentID,
	// requestID, caller, needAck) and of this project's sidecar (`packet.ts` fromContext, which carries the
	// same list), with one deliberate difference in naming: the payload calls the data field `params`, which
	// is what the sidecar reads, where the core library calls it `data`.
	//
	// This test used to assert that an event payload carries no `meta`. Both references say it does, so the
	// assertion was rewritten — and it is what caught the difference.
	Context = OutboundContext();
	Context.EventName   = "probe.event";
	Context.EventGroups = Новый Массив;
	Context.NeedAck     = Ложь;

	Payload = mol_ContextFactory.ToPayload(Context);

	Declared = СтрРазделить("id,event,params,groups,broadcast,meta,locals,level,tracing,parentID,requestID,caller,needAck", ",");
	ЮТест.ОжидаетЧто(Payload.Количество(), "an event payload carries thirteen fields").Равно(Declared.Количество());

	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Payload.Property(Name), "the event payload declares " + Name).ЭтоИстина();
	EndDo;

	ЮТест.ОжидаетЧто(Payload.Property("meta"), "an event payload carries meta, like both references").ЭтоИстина();
	ЮТест.ОжидаетЧто(Payload.event, "the event name is carried").Равно("probe.event");

EndProcedure

Procedure ToPayloadRefusesAContextWithNeitherActionNorEvent() Export

	// mol_ContextFactory.ToPayload — a context that names nothing cannot be addressed to anyone, so it is
	// refused instead of producing a payload with no destination.
	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_ContextFactory.ToPayload(OutboundContext());
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "a context without an action or an event is refused").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "Malformed context") > 0, "the refusal says why: " + Failure).ЭтоИстина();

EndProcedure

Procedure FromPayloadReadsLowerCaseKeys() Export

	// mol_ContextFactory.FromPayload — the wire spells its keys in lower case, and the reader has to accept
	// them. Only `action` selects the action branch, so this also pins that the dispatch key is spelled the
	// way the producer emits it.
	Payload = NewActionPayload("probe.caseSensitive");

	Context = mol_ContextFactory.FromPayload(Payload);

	ЮТест.ОжидаетЧто(Context.Action.Name, "the action name is read from the payload").Равно("probe.caseSensitive");
	ЮТест.ОжидаетЧто(Context.Id, "the identifier is read").Равно("probe-1");
	ЮТест.ОжидаетЧто(Context.Level, "the level is read").Равно(1);

EndProcedure

Procedure FromPayloadKeepsEveryFieldOfTheGoldenPayload() Export

	// mol_ContextFactory.FromPayload — the fixture the HTTP integration test sends, so a failure here and a
	// failure there mean the same thing rather than two different descriptions of the wire.
	Context = mol_ContextFactory.FromPayload(NewActionPayload("probe.notRegistered"));

	ЮТест.ОжидаетЧто(Context.Action.Name, "the action survives").Равно("probe.notRegistered");
	ЮТест.ОжидаетЧто(Context.Id, "the identifier survives").Равно("probe-1");
	ЮТест.ОжидаетЧто(Context.RequestID, "the request identifier survives").Равно("probe-1");
	ЮТест.ОжидаетЧто(Context.Caller, "the caller survives").Равно("probe");
	ЮТест.ОжидаетЧто(Context.Level, "the level survives").Равно(1);
	ЮТест.ОжидаетЧто(Context.Tracing, "the tracing flag survives").Равно(Ложь);
	ЮТест.ОжидаетЧто(Context.ParentID, "the parent identifier survives").Равно(0);

EndProcedure

Procedure AnInboundContextSurvivesTheRoundTrip() Export

	// mol_ContextFactory.FromPayload + ToPayload — the two directions on the shape Moleculer uses: the wire
	// carries the action name, the context carries the action object, and the outbound direction reads the
	// name back off that object. This replaces the test that pinned the opposite, as it asked to be. What
	// depends on it is forwarding a received request to another node.
	//
	// One field is deliberately not asserted: `timeout` does not survive, because FromPayload never reads
	// the payload's timeout into Context.Options. Moleculer keeps it on the context, so this is a real
	// difference, recorded rather than smoothed over.
	Payload = NewActionPayload("probe.roundTrip");

	Context = mol_ContextFactory.FromPayload(Payload);
	Back    = mol_ContextFactory.ToPayload(Context);

	ЮТест.ОжидаетЧто(Back.action, "the action name survives the round trip").Равно(Payload.action);
	ЮТест.ОжидаетЧто(Back.id, "the identifier survives").Равно(Payload.id);
	ЮТест.ОжидаетЧто(Back.requestID, "the request identifier survives").Равно(Payload.requestID);
	ЮТест.ОжидаетЧто(Back.caller, "the caller survives").Равно(Payload.caller);
	ЮТест.ОжидаетЧто(Back.level, "the level survives").Равно(Payload.level);
	ЮТест.ОжидаетЧто(Back.Количество(), "the payload keeps its field count").Равно(Payload.Количество());

EndProcedure

Procedure AnInboundEventSurvivesTheRoundTrip() Export

	// The same pair on the event branch. Moleculer carries the emitted event as `ctx.eventName` (the packet
	// sends `event: ctx.eventName`), so an inbound name belongs in `eventName` — which is what the outbound
	// direction reads — and not in `event`, which is the subscription the receiving side matched.
	Payload = NewEventPayload("probe.event");

	Context = mol_ContextFactory.FromPayload(Payload);
	Back    = mol_ContextFactory.ToPayload(Context);

	ЮТест.ОжидаетЧто(Back.event, "the event name survives the round trip").Равно("probe.event");
	ЮТест.ОжидаетЧто(Back.broadcast, "the broadcast flag survives").Равно(Ложь);
	ЮТест.ОжидаетЧто(Back.Property("groups"), "the groups field survives").ЭтоИстина();
	ЮТест.ОжидаетЧто(Back.Количество(), "the event payload keeps its field count").Равно(Payload.Количество());

EndProcedure

// Builds an outbound context with the structure form of Action, which is what mol_Broker.Call assigns.
// Only the fields ToPayload touches are populated, so a failure points at the contract rather than at a
// fixture that drifted.
Function OutboundContext(ActionName = Неопределено)

	Context = Новый Структура;
	Context.Insert("Id"       , "probe-1");
	Context.Insert("Action"   , ?(ActionName = Неопределено, Неопределено, Новый Структура("Name", ActionName)));
	Context.Insert("EventName"  , Неопределено);
	Context.Insert("EventGroups", Неопределено);
	Context.Insert("EventType"  , Неопределено);
	Context.Insert("Params"   , Новый Структура);
	Context.Insert("Meta"     , Новый Массив);
	Context.Insert("Locals"   , Новый Структура);
	Context.Insert("Level"    , 1);
	Context.Insert("Tracing"  , Ложь);
	Context.Insert("ParentID" , 0);
	Context.Insert("RequestID", "probe-1");
	Context.Insert("Caller"   , "probe");
	Context.Insert("NeedAck"  , Ложь);
	Context.Insert("Options"  , Новый Структура("Timeout, Stream", 0, Ложь));
	Context.Insert("Stream"   , Неопределено);

	Return Context;

EndFunction

// The action payload as data, matching what mol_ContextFactory.ToPayload emits and what
// tests/bsl/http/test-inbound-transport.sh sends.
Function NewActionPayload(ActionName)

	Payload = Новый Структура;
	Payload.Insert("id"       , "probe-1");
	Payload.Insert("action"   , ActionName);
	Payload.Insert("params"   , Новый Структура);
	Payload.Insert("meta"     , Новый Соответствие);
	Payload.Insert("timeout"  , 0);
	Payload.Insert("locals"   , Новый Структура);
	Payload.Insert("level"    , 1);
	Payload.Insert("tracing"  , Ложь);
	Payload.Insert("parentID" , 0);
	Payload.Insert("requestID", "probe-1");
	Payload.Insert("caller"   , "probe");
	Payload.Insert("stream"   , Ложь);

	Return Payload;

EndFunction

// The event payload as data, matching what the event branch of mol_ContextFactory.ToPayload emits and
// what the event branch of FromPayload reads back.
Function NewEventPayload(EventName)

	Payload = Новый Структура;
	Payload.Insert("id"       , "probe-1");
	Payload.Insert("event"    , EventName);
	Payload.Insert("params"   , Новый Структура);
	Payload.Insert("groups"   , Новый Массив);
	Payload.Insert("broadcast", Ложь);
	Payload.Insert("meta"     , Новый Соответствие);
	Payload.Insert("locals"   , Новый Структура);
	Payload.Insert("level"    , 1);
	Payload.Insert("tracing"  , Ложь);
	Payload.Insert("parentID" , 0);
	Payload.Insert("requestID", "probe-1");
	Payload.Insert("caller"   , "probe");
	Payload.Insert("needAck"  , Ложь);

	Return Payload;

EndFunction

#EndRegion
