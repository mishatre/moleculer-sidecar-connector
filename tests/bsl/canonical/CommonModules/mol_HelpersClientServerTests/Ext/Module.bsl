// Behavioural tests for the client/server provider module.
//
// Why this module: mol_Helpers is a facade that forwards every predicate to mol_HelpersClientServer,
// so the provider is where the behaviour actually lives and where a platform-specific branch would be
// introduced. Testing it directly covers both, and the delegation is asserted as well so the pair
// cannot drift apart unnoticed.
//
// Mode note: in the standalone variant the builder merges the provider into the helpers, so these
// modules are addressed directly here and through Moleculer in tests/bsl/standalone.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Helpers provider")
		.ДобавитьСерверныйТест("IsObjectAcceptsStructuresAndMapsOnly")
		.ДобавитьСерверныйТест("IsStructureAndIsMapAreMutuallyExclusive")
		.ДобавитьСерверныйТест("IsStringAcceptsOnlyStrings")
		.ДобавитьСерверныйТест("IsNumberAcceptsOnlyNumbers")
		.ДобавитьСерверныйТест("IsArrayAcceptsOnlyArrays")
		.ДобавитьСерверныйТест("IsBinaryDataAcceptsOnlyBinaryData")
		.ДобавитьСерверныйТест("IsValidDateAcceptsOnlyDates")
		.ДобавитьСерверныйТест("IsStreamRecognisesAMemoryStream")
		.ДобавитьСерверныйТест("CanBeNumberAcceptsNumericText")
		.ДобавитьСерверныйТест("CanBeNumberRefusesInputThatIsNotANumber")
		.ДобавитьСерверныйТест("GetVersionedFullNameWithoutAVersionReturnsTheName")
		.ДобавитьСерверныйТест("GetVersionedFullNamePrefixesAVersion")
		.ДобавитьСерверныйТест("TheHelpersFacadeDelegatesToTheProvider");

EndProcedure

Procedure IsObjectAcceptsStructuresAndMapsOnly() Export

	// IsObject decides whether a value can carry named members, which is what the packet and option
	// code keys on. A Map is included, an Array deliberately is not.
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsObject(Новый Структура), "a structure is an object").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsObject(Новый Соответствие), "a map is an object").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsObject(Новый Массив), "an array is not an object").ЭтоЛожь();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsObject(Неопределено), "undefined is not an object").ЭтоЛожь();

EndProcedure

Procedure IsStructureAndIsMapAreMutuallyExclusive() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsStructure(Новый Структура), "a structure is a structure").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsStructure(Новый Соответствие), "a map is not a structure").ЭтоЛожь();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsMap(Новый Соответствие), "a map is a map").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsMap(Новый Структура), "a structure is not a map").ЭтоЛожь();

EndProcedure

Procedure IsStringAcceptsOnlyStrings() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsString("text"), "a string is a string").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsString(1), "a number is not a string").ЭтоЛожь();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsString(Неопределено), "undefined is not a string").ЭтоЛожь();

EndProcedure

Procedure IsNumberAcceptsOnlyNumbers() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsNumber(1.5), "a number is a number").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsNumber("1.5"), "numeric text is not a number").ЭтоЛожь();

EndProcedure

Procedure IsArrayAcceptsOnlyArrays() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsArray(Новый Массив), "an array is an array").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsArray(Новый Структура), "a structure is not an array").ЭтоЛожь();

EndProcedure

Procedure IsBinaryDataAcceptsOnlyBinaryData() Export

	Data = Base64Значение("dGVzdA==");

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsBinaryData(Data), "binary data is binary data").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsBinaryData("text"), "a string is not binary data").ЭтоЛожь();

EndProcedure

Procedure IsValidDateAcceptsOnlyDates() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsValidDate(Дата(2026, 9, 29)), "a date is a date").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsValidDate("2026-09-29"), "a date string is not a date").ЭтоЛожь();

EndProcedure

Procedure IsStreamRecognisesAMemoryStream() Export

	// The predicate exists for payloads that may arrive as a stream, so the memory stream case is the
	// one that matters: a string must not be mistaken for one.
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsStream(Новый ПотокВПамяти), "a memory stream is a stream").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsStream("text"), "a string is not a stream").ЭтоЛожь();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.IsStream(Неопределено), "undefined is not a stream").ЭтоЛожь();

EndProcedure

Procedure CanBeNumberAcceptsNumericText() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.CanBeNumber("123"), "numeric text can be a number").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.CanBeNumber(123), "a number can be a number").ЭтоИстина();

EndProcedure

Procedure CanBeNumberRefusesInputThatIsNotANumber() Export

	// The conversion is attempted rather than pattern-matched, so the refusal must come from a failed
	// conversion and not from a guess about the text.
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.CanBeNumber("abc"), "text cannot be a number").ЭтоЛожь();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.CanBeNumber(Неопределено), "undefined cannot be a number").ЭтоЛожь();
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.CanBeNumber(Новый Структура), "a structure cannot be a number").ЭтоЛожь();

EndProcedure

Procedure GetVersionedFullNameWithoutAVersionReturnsTheName() Export

	ЮТест.ОжидаетЧто(mol_HelpersClientServer.GetVersionedFullName("Contract"), "an absent version leaves the name alone").Равно("Contract");

EndProcedure

Procedure GetVersionedFullNamePrefixesAVersion() Export

	// A version that is not numeric is used verbatim, so this case is the deterministic half. The
	// numeric half goes through Format() and therefore depends on the session's number format, so only
	// its shape is asserted.
	ЮТест.ОжидаетЧто(mol_HelpersClientServer.GetVersionedFullName("Contract", "v9"), "a textual version is used as given").Равно("v9.Contract");

	Formatted = mol_HelpersClientServer.GetVersionedFullName("Contract", 2);
	ЮТест.ОжидаетЧто(СтрНайти(Formatted, ".Contract") > 0, "a numeric version is prefixed and suffixed: " + Formatted).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНачинаетсяС(Formatted, "v"), "a numeric version is prefixed with v: " + Formatted).ЭтоИстина();

EndProcedure

Procedure TheHelpersFacadeDelegatesToTheProvider() Export

	// mol_Helpers is only a forwarder. Asserting the pair agree means a future platform-specific branch
	// in the provider cannot be bypassed by the facade silently.
	ЮТест.ОжидаетЧто(mol_Helpers.IsObject(Новый Структура), "IsObject agrees").Равно(mol_HelpersClientServer.IsObject(Новый Структура));
	ЮТест.ОжидаетЧто(mol_Helpers.IsMap(Новый Соответствие), "IsMap agrees").Равно(mol_HelpersClientServer.IsMap(Новый Соответствие));
	ЮТест.ОжидаетЧто(mol_Helpers.IsString("text"), "IsString agrees").Равно(mol_HelpersClientServer.IsString("text"));
	ЮТест.ОжидаетЧто(mol_Helpers.CanBeNumber("abc"), "CanBeNumber agrees").Равно(mol_HelpersClientServer.CanBeNumber("abc"));
	ЮТест.ОжидаетЧто(mol_Helpers.GetVersionedFullName("Contract", "v9"), "GetVersionedFullName agrees").Равно(mol_HelpersClientServer.GetVersionedFullName("Contract", "v9"));

EndProcedure

#EndRegion
