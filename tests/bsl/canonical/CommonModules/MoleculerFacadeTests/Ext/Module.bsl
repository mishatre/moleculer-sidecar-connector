// Behavioural tests for the Moleculer facade in extension mode.
//
// Mode note: this suite runs against the canonical extension, where Moleculer is a thin facade over
// mol_Broker, mol_Errors and mol_ContextFactory, the mol_* catalogs still exist, and mol_Helpers is a
// separate module. The standalone variant merges all of those into Moleculer and drops the catalogs
// and the enum, so the catalogue-backed and enum-backed expectations here would not hold there; that
// variant is covered by tests/bsl/standalone.
//
// The helper predicates therefore come from mol_Helpers and not from Moleculer, whose IsString and
// IsArray exist only in the standalone build.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Moleculer facade")
		.ДобавитьСерверныйТест("NewConfigParamsDeclaresTheDocumentedSettings")
		.ДобавитьСерверныйТест("NewConnectionParamsDeclaresTheDocumentedFields")
		.ДобавитьСерверныйТест("NewPublicationParamsDeclaresTheDocumentedFields")
		.ДобавитьСерверныйТест("AuthParamsMatchTheDeclaredAuthType")
		.ДобавитьСерверныйТест("AnUnknownAuthTypeIsRefused")
		.ДобавитьСерверныйТест("AuthTypesResolveToTheEnumInCanonicalMode")
		.ДобавитьСерверныйТест("NamespaceMatchesTheConfiguration")
		.ДобавитьСерверныйТест("CallRefusesAnOptsConnectionWithItsOwnMessage")
		.ДобавитьСерверныйТест("RaiseCustomErrorRaisesWithTheGivenMessage")
		.ДобавитьСерверныйТест("AdaptConnectionParamsPassesThroughUndefinedAndObjects")
		.ДобавитьСерверныйТест("AdaptConnectionParamsRefusesAnUnknownIdentifier")
		.ДобавитьСерверныйТест("ProviderConnectionsMatchTheDeclaredStructure")
		.ДобавитьСерверныйТест("BrokerIsAvailable");

EndProcedure

Procedure NewConfigParamsDeclaresTheDocumentedSettings() Export

	// The constructors define the settings contract: every consumer fills these keys in, and the
	// catalog-backed and standalone providers both write into the same shape.
	Params = Moleculer.NewConfigParams();

	ЮТест.ОжидаетЧто(Params.Количество(), "the settings structure declares ten keys").Равно(10);

	Declared = СтрРазделить("UUID,NodeID,Name,Caption,Namespace,ModulePrefix,LogLevel,ExtVersion,ExtAdminRole,LaunchParameters", ",");
	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Params.Property(Name), "the settings structure declares " + Name).ЭтоИстина();
	EndDo;

	ЮТест.ОжидаетЧто(Params.LaunchParameters.Property("Enable"), "launch parameters declare Enable").ЭтоИстина();
	ЮТест.ОжидаетЧто(Params.LaunchParameters.Property("SkipRolesCheck"), "launch parameters declare SkipRolesCheck").ЭтоИстина();

EndProcedure

Procedure NewConnectionParamsDeclaresTheDocumentedFields() Export

	Params = Moleculer.NewConnectionParams();

	ЮТест.ОжидаетЧто(Params.Количество(), "the connection structure declares eleven keys").Равно(11);

	Declared = СтрРазделить("Id,Description,Default,Type,Endpoint,Port,UseSSL,AccessKey,SecretKey,Timeout,Proxy", ",");
	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Params.Property(Name), "the connection structure declares " + Name).ЭтоИстина();
	EndDo;

EndProcedure

Procedure NewPublicationParamsDeclaresTheDocumentedFields() Export

	Params = Moleculer.NewPublicationParams();

	ЮТест.ОжидаетЧто(Params.Количество(), "the publication structure declares eight keys").Равно(8);

	Declared = СтрРазделить("id,description,endpoint,port,useSSL,path,auth,connection", ",");
	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Params.Property(Name), "the publication structure declares " + Name).ЭтоИстина();
	EndDo;

EndProcedure

Procedure AuthParamsMatchTheDeclaredAuthType() Export

	AuthTypes = Moleculer.AuthTypes();

	TokenParams = Moleculer.NewPublicationAuthParams(AuthTypes.UsingAccessToken);
	ЮТест.ОжидаетЧто(TokenParams.Количество(), "a token publication keeps only the token").Равно(1);
	ЮТест.ОжидаетЧто(TokenParams.Property("token"), "the token field is declared").ЭтоИстина();

	PasswordParams = Moleculer.NewPublicationAuthParams(AuthTypes.UsingPassword);
	ЮТест.ОжидаетЧто(PasswordParams.Количество(), "a password publication keeps both credentials").Равно(2);
	ЮТест.ОжидаетЧто(PasswordParams.Property("username"), "the username field is declared").ЭтоИстина();
	ЮТест.ОжидаетЧто(PasswordParams.Property("password"), "the password field is declared").ЭтоИстина();

	NoAuthParams = Moleculer.NewPublicationAuthParams(AuthTypes.NoAuth);
	ЮТест.ОжидаетЧто(NoAuthParams = Неопределено, "a no-auth publication carries no auth parameters").ЭтоИстина();

EndProcedure

Procedure AnUnknownAuthTypeIsRefused() Export

	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.NewPublicationAuthParams("not-an-auth-type");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	// Silently returning a structure for an unknown type would hand the caller credentials it never
	// asked for, so the refusal is the contract.
	ЮТест.ОжидаетЧто(Raised, "an unknown auth type is refused").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "Unknown auth type") > 0, "the failure names the cause: " + Failure).ЭтоИстина();

EndProcedure

Procedure AuthTypesResolveToTheEnumInCanonicalMode() Export

	// Canonical mode reads the predefined enum values, which is what the catalogs store; standalone
	// mode has no enum and falls back to strings.
	AuthTypes = Moleculer.AuthTypes();

	ЮТест.ОжидаетЧто(AuthTypes.UsingAccessToken = Неопределено, "the token type resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(AuthTypes.UsingPassword = Неопределено, "the password type resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(AuthTypes.NoAuth = Неопределено, "the no-auth type resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(AuthTypes.UsingAccessToken <> AuthTypes.UsingPassword, "the auth types are distinct").ЭтоИстина();

EndProcedure

Procedure NamespaceMatchesTheConfiguration() Export

	ЮТест.ОжидаетЧто(Moleculer.Namespace(), "Namespace() reads the configuration").Равно(Moleculer.GetConfig(Истина).Namespace);

EndProcedure

Procedure CallRefusesAnOptsConnectionWithItsOwnMessage() Export

	// The facade is the entry point that must not accept a connection, because the broker owns it.
	// The guard runs before any packet is built, so this needs no sidecar.
	Opts = Новый Структура;
	Opts.Insert("Connection", "some-connection");

	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.Call("probe.noHandler", Новый Структура, Opts);
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "Call refuses Opts.Connection instead of using it").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "Opts.Connection") > 0, "the failure names the rejected option: " + Failure).ЭтоИстина();

EndProcedure

Procedure RaiseCustomErrorRaisesWithTheGivenMessage() Export

	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.RaiseCustomError("Error", "facade probe");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "RaiseCustomError raises").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "facade probe") > 0, "the message reaches the caller: " + Failure).ЭтоИстина();

EndProcedure

Procedure AdaptConnectionParamsPassesThroughUndefinedAndObjects() Export

	ЮТест.ОжидаетЧто(Moleculer.AdaptConnectionParams(Неопределено) = Неопределено, "an absent connection stays absent").ЭтоИстина();

	Source = Moleculer.NewConnectionParams();
	Source.Id = "probe";

	Adapted = Moleculer.AdaptConnectionParams(Source);
	ЮТест.ОжидаетЧто(Adapted.Id, "a prepared structure is passed through").Равно("probe");

EndProcedure

Procedure AdaptConnectionParamsRefusesAnUnknownIdentifier() Export

	// Canonical mode resolves an identifier through the connections the provider declares. An
	// identifier that matches nothing must be reported rather than silently replaced by Undefined,
	// which would send the socket somewhere arbitrary.
	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.AdaptConnectionParams("no-such-connection-identifier");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "an unknown identifier is refused").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "no-such-connection-identifier") > 0, "the failure names the identifier: " + Failure).ЭтоИстина();

EndProcedure

Procedure ProviderConnectionsMatchTheDeclaredStructure() Export

	Connections = Moleculer.GetConnections(Истина);

	// The count is part of the message because the body below is vacuous while the catalog is empty,
	// which is the state of the test base. That is recorded rather than hidden.
	ЮТест.ОжидаетЧто(mol_Helpers.IsArray(Connections), "the provider returns an array; declared: " + Строка(Connections.Количество())).ЭтоИстина();

	For Each Connection In Connections Do
		ЮТест.ОжидаетЧто(Connection.Property("Id"), "a declared connection identifies itself").ЭтоИстина();
		ЮТест.ОжидаетЧто(Connection.Property("Endpoint"), "a declared connection names an endpoint").ЭтоИстина();
	EndDo;

EndProcedure

Procedure BrokerIsAvailable() Export

	ЮТест.ОжидаетЧто(Moleculer.Broker() = Неопределено, "the facade exposes the broker").ЭтоЛожь();

EndProcedure

#EndRegion
