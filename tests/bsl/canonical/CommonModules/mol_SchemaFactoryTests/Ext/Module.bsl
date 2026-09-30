// Behavioural tests for mol_SchemaFactory — the module that turns a service definition
// into the schema the broker publishes.
//
// Mode note: the canonical extension keeps mol_SchemaFactory as its own common module, so
// this suite addresses it directly and is canonical-only. The standalone variant merges it
// into Moleculer.
//
// Why the coverage is shaped this way: FromString() is the headline entry point, but it
// parses YAML through the sidecar ("$sidecar.utils.parseYAML"), so it cannot run without a
// live connection. What is reachable in-process is the type builders that service authors
// declare parameters with, the building-context guard, and CompileServiceSchema itself.
//
// CompileServiceSchema is exercised against mol_Internal, which is a real server module
// with a real Constructor, so the compile pipeline is checked against something the
// connector actually publishes rather than against a purpose-built fixture.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export
	
	ЮТТесты
		.ДобавитьТестовыйНабор("mol_SchemaFactory")
		.ДобавитьСерверныйТест("TypeStringIsRequiredByDefault")
		.ДобавитьСерверныйТест("TypeStringCanBeOptional")
		.ДобавитьСерверныйТест("TypeBooleanCarriesDefaultConvertAndOptional")
		.ДобавитьСерверныйТест("TypeArrayNestsItsItemType")
		.ДобавитьСерверныйТест("TypeMultiIsOptionalByDefault")
		.ДобавитьСерверныйТест("CompilesARealServiceModule")
		.ДобавитьСерверныйТест("QualifiesHandlerNamesWithTheModule")
		.ДобавитьСерверныйТест("PrefixesTheServiceNameWhenAsked")
		.ДобавитьСерверныйТест("CarriesActionParamsFromTheConstructor")
		.ДобавитьСерверныйТест("TheBuildingContextStackRoundTrips")
		.ДобавитьСерверныйТест("TheBuilderRefusesToRunOutsideACompilingService")
		.ДобавитьСерверныйТест("CompileServiceSchemaRaisesForAnUnknownModule")
		.ДобавитьСерверныйТест("CompileServiceSchemaRaisesForANonModuleValue")
		.ДобавитьСерверныйТест("SchemaFailuresUseTheDispatchedType")
		.ДобавитьСерверныйТест("FromStringRejectsANonString")
		.ДобавитьСерверныйТест("FromStringNeedsTheSidecarForAnythingThatIsNotJSON")
		.ДобавитьСерверныйТест("TheSafeModeWindowIsReal")
		.ДобавитьСерверныйТест("ASafeModeWindowDoesNotBlockLocalParsing")
		.ДобавитьСерверныйТест("AnEmptyServiceReferenceIsNotATypeError")
		.ДобавитьСерверныйТест("TheQualifiedNameComesFromTheDeclaredName");
	
EndProcedure

#Region Parameters

Procedure TypeStringIsRequiredByDefault() Export
	
	Type = mol_SchemaFactory.TypeString();
	
	ЮТест.ОжидаетЧто(Type.type, "a plain parameter is declared as a string").Равно("string");
	ЮТест.ОжидаетЧто(Type.optional, "TypeString defaults to a required parameter").Равно(Ложь);
	
EndProcedure

Procedure TypeStringCanBeOptional() Export
	
	Type = mol_SchemaFactory.TypeString(Истина);
	
	ЮТест.ОжидаетЧто(Type.optional, "the flag is the only thing that changes").Равно(Истина);
	ЮТест.ОжидаетЧто(Type.type, "an optional parameter is still a string").Равно("string");
	
EndProcedure

Procedure TypeBooleanCarriesDefaultConvertAndOptional() Export
	
	Default = mol_SchemaFactory.TypeBoolean();
	
	ЮТест.ОжидаетЧто(Default.type, "a flag is declared as a boolean").Равно("boolean");
	ЮТест.ОжидаетЧто(Default.optional, "TypeBoolean is optional by default").Равно(Истина);
	ЮТест.ОжидаетЧто(Default.convert, "TypeBoolean converts by default").Равно(Истина);
	ЮТест.ОжидаетЧто(Default.default, "the default value is False unless given").Равно(Ложь);
	
	Overridden = mol_SchemaFactory.TypeBoolean(Истина, Ложь, Ложь);
	
	ЮТест.ОжидаетЧто(Overridden.default, "the first argument is the default value").Равно(Истина);
	ЮТест.ОжидаетЧто(Overridden.optional, "the second argument is the optional flag").Равно(Ложь);
	ЮТест.ОжидаетЧто(Overridden.convert, "the third argument is the convert flag").Равно(Ложь);
	
EndProcedure

Procedure TypeArrayNestsItsItemType() Export
	
	Items = mol_SchemaFactory.TypeString(Истина);
	Type = mol_SchemaFactory.TypeArray(Items);
	
	ЮТест.ОжидаетЧто(Type.type, "a list is declared as an array").Равно("array");
	ЮТест.ОжидаетЧто(Type.optional, "TypeArray defaults to a required parameter").Равно(Ложь);
	ЮТест.ОжидаетЧто(Type.items.type, "the item descriptor is carried unchanged").Равно("string");
	ЮТест.ОжидаетЧто(Type.items.optional, "the item descriptor keeps its own flags").Равно(Истина);
	
EndProcedure

Procedure TypeMultiIsOptionalByDefault() Export
	
	Rules = New Array();
	Rules.Add(mol_SchemaFactory.TypeString());
	Type = mol_SchemaFactory.TypeMulti(Rules);
	
	ЮТест.ОжидаетЧто(Type.type, "a union is declared as multi").Равно("multi");
	ЮТест.ОжидаетЧто(Type.optional, "TypeMulti is optional by default").Равно(Истина);
	ЮТест.ОжидаетЧто(Type.rules.Count(), "the rules are carried through").Равно(1);
	
EndProcedure

#EndRegion

#Region Compiling

Procedure CompilesARealServiceModule() Export
	
	Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal");
	
	ЮТест.ОжидаетЧто(Schema.Name, "the constructor owns the service name").Равно("$internal");
	ЮТест.ОжидаетЧто(Schema.Metadata.Get("$dynamic"), "a module service is not a dynamic one").Равно(Ложь);
	
EndProcedure

Procedure QualifiesHandlerNamesWithTheModule() Export
	
	Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal");
	Action = Schema.Actions.Get("list");
	
	ЮТест.ОжидаетЧто(Action.Handler,
			"a handler in a module service is addressed through its module, otherwise the broker could not call it")
		.Равно("mol_Internal.ListAction");
	
EndProcedure

Procedure PrefixesTheServiceNameWhenAsked() Export
	
	Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal", "pfx");
	
	ЮТест.ОжидаетЧто(Schema.Name, "the prefix is applied in front of the constructor's name")
		.Равно("pfx.$internal");
	
EndProcedure

Procedure CarriesActionParamsFromTheConstructor() Export
	
	Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal");
	Params = Schema.Actions.Get("services").Params;
	
	ЮТест.ОжидаетЧто(Params.onlyLocal.type, "declared params reach the compiled schema").Равно("boolean");
	ЮТест.ОжидаетЧто(Params.grouping.default,
			"Builder.TypeBoolean(True) passes its default through to the schema").Равно(Истина);
	
EndProcedure

Procedure TheBuildingContextStackRoundTrips() Export
	
	// CompileServiceSchema pushes a context that the service constructor reads back through
	// GetServiceBuildingContext, so this stack has to survive across calls. It is served by
	// mol_ReuseCalls.GetCacheStack(), whose source returns New Structure() — a fresh object per
	// call, which would make the stack useless. The raw values are printed because comparing
	// against a possibly-Undefined value may not be a real assertion.
	Кэш = mol_ReuseCalls.GetCacheStack();
	Кэш.Insert("probe", 1);
	Второй = mol_ReuseCalls.GetCacheStack();
	ДержитКэш = Второй.Property("probe");
	
	mol_Helpers.PushToStack("probeStack", 42);
	Найденное = mol_Helpers.LastFromStack("probeStack");
	
	Сообщить("stack probe: GetCacheStack persists = " + Строка(ДержитКэш)
		+ "; pushed 42, read back [" + Строка(Найденное) + "]"
		+ " type " + Строка(ТипЗнч(Найденное)));
	
	ЮТест.ОжидаетЧто(Строка(Найденное),
			"compared as text, so a skipped Undefined comparison cannot pass this")
		.Равно("42");
	
EndProcedure

Procedure TheBuilderRefusesToRunOutsideACompilingService() Export
	
	// A compile runs first on purpose: if CompileServiceSchema forgot to pop its context,
	// the stack would still hold one and the call below would silently succeed.
	mol_SchemaFactory.CompileServiceSchema("mol_Internal");
	
	Raised = False;
	Try
		mol_SchemaFactory.Action("probe", "Handler");
	Except
		Raised = True;
	EndTry;
	
	ЮТест.ОжидаетЧто(Raised,
			"a finished compile must leave no building context, so a stray builder call has to fail")
		.Равно(Истина);
	
EndProcedure

#EndRegion

#Region SafeMode

// CompileServiceSchema wraps the service constructor in SetSafeMode(True), and the
// constructor is where a text definition would be parsed. The platform forbids loading and
// connecting external components in safe mode, which is what makes an AddIn parser awkward.
//
// These two tests put the other option on a measured footing: if safe mode does not block
// local computation, then a parser written in BSL needs no exception at all, and the
// question of switching safe mode off never arises.
//
// Each test enables safe mode exactly once and disables it exactly once in the same
// procedure. The platform also clears it on return from the procedure that enabled it, so a
// throwaway experiment here cannot leak into the rest of the run.

Procedure TheSafeModeWindowIsReal() Export
	
	УстановитьБезопасныйРежим(Истина);
	IsSafe = БезопасныйРежим();
	УстановитьБезопасныйРежим(Ложь);
	
	ЮТест.ОжидаетЧто(IsSafe, "safe mode is on for anything reached from the window")
		.Равно(Истина);
	
EndProcedure

Procedure ASafeModeWindowDoesNotBlockLocalParsing() Export
	
	УстановитьБезопасныйРежим(Истина);
	
	Parsed = Неопределено;
	Failure = Неопределено;
	Try
		Parsed = mol_Helpers.FromJSONString("{""name"":""probe""}");
	Except
		Failure = ИнформацияОбОшибке();
	EndTry;
	
	УстановитьБезопасныйРежим(Ложь);
	
	ЮТест.ОжидаетЧто(Failure, "safe mode restricts external actions, not local computation")
		.Равно(Неопределено);
	ЮТест.ОжидаетЧто(Parsed.name, "and the parsed value is usable inside the window").Равно("probe");
	
EndProcedure

#EndRegion

#Region Parsing

// FromString is the only entry point that reads a text definition, and it is the only
// place the connector still needs YAML. These two tests pin what that dependency costs:
// the JSON branch is native and needs nothing, while the YAML branch cannot run at all
// without a connected sidecar.

Procedure FromStringRejectsANonString() Export
	
	Raised = False;
	Try
		mol_SchemaFactory.FromString(42);
	Except
		Raised = True;
	EndTry;
	
	ЮТест.ОжидаетЧто(Raised, "a definition has to be text").Равно(Истина);
	
EndProcedure

Procedure FromStringNeedsTheSidecarForAnythingThatIsNotJSON() Export
	
	// No sidecar is connected during a test run, so YAML text cannot be parsed. The
	// failure is also hard to diagnose: the Try around ParseServiceDefinition turns the
	// transport failure into "TextDefinition should contain valid YAML or JSON", which
	// blames the caller's text for a missing parser. Only the raise is asserted here,
	// because the message is expected to change when the taxonomy is settled.
	Raised = False;
	Try
		mol_SchemaFactory.FromString("name: probe" + Chars.LF + "actions: {}");
	Except
		Raised = True;
	EndTry;
	
	ЮТест.ОжидаетЧто(Raised, "without a sidecar there is no parser behind the YAML branch")
		.Равно(Истина);
	
EndProcedure

#EndRegion

#Region Failing

// Context setup runs before CompileServiceSchema enters its Try block, so a bad reference
// escapes as an exception. Only the construction phase is contained. These two tests pin
// that asymmetry; the test below it pins the containment itself.

Procedure CompileServiceSchemaRaisesForAnUnknownModule() Export
	
	Raised = False;
	Try
		mol_SchemaFactory.CompileServiceSchema("mol_NoSuchModuleAtAll");
	Except
		Raised = True;
	EndTry;
	
	ЮТест.ОжидаетЧто(Raised, "an unresolvable module name is raised, not reported as a failed compile")
		.Равно(Истина);
	
EndProcedure

Procedure CompileServiceSchemaRaisesForANonModuleValue() Export
	
	Raised = False;
	Try
		mol_SchemaFactory.CompileServiceSchema(42);
	Except
		Raised = True;
	EndTry;
	
	ЮТест.ОжидаетЧто(Raised, "a value that is not a module or a reference is raised")
		.Равно(Истина);
	
EndProcedure

// The taxonomy work landed, so this test was rewritten rather than deleted, as its own comment asked.
//
// mol_SchemaFactory raises its schema failures with the type key "ServiceSchema", while the factory is
// named ServiceSchemaError. CustomError now normalises the short name before its chain, so both spellings
// reach the same factory and a consumer can tell a schema failure from any other kind.
Procedure SchemaFailuresUseTheDispatchedType() Export

    Intended = mol_Errors.ServiceSchemaError("probe");
    Actual = mol_Errors.CustomError("ServiceSchema", "probe");

    ЮТест.ОжидаетЧто(Intended.Type, "the named factory produces the documented code")
            .Равно("SERVICE_SCHEMA_ERROR");
    ЮТест.ОжидаетЧто(Actual.Type, "both spellings reach the same factory")
            .Равно("SERVICE_SCHEMA_ERROR");
    ЮТест.ОжидаетЧто(Actual.Message, "the caller's message survives the normalisation")
            .Равно("probe");
	
EndProcedure

// A catalog reference selects a dynamic service in extension mode, so the dispatch must treat it as
// an accepted value type rather than falling through to the type error. An empty reference is the
// boundary of that path: the constructor text is missing, so a refusal is expected, but it must be a
// refusal about the constructor and not the argument type.
//
// The failure text is carried in the assertion messages so the distinction stays visible when this
// changes.
Procedure AnEmptyServiceReferenceIsNotATypeError() Export

	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_SchemaFactory.CompileServiceSchema(Справочники.mol_Services.ПустаяСсылка());
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	// RaiseTypeError names its parameter, so a failure that mentions it would mean the catalog
	// reference was rejected as an unsupported type instead of being dispatched as a dynamic service.
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "ModuleOrReference") = 0,
		"a catalog reference is an accepted type, so the type error must not fire: " + Failure).ЭтоИстина();
	ЮТест.ОжидаетЧто(Raised, "an empty reference is refused rather than compiled silently: " + Failure).ЭтоИстина();

EndProcedure

// The acceptance asks for the prefix and version derivation of a service's fullName. This records both
// answers, and the first one matters beyond this suite: the qualified name is the name the constructor
// declares, not the module it lives in, so `mol_Internal` compiles to `$internal` and a service whose
// constructor declares no version gets no version suffix.
//
// That also settles an assumption made while investigating T032: the guard in mol_Transport.RequestHandler
// and the qualifier mol_Broker builds do agree on `$internal`, so the reason the connector's own actions
// answer 503 lies further in than the naming.
Procedure TheQualifiedNameComesFromTheDeclaredName() Export

	Schema = mol_SchemaFactory.CompileServiceSchema("mol_Internal");

	ЮТест.ОжидаетЧто(Schema.FullName, "the qualified name is the declared name: " + Строка(Schema.FullName)).Равно("$internal");
	ЮТест.ОжидаетЧто(СтрНайти(Строка(Schema.FullName), ".") = 0,
		"a service declaring no version gets no version suffix: " + Строка(Schema.FullName)).ЭтоИстина();

EndProcedure

#EndRegion

#EndRegion
