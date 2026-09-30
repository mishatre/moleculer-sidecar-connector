// Runtime-contour tests for the standalone variant of the connector.
//
// Mode note: the standalone build drops Catalog.mol_Services and reads its deployment settings from
// the provider module MoleculerOverridable instead of from the mol_* catalogs and constants. These
// tests assert the consequences of that swap, so they belong in the standalone tree: the canonical
// extension has the catalog and would answer differently on purpose. This is the counterpart of the
// canonical suites, which address the split modules directly.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Standalone runtime contour")
		.ДобавитьСерверныйТест("TheVariantKnowsItIsStandalone")
		.ДобавитьСерверныйТест("ConfigurationComesFromTheProvider")
		.ДобавитьСерверныйТест("TheProviderDeclaresNoConnectionsOrPublications")
		.ДобавитьСерверныйТест("AnOutboundCallWithoutASidecarFailsControlled")
		.ДобавитьСерверныйТест("TheLevelMappingSurvivesInTheStandaloneVariant")
		.ДобавитьСерверныйТест("TheAuthTypeMappingSurvivesInTheStandaloneVariant")
		.ДобавитьСерверныйТест("AnAbsentAuthTypeIsRefusedRatherThanGuessed");

EndProcedure

Procedure TheVariantKnowsItIsStandalone() Export

	// IsStandalone() reports whether Catalog.mol_Services resolves, so this asserts that the builder
	// dropped the catalog, not merely that some flag is set.
	ЮТест.ОжидаетЧто(Moleculer.IsStandalone(), "the canonical catalog must be absent").ЭтоИстина();

EndProcedure

Procedure ConfigurationComesFromTheProvider() Export

	Config = Moleculer.GetConfig(Истина);

	// ExtVersion, Namespace and ExtAdminRole are supplied only by MoleculerOverridable: nothing in
	// the generated module assigns them. Reading them proves the provider seam is wired up, whereas
	// ModulePrefix and LogLevel are assigned in the generated module itself.
	ЮТест.ОжидаетЧто(Config.ExtVersion, "the provider supplies the version").Равно("0.2.0 beta 4");
	ЮТест.ОжидаетЧто(Config.Namespace, "the provider supplies the namespace").Равно("");
	ЮТест.ОжидаетЧто(Config.ExtAdminRole, "the provider supplies the admin role").Равно("");
	ЮТест.ОжидаетЧто(Config.ModulePrefix, "the module prefix").Равно("Service");

	Сообщить("standalone config: ModulePrefix=" + Config.ModulePrefix
		+ ", LogLevel=" + Строка(Config.LogLevel)
		+ ", ExtVersion=" + Config.ExtVersion
		+ ", Namespace=<" + Config.Namespace + ">");

EndProcedure

Procedure TheProviderDeclaresNoConnectionsOrPublications() Export

	// Both paths are exercised on purpose. The runtime reads the reuse-cached one, and the acceptance
	// asks for the provider's data rather than the stub sample rows an earlier shape returned.
	ЮТест.ОжидаетЧто(Moleculer.GetConnections(Истина).Количество(), "provider connections").Равно(0);
	ЮТест.ОжидаетЧто(Moleculer.GetPublications(Истина).Количество(), "provider publications").Равно(0);
	ЮТест.ОжидаетЧто(Moleculer.GetConnections().Количество(), "cached connections").Равно(0);
	ЮТест.ОжидаетЧто(Moleculer.GetPublications().Количество(), "cached publications").Равно(0);

EndProcedure

Procedure AnOutboundCallWithoutASidecarFailsControlled() Export

	// No sidecar runs during this suite, so this is the unreachable-sidecar case. The call must be
	// reported as an error instead of returning a silent failure, and it must not leave the session
	// in safe mode or in a half-built context.
	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.Call("runtime.contourProbe", Новый Структура);
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "a call with no reachable sidecar must raise").ЭтоИстина();
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Failure), "the failure must carry a reason").ЭтоИстина();
	ЮТест.ОжидаетЧто(БезопасныйРежим(), "the failed call must not leave safe mode on").ЭтоЛожь();

	Сообщить("outbound failure: " + Failure);

EndProcedure

Procedure TheLevelMappingSurvivesInTheStandaloneVariant() Export

	// The builder used to delete the whole statement for a dead condition instead of the dead branch,
	// which emptied this mapping and left the logger comparing the configured level against nothing. It
	// now keeps the surviving Else, so the platform-enum mapping is what the variant runs.
	Levels = Moleculer.LogLevels();

	ЮТест.ОжидаетЧто(Levels.Info, "the level mapping survives as the platform enum").Равно(EventLogLevel.Information);
	ЮТест.ОжидаетЧто(Levels.Debug = Неопределено, "no level is left undefined").ЭтоЛожь();

EndProcedure

Procedure TheAuthTypeMappingSurvivesInTheStandaloneVariant() Export

	// The same fix, second casualty: the variant's deployment profile names auth types as strings, so
	// the mapping has to be present for the dispatch in NewPublicationAuthParams to reach a branch at all.
	AuthTypes = Moleculer.AuthTypes();

	ЮТест.ОжидаетЧто(AuthTypes.UsingAccessToken, "the auth types survive as strings").Равно("UsingAccessToken");

	PasswordParams = Moleculer.NewPublicationAuthParams("UsingPassword");
	ЮТест.ОжидаетЧто(PasswordParams.Property("username"), "a declared type is answered with its own fields").ЭтоИстина();
	ЮТест.ОжидаетЧто(PasswordParams.Property("password"), "and both credentials are declared").ЭтоИстина();

EndProcedure

Procedure AnAbsentAuthTypeIsRefusedRatherThanGuessed() Export

	// Before the fix the mapping was undefined, so an absent type matched the first comparison —
	// `Undefined = Undefined` — and was answered with token auth. Now it reaches the same refusal that
	// extension mode gives, which is the point of the dispatch being shared.
	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.NewPublicationAuthParams(Неопределено);
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "an absent auth type is refused: " + Failure).ЭтоИстина();

EndProcedure

#EndRegion
