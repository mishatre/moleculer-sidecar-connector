// Behavioural tests for the payload contract between mol_ContextFactory and the wire.
//
// Source functions exercised, named per test as the acceptance requires:
//   mol_ContextFactory.ToPayload   — context to payload, one shape per direction
//   mol_ContextFactory.FromPayload — payload to context, including key casing
//
// Why this is the first slice of T018: the payload is the boundary every other assertion depends on, and
// the two directions do not produce the same shape. ToPayload writes `action` from `Context.Action.Name`,
// so it needs the structure form that mol_Broker.Call builds, while FromPayload assigns the payload's
// `action` string straight to `Context.Action`. The pair is therefore not symmetric, and that asymmetry is
// the first thing these tests pin.
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
		.ДобавитьСерверныйТест("ToPayloadEmitsTheEventFieldSetWithoutMeta")
		.ДобавитьСерверныйТест("ToPayloadRefusesAContextWithNeitherActionNorEvent")
		.ДобавитьСерверныйТест("FromPayloadReadsLowerCaseKeys")
		.ДобавитьСерверныйТест("FromPayloadKeepsEveryFieldOfTheGoldenPayload")
		.ДобавитьСерверныйТест("AnInboundContextCannotBeSerialisedBackToAPayload");

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

Procedure ToPayloadEmitsTheEventFieldSetWithoutMeta() Export

	// mol_ContextFactory.ToPayload — the event direction. It has its own field set, and the difference is
	// the reason the acceptance calls it out: an event payload carries no `meta`.
	Context = OutboundContext();
	Context.EventName   = "probe.event";
	Context.EventGroups = Новый Массив;
	Context.NeedAck     = Ложь;

	Payload = mol_ContextFactory.ToPayload(Context);

	Declared = СтрРазделить("id,event,params,groups,broadcast,locals,level,tracing,parentID,requestID,caller,needAck", ",");
	ЮТест.ОжидаетЧто(Payload.Количество(), "an event payload carries twelve fields").Равно(Declared.Количество());

	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Payload.Property(Name), "the event payload declares " + Name).ЭтоИстина();
	EndDo;

	ЮТест.ОжидаетЧто(Payload.Property("meta"), "an event payload carries no meta").ЭтоЛожь();
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

	ЮТест.ОжидаетЧто(Context.Action, "the action name is read from the payload").Равно("probe.caseSensitive");
	ЮТест.ОжидаетЧто(Context.Id, "the identifier is read").Равно("probe-1");
	ЮТест.ОжидаетЧто(Context.Level, "the level is read").Равно(1);

EndProcedure

Procedure FromPayloadKeepsEveryFieldOfTheGoldenPayload() Export

	// mol_ContextFactory.FromPayload — the fixture the HTTP integration test sends, so a failure here and a
	// failure there mean the same thing rather than two different descriptions of the wire.
	Context = mol_ContextFactory.FromPayload(NewActionPayload("probe.notRegistered"));

	ЮТест.ОжидаетЧто(Context.Action, "the action survives").Равно("probe.notRegistered");
	ЮТест.ОжидаетЧто(Context.Id, "the identifier survives").Равно("probe-1");
	ЮТест.ОжидаетЧто(Context.RequestID, "the request identifier survives").Равно("probe-1");
	ЮТест.ОжидаетЧто(Context.Caller, "the caller survives").Равно("probe");
	ЮТест.ОжидаетЧто(Context.Level, "the level survives").Равно(1);
	ЮТест.ОжидаетЧто(Context.Tracing, "the tracing flag survives").Равно(Ложь);
	ЮТест.ОжидаетЧто(Context.ParentID, "the parent identifier survives").Равно(0);

EndProcedure

Procedure AnInboundContextCannotBeSerialisedBackToAPayload() Export

	// CURRENT BEHAVIOUR, pinned deliberately, and the first finding of this suite.
	//
	// FromPayload stores the payload's `action` string in Context.Action, but ToPayload reads
	// Context.Action.Name, which only the outbound structure form has. So an inbound context cannot be
	// turned back into a payload: the round-trip raises "field not found (Name)". Forwarding a received
	// request to another node is exactly what that would be needed for.
	//
	// When the two directions agree on one shape this test must be rewritten to assert the round-trip,
	// not deleted.
	Context = mol_ContextFactory.FromPayload(NewActionPayload("probe.roundTrip"));

	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_ContextFactory.ToPayload(Context);
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "CURRENT BEHAVIOUR: an inbound context cannot be re-serialised: " + Failure).ЭтоИстина();

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

#EndRegion
