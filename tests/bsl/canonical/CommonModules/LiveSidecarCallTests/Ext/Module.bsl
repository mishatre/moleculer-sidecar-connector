// Live tests: the connector talking to a real sidecar process.
//
// Mode note: canonical only, and these tests need a sidecar — the one built as
// `build/sidecar/moleculer-sidecar-linux-x64`, reachable on the loopback address, with an access key
// pair. The connection is supplied through `Opts.Connection`, which `mol_Broker.Call` honours, so
// nothing in the infobase, the catalog or the provider has to be touched and no credential is stored
// in a tracked file. The fixture is `build/test/sidecar-connection.json`, written by the operator:
//
//   {"id": "live-sidecar", "endpoint": "127.0.0.1", "port": 5103,
//    "accessKey": "...", "secretKey": "..."}
//
// When the fixture is absent the suite reports that in the run log and asserts nothing, so an
// environment without a sidecar still runs green instead of failing on infrastructure it was never
// promised. What it covers when the fixture is present is the part of the connector that cannot be
// faked: the whole outbound path — packet, SigV4 signature, HTTP call, response handling — against the
// service that actually verifies the signature.
//
// Why it exists: T020's remaining items and T030's proof both needed a call that *completes*, which is
// the only way to reach the code the broker runs after the transport answers.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Live sidecar")
		.ДобавитьСерверныйТест("TheSidecarAnswersThroughTheBroker")
		.ДобавитьСерверныйТест("TheSuccessPathRestoresSafeMode")
		.ДобавитьСерверныйТест("TheBrokerLeavesItsContextOnTheAmbientStack");

EndProcedure

Procedure TheSidecarAnswersThroughTheBroker() Export

	// mol_Broker.Call → mol_Transport.ExecuteRequest → the sidecar's own $sidecar.utils.parseYAML.
	// A successful answer proves four links at once: the payload the connector builds is one the sidecar
	// accepts, the SigV4 signature is what $sidecar.auth verifies, the HTTP envelope is right, and the
	// response is read back into a BSL value.
	If Not LiveSidecarAvailable() Then
		Return;
	EndIf;

	Response = mol_Broker.Call("$sidecar.utils.parseYAML",
		Новый Структура("string", "probe: ok"),
		Новый Структура("Connection", LiveConnection()));

	ЮТест.ОжидаетЧто(ТипЗнч(Response), "the sidecar answers with structured data: " + Строка(Response))
		.Равно(Тип("Структура"));
	ЮТест.ОжидаетЧто(Response.probe, "the parsed document comes back").Равно("ok");

EndProcedure

Procedure TheSuccessPathRestoresSafeMode() Export

	// mol_Transport.Send — the success half of the safe-mode contract. The failure path is covered in
	// mol_TransportTests against a closed port; this is the path that only a real answer reaches, and it
	// is the reason T020 listed it as outstanding.
	If Not LiveSidecarAvailable() Then
		Return;
	EndIf;

	Before = ПолучитьОтключениеБезопасногоРежима();

	mol_Broker.Call("$sidecar.utils.parseYAML",
		Новый Структура("string", "probe: ok"),
		Новый Структура("Connection", LiveConnection()));

	ЮТест.ОжидаетЧто(ПолучитьОтключениеБезопасногоРежима(),
		"a completed call must leave safe mode as it found it").Равно(Before);

EndProcedure

Procedure TheBrokerLeavesItsContextOnTheAmbientStack() Export

	// CURRENT BEHAVIOUR, pinned deliberately, and the runtime half of T030.
	//
	// mol_Broker.Call publishes its context with mol_ContextFactory.SetCurrentContext after the transport
	// answers, and SetCurrentContext only pushes. Nothing pops it. So after one successful call the
	// ambient stack holds a context nobody will remove — and it sits on top of whatever was there, which
	// is what a sentinel shows here. The earlier reading of the sources could only assert that the push
	// exists; with a real sidecar the call completes and the imbalance is observable.
	//
	// When the stack is made symmetric this test must be rewritten to assert the sentinel is current
	// again, not deleted.
	If Not LiveSidecarAvailable() Then
		Return;
	EndIf;

	Sentinel = Новый Структура("id", "ambient-sentinel");
	mol_ContextFactory.SetCurrentContext(Sentinel);

	mol_Broker.Call("$sidecar.utils.parseYAML",
		Новый Структура("string", "probe: ok"),
		Новый Структура("Connection", LiveConnection()));

	Current = mol_ContextFactory.GetCurrentContext();

	ЮТест.ОжидаетЧто(Current <> Sentinel,
		"CURRENT BEHAVIOUR: the call pushed a context and did not pop it").ЭтоИстина();
	ЮТест.ОжидаетЧто(Current.Action.Name,
		"and what it left there is the context of that call").Равно("$sidecar.utils.parseYAML");

EndProcedure

#EndRegion

#Region Private

// The live connection, or Undefined with a note in the run log. The fixture is untracked and written by
// the operator, so its absence is a configuration fact rather than a test failure.
Function LiveSidecarAvailable()

	FilePath = "/workspace/build/test/sidecar-connection.json";
	FileInfo = Новый Файл(FilePath);
	Available = FileInfo.Существует();

	If Not Available Then
		Сообщить("live sidecar tests skipped: " + FilePath + " is absent."
			+ " Start build/sidecar/moleculer-sidecar-linux-x64 and write the fixture to run them.");
	EndIf;

	Return Available;

EndFunction

// The connection the transport expects, read from the fixture. Its field set matches the one the broker
// publishes: mol_Transport reads Endpoint, Port, UseSSL, AccessKey and SecretKey, and
// mol_Helpers.GetCachedHTTPConnection reads the rest.
Function LiveConnection()

	Reader = Новый ЧтениеJSON;
	Reader.ОткрытьФайл(LiveSidecarPath());
	Settings = ПрочитатьJSON(Reader);
	Reader.Закрыть();

	Result = Новый Структура;
	Result.Insert("Id"         , Settings.id);
	Result.Insert("Description", "live sidecar");
	Result.Insert("Default"    , Истина);
	Result.Insert("Type"       , "HTTP");
	Result.Insert("Endpoint"   , Settings.endpoint);
	Result.Insert("Port"       , Settings.port);
	Result.Insert("UseSSL"     , Ложь);
	Result.Insert("AccessKey"  , Settings.accessKey);
	Result.Insert("SecretKey"  , Settings.secretKey);
	Result.Insert("Timeout"    , 10);
	Result.Insert("Proxy"      , Неопределено);

	Return Result;

EndFunction

// The path of the operator-written fixture.
Function LiveSidecarPath()

	Return "/workspace/build/test/sidecar-connection.json";

EndFunction

#EndRegion
