// Behavioural tests for the ambient-context lifecycle.
//
// Mechanism under test: the ambient context and the ambient error are named stacks held by
// mol_Helpers. PushToStack and PopFromStack are their primitives; mol_ContextFactory.GetCurrentContext
// reads the context stack's top and SetCurrentContext pushes onto it. The lifecycle spans three
// modules, which is why this suite is named for the lifecycle rather than for any one of them. T030
// made every push symmetric:
//
//   mol_ContextFactory.Handler  pushes the incoming context and pops it in its tail, and pops the
//                               ambient error there too, so the operation ends with neither
//   mol_Broker.Call/Emit/Broadcast  publish the outgoing context for the duration of the transport
//                               call and pop it again on both the success and the failure path
//   mol_Errors                  pushes the raised error so the Except that handles it can read the
//                               structured error back; PopCurrentError is its pop
//
// Mode note: canonical only. The standalone variant merges mol_ContextFactory, mol_Broker and
// mol_Errors into Moleculer.
//
// What is reachable here and what is not: the broker's publish and pop straddle the transport, so only
// a completed call can show that the pair is balanced, and that half lives in LiveSidecarCallTests.
// What is reachable without a sidecar is the handler boundary and the error stack.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Ambient context lifecycle")
		.ДобавитьСерверныйТест("SetCurrentContextPublishesTheAmbientContext")
		.ДобавитьСерверныйТест("AFailingCallLeavesTheAmbientContextAlone")
		.ДобавитьСерверныйТест("ANestedCallStampsTheActionIntoTheCallingContext")
		.ДобавитьСерверныйТест("TheAmbientErrorDoesNotOutliveTheOperationThatHandledIt");

EndProcedure

Procedure SetCurrentContextPublishesTheAmbientContext() Export

	// The contract the broker relies on: whatever is set last is what a reader sees. A marker
	// structure is used instead of a real context because the assertion is about what is published,
	// not about what a context contains.
	First = Новый Структура("id", "first");
	Second = Новый Структура("id", "second");

	mol_ContextFactory.SetCurrentContext(First);
	ЮТест.ОжидаетЧто(mol_ContextFactory.GetCurrentContext().id, "the first context is published").Равно("first");

	mol_ContextFactory.SetCurrentContext(Second);
	ЮТест.ОжидаетЧто(mol_ContextFactory.GetCurrentContext().id, "the newest context is published").Равно("second");

EndProcedure

Procedure AFailingCallLeavesTheAmbientContextAlone() Export

	// A call that never reaches a sidecar must not disturb what was ambient. The broker publishes its
	// context before the transport and pops it on both paths, so a failure restores the stack instead
	// of leaving one entry behind per attempt.
	Sentinel = Новый Структура("id", "sentinel");
	mol_ContextFactory.SetCurrentContext(Sentinel);

	Попытка
		mol_Broker.Call("probe.noHandler", Новый Структура);
	Исключение
		// Expected: no sidecar is reachable.
	КонецПопытки;

	ЮТест.ОжидаетЧто(mol_ContextFactory.GetCurrentContext().id,
		"a failed call does not republish the ambient context").Равно("sentinel");

EndProcedure

Procedure ANestedCallStampsTheActionIntoTheCallingContext() Export

	// A nested call is identified by Opts.Context: the broker writes the action name into the caller's
	// context instead of building a new one. That happens before the transport, so it is observable
	// even though the call itself cannot complete without a sidecar.
	Calling = Новый Структура;
	Calling.Insert("Action", Новый Структура);

	Opts = Новый Структура;
	Opts.Insert("Context", Calling);

	Попытка
		mol_Broker.Call("probe.nestedAction", Новый Структура, Opts);
	Исключение
		// Expected: no sidecar is reachable.
	КонецПопытки;

	ЮТест.ОжидаетЧто(Calling.Action.Property("name"), "the action name is stamped into the calling context").ЭтоИстина();
	ЮТест.ОжидаетЧто(Calling.Action.name, "the stamped name is the action that was called").Равно("probe.nestedAction");

EndProcedure

Procedure TheAmbientErrorDoesNotOutliveTheOperationThatHandledIt() Export

	// This test pinned the opposite until T030. Raising published the error and nothing removed it, so
	// an unrelated successful operation still read the previous failure; the old assertion said so and
	// asked to be flipped when the lifecycle changed.
	//
	// The raise still publishes the error, because that is how the Except that handles the exception
	// reads the structured error back. What changed is the pairing: mol_ContextFactory.Handler pops the
	// ambient error in its tail, next to the ambient context it already popped, so the error ends with
	// the operation that handled it.
	//
	// The comparison is against the error that was current before the raise rather than against
	// Undefined, because this suite runs in a session shared with every other suite, so an older error
	// may legitimately sit under this one. Restoring the previous top is the property being asserted.
	BeforeTheRaise = Moleculer.GetCurrentError();

	Попытка
		Moleculer.RaiseCustomError("Error", "context probe");
	Исключение
		// Expected: the raise is how the error becomes ambient.
	КонецПопытки;

	AfterTheRaise = Moleculer.GetCurrentError();

	// An unrelated operation that succeeds and raises nothing: the handler boundary is where an
	// operation's ambient error ends.
	Response = mol_ContextFactory.Handler(InboundContext("mol_Internal.PingAction"));

	AfterTheUnrelatedOperation = Moleculer.GetCurrentError();

	ЮТест.ОжидаетЧто(AfterTheRaise = Неопределено, "raising publishes an ambient error").ЭтоЛожь();
	ЮТест.ОжидаетЧто(AfterTheUnrelatedOperation = BeforeTheRaise,
		"the ambient error ends with the operation that handled it").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_Helpers.IsErrorResponse(Response), "the unrelated operation really did succeed").ЭтоЛожь();

EndProcedure

#EndRegion

#Region Private

// Builds the context mol_Transport.RequestHandler hands to mol_ContextFactory.Handler: a destination
// and a resolved handler. Only the keys Handler reads are populated, so a failure points at the
// contract rather than at a fixture that drifted.
Function InboundContext(HandlerName)

	Context = Новый Структура;
	Context.Insert("Action", "probe.action");
	Context.Insert("Event" , Неопределено);
	Context.Insert("Locals", Новый Структура("Handler", HandlerName));

	Return Context;

EndFunction

#EndRegion
