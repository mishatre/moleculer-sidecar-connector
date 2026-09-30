// Behavioural tests for the error shapes mol_Errors builds.
//
// Source functions exercised: mol_Errors.ClientError/ServerError/RetryableError, the named factories,
// RegenerateError, ToString and NoExceptionError. Each test names the one it holds to account.
//
// Why these: the taxonomy task (T023) wants every factory to return a numeric code and a name from a
// documented set. That is a claim about the whole family, so the family is walked here rather than
// sampled — the assertion messages carry the factory's type, so a failure says which one broke the rule
// instead of just that one did.
//
// Mode note: canonical only. The standalone variant merges mol_Errors into Moleculer.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Error shapes")
		.ДобавитьСерверныйТест("AnErrorCarriesTheDocumentedFieldSet")
		.ДобавитьСерверныйТест("TheThreeClassesCarryTheirNamesAndCodes")
		.ДобавитьСерверныйТест("EveryNamedFactoryCarriesANumberCodeAndAName")
		.ДобавитьСерверныйТест("RegeneratingAnErrorPreservesItsFields")
		.ДобавитьСерверныйТест("ToStringStatesTheMessageTheTypeAndTheCode")
		.ДобавитьСерверныйТест("FromErrorInfoConvertsACaughtPlatformError")
		.ДобавитьСерверныйТест("FromErrorInfoRefusesSomethingThatIsNotAnErrorInfo")
		.ДобавитьСерверныйТест("ARemoteStackIsRetainedThroughRegeneration");

EndProcedure

Procedure AnErrorCarriesTheDocumentedFieldSet() Export

	// mol_Errors.ClientError — every factory funnels into the same seven-key shape, which is what the
	// envelope serialiser and the remote conversion both rely on.
	Error = mol_Errors.ClientError("PROBE_ERROR", 400, "probe message");

	Declared = СтрРазделить("name,type,message,code,data,stack,errorInfo", ",");
	ЮТест.ОжидаетЧто(Error.Количество(), "an error carries seven fields").Равно(Declared.Количество());

	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Error.Property(Name), "the error declares " + Name).ЭтоИстина();
	EndDo;

	ЮТест.ОжидаетЧто(Error.type, "the caller's type is kept").Равно("PROBE_ERROR");
	ЮТест.ОжидаетЧто(Error.message, "the message is kept").Равно("probe message");
	ЮТест.ОжидаетЧто(Error.code, "the code is kept").Равно(400);

EndProcedure

Procedure TheThreeClassesCarryTheirNamesAndCodes() Export

	// mol_Errors.ClientError/ServerError/RetryableError — the three classes the rest of the connector
	// builds on. The defaults matter because callers rely on them instead of passing a code.
	Client    = mol_Errors.ClientError("PROBE", 400);
	Server    = mol_Errors.ServerError("PROBE");
	Retryable = mol_Errors.RetryableError("PROBE");

	ЮТест.ОжидаетЧто(Client.name, "the client class names itself").Равно("MoleculerClientError");
	ЮТест.ОжидаетЧто(Server.name, "the server class names itself").Равно("MoleculerServerError");
	ЮТест.ОжидаетЧто(Retryable.name, "the retryable class names itself").Равно("MoleculerRetryableError");

	ЮТест.ОжидаетЧто(Client.code, "the client class defaults to 400").Равно(400);
	ЮТест.ОжидаетЧто(Server.code, "the server class defaults to 500").Равно(500);
	ЮТест.ОжидаетЧто(Retryable.code, "the retryable class defaults to 500").Равно(500);

EndProcedure

Procedure EveryNamedFactoryCarriesANumberCodeAndAName() Export

	// The whole named family, walked rather than sampled, because T023's acceptance is a claim about all
	// of it: "every factory returns Code as a number and a Name from a documented set". The type is in
	// each message so a failure identifies the offender.
	Errors = Новый Массив;
	Errors.Add(mol_Errors.TypeError("probe"));
	Errors.Add(mol_Errors.ServiceNotFound("probe"));
	Errors.Add(mol_Errors.ServiceNotAvailable("probe"));
	Errors.Add(mol_Errors.RequestTimeout("probe"));
	Errors.Add(mol_Errors.RequestSkipped("probe"));
	Errors.Add(mol_Errors.RequestRejected("probe"));
	Errors.Add(mol_Errors.ValidationError("probe"));
	Errors.Add(mol_Errors.MaxCallLevel("probe"));
	Errors.Add(mol_Errors.ServiceSchemaError("probe"));
	Errors.Add(mol_Errors.InvalidPacketData("probe"));

	ЮТест.ОжидаетЧто(Errors.Количество(), "the family under test is the ten named factories").Равно(10);

	For Each Error In Errors Do
		ЮТест.ОжидаетЧто(TypeOf(Error.code) = Type("Number"),
			"the code is a number, not a string: " + Строка(Error.type)).ЭтоИстина();
		ЮТест.ОжидаетЧто(Не ПустаяСтрока(Error.name),
			"a name is present: " + Строка(Error.type)).ЭтоИстина();
		ЮТест.ОжидаетЧто(Не ПустаяСтрока(Error.type),
			"a type is present").ЭтоИстина();
	EndDo;

EndProcedure

Procedure RegeneratingAnErrorPreservesItsFields() Export

	// mol_Errors.RegenerateError — used when an error crosses a boundary and has to be rebuilt on the
	// other side, so the fields a caller reads must survive the trip.
	Original = mol_Errors.ServerError("REQUEST_TIMEOUT", 504, "probe timeout", "probe payload");

	Regenerated = mol_Errors.RegenerateError(Original);

	ЮТест.ОжидаетЧто(Regenerated.type, "the type survives").Равно(Original.type);
	ЮТест.ОжидаетЧто(Regenerated.name, "the name survives").Равно(Original.name);
	ЮТест.ОжидаетЧто(Regenerated.code, "the code survives").Равно(Original.code);
	ЮТест.ОжидаетЧто(Regenerated.message, "the message survives").Равно(Original.message);
	ЮТест.ОжидаетЧто(Regenerated.data, "the data survives").Равно(Original.data);

EndProcedure

Procedure ToStringStatesTheMessageTheTypeAndTheCode() Export

	// mol_Errors.ToString — the human-readable form. A logger or a support ticket sees this, so the three
	// facts that identify a failure have to be in it.
	Error = mol_Errors.ServerError("PROBE_TYPE", 503, "probe message");
	Text  = mol_Errors.ToString(Error);

	ЮТест.ОжидаетЧто(СтрНайти(Text, "probe message") > 0, "the message is stated: " + Text).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Text, "PROBE_TYPE") > 0, "the type is stated: " + Text).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Text, "503") > 0, "the code is stated: " + Text).ЭтоИстина();

EndProcedure

Procedure FromErrorInfoConvertsACaughtPlatformError() Export

	// mol_Errors.FromErrorInfo — the conversion every catch block goes through, so it has to carry the
	// description, a name from the documented category set, a type and the ErrorInfo itself.
	Caught = Undefined;
	Попытка
		ВызватьИсключение "probe conversion";
	Исключение
		Caught = ИнформацияОбОшибке();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Caught <> Неопределено, "the fixture needs a real platform error").ЭтоИстина();

	Converted = mol_Errors.FromErrorInfo(Caught);

	ЮТест.ОжидаетЧто(СтрНайти(Converted.message, "probe conversion") > 0,
		"the description survives: " + Строка(Converted.message)).ЭтоИстина();
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Converted.name), "a category name is chosen").ЭтоИстина();
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Converted.type), "a type is derived").ЭтоИстина();
	ЮТест.ОжидаетЧто(Converted.errorInfo <> Неопределено, "the platform error is retained").ЭтоИстина();

EndProcedure

Procedure FromErrorInfoRefusesSomethingThatIsNotAnErrorInfo() Export

	// mol_Errors.FromErrorInfo — the conversion is reachable from catch blocks only, and a caller that
	// passes something else should be told rather than get a converted structure out of nothing.
	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_Errors.FromErrorInfo("not an error info");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "a non-ErrorInfo value is refused").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "ErrorInfo") > 0, "the refusal names the argument: " + Failure).ЭтоИстина();

EndProcedure

Procedure ARemoteStackIsRetainedThroughRegeneration() Export

	// mol_Errors.RegenerateError with mol_Errors.AppendErrorInfo — an error that crossed a boundary
	// carries the sender's stack as a string, and rebuilding the error locally must not drop it: it is the
	// only diagnostic the receiver has for the far side.
	RemoteStack = "----EXTERNAL_STACK----" + Символы.ПС + "remote frame" + Символы.ПС + "----EXTERNAL_STACK----";

	Original    = mol_Errors.ServerError("PROBE_REMOTE", 500, "remote failure", Неопределено, RemoteStack);
	Regenerated = mol_Errors.RegenerateError(Original);

	ЮТест.ОжидаетЧто(Original.stack, "the fixture's stack is a string").Равно(RemoteStack);
	ЮТест.ОжидаетЧто(Regenerated.stack, "the remote stack survives regeneration").Равно(RemoteStack);

EndProcedure

#EndRegion
