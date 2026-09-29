// Behavioural tests for the ambient-context lifecycle.
//
// Mechanism under test: the ambient context is a named stack held by mol_Helpers. PushToStack and
// PopFromStack are its primitives; mol_ContextFactory.GetCurrentContext reads the top and
// SetCurrentContext pushes onto it. The lifecycle spans three modules, which is why this suite is
// named for the lifecycle rather than for any one of them:
//
//   mol_ContextFactory.Handler  pushes the incoming context and pops it again   (balanced)
//   mol_Broker.Call/Emit/Broadcast  call SetCurrentContext, which pushes only   (push without pop)
//   mol_Errors                  pushes the raised error and never pops          (push without pop)
//
// Mode note: canonical only. The standalone variant merges mol_ContextFactory, mol_Broker and
// mol_Errors into Moleculer.
//
// What is reachable here and what is not: the broker publishes its context *after* the transport
// answers, so no sidecar means the push itself cannot be reached. What is reachable is everything
// around it, and the error stack's staleness, which is triggered by a raise and therefore does not
// need a sidecar. The push-without-pop sites in mol_Broker are recorded in the task instead.
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
		.ДобавитьСерверныйТест("TheAmbientErrorOutlivesTheOperationThatRaisedIt");

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

	// A call that never reaches a sidecar must not disturb what was ambient, because the broker
	// publishes its own context only after the transport answers. Nothing pops here either, so a
	// failure that published would leave the stack permanently longer.
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

Procedure TheAmbientErrorOutlivesTheOperationThatRaisedIt() Export

	// Current behaviour, pinned deliberately. Raising pushes the error onto the ambient stack and
	// nothing pops it, so a later successful operation still reads the previous failure. This is the
	// staleness the acceptance asks to expose, and the reachable half of the push-without-pop pattern
	// the broker and mol_Errors share.
	//
	// When the lifecycle is fixed this test must be rewritten to assert the opposite, not deleted.
	Попытка
		Moleculer.RaiseCustomError("Error", "context probe");
	Исключение
		// Expected: the raise is how the error becomes ambient.
	КонецПопытки;

	AfterTheRaise = Moleculer.GetCurrentError();

	// An unrelated operation that succeeds and raises nothing.
	Unrelated = mol_Broker.GenerateUid();

	AfterAnUnrelatedSuccess = Moleculer.GetCurrentError();

	ЮТест.ОжидаетЧто(AfterTheRaise = Неопределено, "raising publishes an ambient error").ЭтоЛожь();
	ЮТест.ОжидаетЧто(AfterAnUnrelatedSuccess = AfterTheRaise,
		"CURRENT BEHAVIOUR: the ambient error survives an unrelated successful operation").ЭтоИстина();
	ЮТест.ОжидаетЧто(Unrelated <> Неопределено, "the unrelated operation really did succeed").ЭтоИстина();

EndProcedure

#EndRegion
