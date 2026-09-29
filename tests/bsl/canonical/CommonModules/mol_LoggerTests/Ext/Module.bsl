// Behavioural tests for mol_Logger's level mapping.
//
// Mechanism under test: the logger does not store a level, it maps one. LogLevels() returns the four
// names the extension logs under, resolved either to the mol_LogLevel enum (extension mode) or to the
// platform's event-log levels (standalone, where the enum does not exist). WriteLogEventSystem then
// compares the configured level against those values to pick a branch, so a mapping that resolves to
// Undefined does not merely lose a label: no comparison can match.
//
// Mode note: this suite is canonical, so it asserts the enum path. The standalone path is covered by
// tests/bsl/standalone, which currently pins a defect: the builder strips the whole If/Else rather than
// keeping the live branch, so the platform mapping never reaches the variant.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Logger")
		.ДобавитьСерверныйТест("LogLevelsDeclaresTheFourLevels")
		.ДобавитьСерверныйТест("LogLevelsResolveToTheEnumInCanonicalMode")
		.ДобавитьСерверныйТест("TheConfiguredLogLevelComesFromTheExtensionConstant")
		.ДобавитьСерверныйТест("WritingEachLevelLeavesTheAmbientContextAlone");

EndProcedure

Procedure LogLevelsDeclaresTheFourLevels() Export

	Levels = mol_Logger.LogLevels();

	ЮТест.ОжидаетЧто(Levels.Количество(), "the mapping declares four levels").Равно(4);

	Declared = СтрРазделить("Debug,Error,Warn,Info", ",");
	For Each Name In Declared Do
		ЮТест.ОжидаетЧто(Levels.Property(Name), "the mapping declares " + Name).ЭтоИстина();
	EndDo;

EndProcedure

Procedure LogLevelsResolveToTheEnumInCanonicalMode() Export

	// Extension mode reads the predefined enum, which is what the logger compares against.
	Levels = mol_Logger.LogLevels();

	ЮТест.ОжидаетЧто(Levels.Debug = Неопределено, "Debug resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Levels.Error = Неопределено, "Error resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Levels.Warn = Неопределено, "Warn resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Levels.Info = Неопределено, "Info resolves to the enum").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Levels.Debug <> Levels.Error, "the levels are distinct from each other").ЭтоИстина();

EndProcedure

Procedure TheConfiguredLogLevelComesFromTheExtensionConstant() Export

	// GetConfig writes the mapping's Info level first and then overwrites it from the extension's
	// mol_LogLevel constant, so in this mode the setting is the source and the mapping is the fallback.
	// Comparing the two directly keeps the assertion valid whether or not the base has a value: an
	// unset constant leaves both sides undefined rather than failing.
	ЮТест.ОжидаетЧто(Moleculer.GetConfig(Истина).LogLevel,
		"the configured level comes from the mol_LogLevel constant").Равно(Constants["mol_LogLevel"].Get());

EndProcedure

Procedure WritingEachLevelLeavesTheAmbientContextAlone() Export

	// Logging is a side effect, not an operation, so it must not publish a context. The write itself
	// lands in the base's event log, which a test cannot read back, so the assertion is about what the
	// calls must not disturb.
	Sentinel = Новый Структура("id", "logging-sentinel");
	mol_ContextFactory.SetCurrentContext(Sentinel);

	mol_Logger.Debug("probe", "debug probe");
	mol_Logger.Info("probe", "info probe");
	mol_Logger.Warn("probe", "warn probe");
	mol_Logger.Error("probe", "error probe");

	ЮТест.ОжидаетЧто(mol_ContextFactory.GetCurrentContext().id,
		"logging does not publish an ambient context, and does not raise").Равно("logging-sentinel");

EndProcedure

#EndRegion
