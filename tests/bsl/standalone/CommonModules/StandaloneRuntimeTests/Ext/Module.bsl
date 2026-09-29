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
		.ДобавитьСерверныйТест("TheLevelMappingIsStrippedByTheBuilder")
		.ДобавитьСерверныйТест("TheAuthTypeMappingIsStrippedByTheBuilder");

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

Procedure TheLevelMappingIsStrippedByTheBuilder() Export

	// CURRENT BEHAVIOUR, pinned deliberately. The builder's strip step deletes the whole
	// `If Not IsStandalone() ... Else ... EndIf` statement when the condition is dead, instead of
	// keeping the live Else body. So the platform-enum mapping this variant needs never reaches the
	// output and every level is undefined. The consequence is not a lost label: the logger compares the
	// configured level with `=`, so no comparison can match and the level no longer selects a branch.
	//
	// When the builder keeps the Else body, this test must be rewritten to assert EventLogLevel values,
	// not deleted.
	Levels = Moleculer.LogLevels();

	ЮТест.ОжидаетЧто(Levels.Info = Неопределено, "CURRENT BEHAVIOUR: the level mapping is stripped").ЭтоИстина();
	ЮТест.ОжидаетЧто(Levels.Error = Неопределено, "CURRENT BEHAVIOUR: no level is mapped").ЭтоИстина();

EndProcedure

Procedure TheAuthTypeMappingIsStrippedByTheBuilder() Export

	// A second casualty of the same strip step, with a sharper consequence: the variant's deployment
	// profile names auth types as strings, but no comparison in NewPublicationAuthParams can match an
	// undefined mapping, so a correctly declared type is refused. An absent type fares worse still: it
	// matches the first comparison, `Undefined = Undefined`, and is answered with token auth.
	AuthTypes = Moleculer.AuthTypes();

	ЮТест.ОжидаетЧто(AuthTypes.UsingAccessToken = Неопределено, "CURRENT BEHAVIOUR: the auth types are stripped").ЭтоИстина();

	Raised  = Ложь;
	Failure = "";

	Попытка
		Moleculer.NewPublicationAuthParams("UsingPassword");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "CURRENT BEHAVIOUR: a declared type is refused: " + Failure).ЭтоИстина();

	NoTypeParams = Moleculer.NewPublicationAuthParams(Неопределено);
	ЮТест.ОжидаетЧто(NoTypeParams.Property("token"), "CURRENT BEHAVIOUR: an absent type is answered with token auth").ЭтоИстина();

EndProcedure

#EndRegion
