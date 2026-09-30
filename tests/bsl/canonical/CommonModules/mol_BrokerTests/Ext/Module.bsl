// Behavioural tests for mol_Broker — the module that routes calls and events.
//
// The interesting parts of the broker end in a transport attempt, so this suite covers what is
// reachable without a sidecar: the identifier generation the packet envelope depends on, the node
// identifier, the publication guard's argument mutation, and how far each entry point gets before the
// transport refuses. Payload field construction itself lives in mol_Transport and belongs to the
// transport suite.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Broker")
		.ДобавитьСерверныйТест("GenerateUidReturnsAValue")
		.ДобавитьСерверныйТест("GenerateUidIsUniquePerCall")
		.ДобавитьСерверныйТест("NodeIDComesFromTheConfiguration")
		.ДобавитьСерверныйТест("CallReportsAnUnreachableSidecar")
		.ДобавитьСерверныйТест("EmitWithoutOptionsReachesTheTransport")
		.ДобавитьСерверныйТест("EmitWithAGroupStringReachesTheTransport")
		.ДобавитьСерверныйТест("BroadcastWithoutOptionsReachesTheTransport")
		.ДобавитьСерверныйТест("BroadcastWithAGroupStringReachesTheTransport")
		.ДобавитьСерверныйТест("GetPublicationValidationCodeRemovesTheConnectionFromItsArgument")
		.ДобавитьСерверныйТест("TheInternalResolverFindsAnInternalAction")
		.ДобавитьСерверныйТест("TheInternalResolverRefusesAnActionItDoesNotHave")
		.ДобавитьСерверныйТест("TheInternalServiceSchemaIsKeyedByTheBareActionName");

EndProcedure

// NewPacket stamps every outgoing packet with an identifier, so the generator has to keep
// producing usable values.
Procedure GenerateUidReturnsAValue() Export

	Uid = mol_Broker.GenerateUid();

	ЮТест.ОжидаетЧто(Uid, "a generated identifier must not be empty").Заполнено();

EndProcedure

Procedure GenerateUidIsUniquePerCall() Export

	First = mol_Broker.GenerateUid();
	Second = mol_Broker.GenerateUid();

	ЮТест.ОжидаетЧто(First, "two calls must not produce the same identifier")
		.НеРавно(Second);

EndProcedure

Procedure NodeIDComesFromTheConfiguration() Export

	// The node identifier travels in every packet, so it must come from the configuration rather
	// than from a fresh identifier per call.
	ЮТест.ОжидаетЧто(mol_Broker.NodeID(), "the node identifier comes from the configuration")
		.Равно(Moleculer.GetConfig(Истина).NodeID);
	ЮТест.ОжидаетЧто(mol_Broker.NodeID(), "the node identifier is not empty").Заполнено();

EndProcedure

Procedure CallReportsAnUnreachableSidecar() Export

	// No sidecar runs during the suite. The entry point has to report that, rather than returning an
	// empty result that the caller would read as a successful call with no data.
	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_Broker.Call("probe.noHandler", Новый Структура);
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "a call without a sidecar raises").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "sidecar") > 0, "the refusal names the sidecar: " + Failure).ЭтоИстина();

EndProcedure

Procedure EmitWithoutOptionsReachesTheTransport() Export

	// Emit documents its options as optional, so this path must normalise them and reach the
	// transport. The refusal naming the sidecar is the evidence, because a failure that named a
	// missing option field instead would mean normalisation broke first.
	Failure = TransportRefusal(Истина, Неопределено);

	ЮТест.ОжидаетЧто(СтрНайти(Failure, "sidecar") > 0, "emitting without options reaches the transport: " + Failure).ЭтоИстина();

EndProcedure

Procedure EmitWithAGroupStringReachesTheTransport() Export

	// The documented signature accepts a bare string as the group, which has to be wrapped before the
	// context is built.
	Failure = TransportRefusal(Истина, "probe-group");

	ЮТест.ОжидаетЧто(СтрНайти(Failure, "sidecar") > 0, "emitting to one group reaches the transport: " + Failure).ЭтоИстина();

EndProcedure

Procedure BroadcastWithoutOptionsReachesTheTransport() Export

	Failure = TransportRefusal(Ложь, Неопределено);

	ЮТест.ОжидаетЧто(СтрНайти(Failure, "sidecar") > 0, "broadcasting without options reaches the transport: " + Failure).ЭтоИстина();

EndProcedure

Procedure BroadcastWithAGroupStringReachesTheTransport() Export

	Failure = TransportRefusal(Ложь, "probe-group");

	ЮТест.ОжидаетЧто(СтрНайти(Failure, "sidecar") > 0, "broadcasting to one group reaches the transport: " + Failure).ЭтоИстина();

EndProcedure

Procedure GetPublicationValidationCodeRemovesTheConnectionFromItsArgument() Export

	// The guard deletes the connection from the publication before sending it, and the acceptance
	// pins that mutation of the caller's argument. The call that follows needs a sidecar, so only the
	// mutation is asserted; the raise is expected and is not the subject here.
	Publication = Новый Структура;
	Publication.Insert("id", "probe");
	Publication.Insert("Connection", "probe-connection");

	Попытка
		mol_Broker.GetPublicationValidationCode(Publication);
	Исключение
		// Expected: the guard calls the sidecar, which is not running here.
	КонецПопытки;

	ЮТест.ОжидаетЧто(Publication.Property("Connection"), "the connection is removed from the argument").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Publication.Property("id"), "the remaining fields are left alone").ЭтоИстина();

EndProcedure

// Runs Emit or Broadcast with the given options and returns the resulting failure text, or an empty
// string when the call returned without error.
//
// The refusal that names the sidecar means execution reached the transport. Any other text means it
// did not, and returning the text rather than a flag keeps that cause in the report instead of hiding
// it behind a boolean.
Function TransportRefusal(IsEmit, Opts)

	Попытка
		Если IsEmit Then
			mol_Broker.Emit("probe.event", Новый Структура, Opts);
		Иначе
			mol_Broker.Broadcast("probe.event", Новый Структура, Opts);
		КонецЕсли;
		// A call that somehow succeeds still means execution reached the transport.
		Return "";
	Исключение
		Return ОписаниеОшибки();
	КонецПопытки;

EndFunction

Procedure TheInternalResolverFindsAnInternalAction() Export

	// mol_Broker.Delete_FindInternalHandler — the resolver the inbound transport consults for the
	// connector's own actions. It is exercised directly because the HTTP path hides which half fails: a
	// 503 from there is the same whether the resolver returned nothing or the caller mishandled what it
	// returned. This is the instrumentation T032 asks for.
	Handler = mol_Broker.Delete_FindInternalHandler("$internal.ping");

	ЮТест.ОжидаетЧто(Handler <> Неопределено,
		"the resolver finds the ping action of mol_Internal").ЭтоИстина();

	If Handler <> Неопределено Then
		ЮТест.ОжидаетЧто(СтрНайти(Строка(Handler), "PingAction") > 0,
			"the resolved handler is PingAction: " + Строка(Handler)).ЭтоИстина();
	EndIf;

EndProcedure

Procedure TheInternalResolverRefusesAnActionItDoesNotHave() Export

	// mol_Broker.Delete_FindInternalHandler — the negative case, so the positive one cannot pass by
	// returning something for every name it is given.
	ЮТест.ОжидаетЧто(mol_Broker.Delete_FindInternalHandler("$internal.noSuchAction") = Неопределено,
		"an action the schema does not declare resolves to nothing").ЭтоИстина();

EndProcedure

Procedure TheInternalServiceSchemaIsKeyedByTheBareActionName() Export

	// The resolver builds each candidate as `<fullName>.<key>`, so the keys of the schema's Actions map
	// decide whether `$internal.ping` can be found at all. This test exists to answer that with a run
	// rather than with another reading of the resolver, which is how T032's original claim went wrong.
	Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal");

	ЮТест.ОжидаетЧто(Schema.FullName, "the qualifier the resolver prepends").Равно("$internal");
	ЮТест.ОжидаетЧто(Schema.Actions.Get("ping") <> Неопределено,
		"the actions map is keyed by the bare action name").ЭтоИстина();

EndProcedure

#EndRegion
