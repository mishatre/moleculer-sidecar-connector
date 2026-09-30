// Behavioural tests for how a context gets its fields.
//
// Source functions exercised: mol_ContextFactory.SetEndpoint, mol_ContextFactory.SetParams,
// mol_ContextFactory.FromPayload and mol_ContextFactory.Call. Each test names the one it holds to account.
//
// Why these: the acceptance asks for the payload conversion "including field casing" and for nested-call
// handling, which are the two places where a context's fields are decided by something other than the
// caller. SetEndpoint resolves a whole action or event from an endpoint description, and the conversion
// has to accept the wire's lower-case keys while a BSL-built fixture spells them however it likes.
//
// Mode note: canonical only. The standalone variant merges mol_ContextFactory into Moleculer.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Context fields")
		.ДобавитьСерверныйТест("SetEndpointResolvesAnActionEndpoint")
		.ДобавитьСерверныйТест("SetEndpointResolvesAnEventEndpoint")
		.ДобавитьСерверныйТест("SetEndpointStoresANonStructureWithoutDerivingFromIt")
		.ДобавитьСерверныйТест("SetParamsCarriesTheParametersThrough")
		.ДобавитьСерверныйТест("FromPayloadAcceptsItsKeysRegardlessOfCase")
		.ДобавитьСерверныйТест("TheContextFactoryThreadsItsParentIntoTheNewContext");

EndProcedure

Procedure SetEndpointResolvesAnActionEndpoint() Export

	// mol_ContextFactory.SetEndpoint — an endpoint description carries the node and a whole action, and the
	// context is expected to take its service from that action while clearing any event.
	Context  = NewContextFields();
	Endpoint = NewEndpoint("probe.action", "probe.service");

	mol_ContextFactory.SetEndpoint(Context, Endpoint);

	ЮТест.ОжидаетЧто(Context.NodeID, "the node identifier comes from the endpoint").Равно("node-1");
	ЮТест.ОжидаетЧто(Context.Action, "the action comes from the endpoint").Равно(Endpoint.Action);
	ЮТест.ОжидаетЧто(Context.Service, "the service is taken from the action").Равно("probe.service");
	ЮТест.ОжидаетЧто(Context.Event = Неопределено, "an action endpoint leaves no event behind").ЭтоИстина();

EndProcedure

Procedure SetEndpointResolvesAnEventEndpoint() Export

	// The mirror of the action case, and the reason both are asserted: the resolution has to depend on which
	// shape the endpoint carries rather than on the order the fields happen to be checked in.
	Context  = NewContextFields();
	Endpoint = NewEndpoint(Неопределено, "probe.service");

	mol_ContextFactory.SetEndpoint(Context, Endpoint);

	ЮТест.ОжидаетЧто(Context.Event, "the event comes from the endpoint").Равно(Endpoint.Event);
	ЮТест.ОжидаетЧто(Context.Service, "the service is taken from the event").Равно("probe.service");
	ЮТест.ОжидаетЧто(Context.Action = Неопределено, "an event endpoint leaves no action behind").ЭтоИстина();

EndProcedure

Procedure SetEndpointStoresANonStructureWithoutDerivingFromIt() Export

	// mol_ContextFactory.SetEndpoint — an endpoint that is not a structure carries no fields to derive, so
	// only the endpoint itself is stored. A caller reading NodeID afterwards gets nothing rather than a
	// partially filled context.
	Context = Новый Структура("NodeID, Action, Event, Service, Endpoint");

	mol_ContextFactory.SetEndpoint(Context, "probe://endpoint");

	ЮТест.ОжидаетЧто(Context.Endpoint, "the endpoint is stored as given").Равно("probe://endpoint");
	ЮТест.ОжидаетЧто(Context.NodeID = Неопределено, "nothing else is derived from it").ЭтоИстина();

EndProcedure

Procedure SetParamsCarriesTheParametersThrough() Export

	// mol_ContextFactory.SetParams — the parameters become the context's own, and an absent argument leaves
	// what is already there alone rather than clearing it.
	Context = Новый Структура("Params");
	Params  = Новый Структура("probeParameter", "probe value");

	mol_ContextFactory.SetParams(Context, Params);
	ЮТест.ОжидаетЧто(Context.Params.probeParameter, "the parameters are carried through").Равно("probe value");

	mol_ContextFactory.SetParams(Context, Неопределено);
	ЮТест.ОжидаетЧто(Context.Params.probeParameter, "an absent argument leaves them alone").Равно("probe value");

EndProcedure

Procedure FromPayloadAcceptsItsKeysRegardlessOfCase() Export

	// mol_ContextFactory.FromPayload — the branch is chosen by Payload.Property("action"), which is
	// case-insensitive on a structure while the wire is lower case. A fixture built in BSL with title case
	// therefore takes the same branch, which is what keeps hand-built and deserialised packets
	// interchangeable.
	Payload = Новый Структура;
	Payload.Insert("Id"       , "probe-1");
	Payload.Insert("Action"   , "probe.titleCase");
	Payload.Insert("Params"   , Новый Структура);
	Payload.Insert("Meta"     , Новый Соответствие);
	Payload.Insert("Locals"   , Новый Структура);
	Payload.Insert("Level"    , 1);
	Payload.Insert("Tracing"  , Ложь);
	Payload.Insert("ParentID" , 0);
	Payload.Insert("RequestID", "probe-1");
	Payload.Insert("Caller"   , "probe");

	Context = mol_ContextFactory.FromPayload(Payload);

	ЮТест.ОжидаетЧто(Context.Action.Name, "a title-case key selects the action branch").Равно("probe.titleCase");

EndProcedure

Procedure TheContextFactoryThreadsItsParentIntoTheNewContext() Export

	// mol_ContextFactory.Call + mol_ContextFactory.Create — the nested-call mechanism, and a correction.
	//
	// This test used to assert that nothing reads the `parentCtx` the factory threads in, and to say so in
	// its name. That was wrong: a case-sensitive search missed `Opts.ParentCtx` in `Create`, and BSL
	// structure keys do not care about case. `Create` derives requestID, meta, tracing, level + 1, parentID
	// and caller from the parent exactly as Moleculer's `ContextFactory.create` does (`context.js`), and the
	// broker builds its context through `Create`, so the chain works.
	//
	// The threading half: Call puts the ambient context into the options before handing them to the broker.
	Sentinel = Новый Структура("id", "parent-sentinel");
	mol_ContextFactory.SetCurrentContext(Sentinel);

	Opts = Новый Структура;
	Попытка
		mol_ContextFactory.Call("probe.nested", Новый Структура, Opts);
	Исключение
		// Expected: no sidecar is reachable.
	КонецПопытки;

	ЮТест.ОжидаетЧто(Opts.Property("parentCtx"), "the ambient context is threaded into the options").ЭтоИстина();
	ЮТест.ОжидаетЧто(Opts.parentCtx.id, "and it is the ambient one").Равно("parent-sentinel");

	// The derivation half. Create is what the broker calls, so this is the observable end of the chain.
	ParentMeta = Новый Соответствие;
	ParentMeta.Вставить("tenant", "acme");

	Parent = Новый Структура;
	Parent.Insert("id"       , "parent-1");
	Parent.Insert("requestID", "trace-1");
	Parent.Insert("tracing"  , Истина);
	Parent.Insert("level"    , 3);
	Parent.Insert("meta"     , ParentMeta);

	Derived = mol_ContextFactory.Create(mol_Broker, Новый Структура, Новый Структура("parentCtx", Parent));

	ЮТест.ОжидаетЧто(Derived.Level, "the child sits one level deeper").Равно(4);
	ЮТест.ОжидаетЧто(Derived.RequestID, "the request identifier is inherited").Равно("trace-1");
	ЮТест.ОжидаетЧто(Derived.Tracing, "the tracing flag is inherited").ЭтоИстина();
	ЮТест.ОжидаетЧто(Derived.ParentID, "the parent identifier is the parent's own").Равно("parent-1");
	ЮТест.ОжидаетЧто(Derived.Meta.Получить("tenant"), "the parent's meta is merged").Равно("acme");

EndProcedure

// The fields SetEndpoint writes, declared up front because a structure does not grow on assignment.
Function NewContextFields()

	Return Новый Структура("NodeID, Action, Event, Service, Endpoint");

EndFunction

// An endpoint description carrying either an action or an event, shaped the way the broker's discovery
// fills it.
Function NewEndpoint(ActionName, ServiceName)

	Endpoint = Новый Структура;
	Endpoint.Insert("Id", "node-1");

	If ActionName = Неопределено Then
		Endpoint.Insert("Action", Неопределено);
		Endpoint.Insert("Event" , Новый Структура("Name, Service", "probe.event", ServiceName));
	Else
		Endpoint.Insert("Action", Новый Структура("Name, Service", ActionName, ServiceName));
		Endpoint.Insert("Event" , Неопределено);
	EndIf;

	Return Endpoint;

EndFunction

#EndRegion
