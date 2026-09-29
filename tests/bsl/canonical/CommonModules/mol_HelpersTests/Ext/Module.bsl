// Behavioural tests for mol_Helpers — the shared type, JSON and request helpers.
//
// Mode note: the canonical extension keeps mol_Helpers as its own common module, so the
// suite addresses it directly. The standalone variant merges it into Moleculer, where the
// same functions answer as Moleculer.*; that surface is covered by the standalone suite.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Helpers")
		.ДобавитьСерверныйТест("IsStringAcceptsString")
		.ДобавитьСерверныйТест("IsStringRejectsNumber")
		.ДобавитьСерверныйТест("IsNumberAcceptsNumber")
		.ДобавитьСерверныйТест("IsNumberRejectsNumericString")
		.ДобавитьСерверныйТест("CanBeNumberAcceptsNumbers")
		.ДобавитьСерверныйТест("CanBeNumberAcceptsNumericStrings")
		.ДобавитьСерверныйТест("CanBeNumberRejectsText")
		.ДобавитьСерверныйТест("TypeDescriptionCastsNumericStrings")
		.ДобавитьСерверныйТест("TypeDescriptionCastsNumericStringsInRussian")
		.ДобавитьСерверныйТест("IsStructureAcceptsStructure")
		.ДобавитьСерверныйТест("IsStructureRejectsMap")
		.ДобавитьСерверныйТест("IsMapAcceptsMap")
		.ДобавитьСерверныйТест("IsArrayAcceptsArray")
		.ДобавитьСерверныйТест("IsObjectRejectsPlainValue")
		.ДобавитьСерверныйТест("ToJSONStringReturnsStringsUnchanged")
		.ДобавитьСерверныйТест("FromJSONStringReadsObjectProperty")
		.ДобавитьСерверныйТест("FromJSONStringReadsArrayElements")
		.ДобавитьСерверныйТест("JSONRoundTripPreservesValues")
		.ДобавитьСерверныйТест("GetOnStructureIgnoresCase")
		.ДобавитьСерверныйТест("GetOnMapIsCaseSensitiveByDefault")
		.ДобавитьСерверныйТест("GetOnMapCanIgnoreCase")
		.ДобавитьСерверныйТест("NewRequestParametersDeclaresTheTransportContract");

EndProcedure

Procedure IsStringAcceptsString() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsString("text")).ЭтоИстина();

EndProcedure

Procedure IsStringRejectsNumber() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsString(1)).ЭтоЛожь();

EndProcedure

Procedure IsNumberAcceptsNumber() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsNumber(1)).ЭтоИстина();

EndProcedure

// CanBeNumber exists separately, so IsNumber must stay strict about the type.
Procedure IsNumberRejectsNumericString() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsNumber("1"), "a numeric string is not a Number")
		.ЭтоЛожь();

EndProcedure

// CanBeNumber is the lenient half of the pair: it answers whether a value can be read as a
// number, which is what the transport needs when the sidecar sends numbers as strings.
Procedure CanBeNumberAcceptsNumbers() Export

	ЮТест.ОжидаетЧто(mol_Helpers.CanBeNumber(1)).ЭтоИстина();

EndProcedure

Procedure CanBeNumberAcceptsNumericStrings() Export

	ЮТест.ОжидаетЧто(mol_Helpers.CanBeNumber("1")).ЭтоИстина();

EndProcedure

Procedure CanBeNumberRejectsText() Export

	ЮТест.ОжидаетЧто(mol_Helpers.CanBeNumber("not a number")).ЭтоЛожь();

EndProcedure

// Pins the platform call used to convert a number-like value, and verifies the method name.
// ПривестиЗначение is AdjustValue in the English spelling, not CastValue. Both names are
// exercised so a rename on either side shows up here.
Procedure TypeDescriptionCastsNumericStrings() Export

	NumberType = New TypeDescription("Number");
	Casted = NumberType.AdjustValue("1");

	ЮТест.ОжидаетЧто(Casted, "a numeric string must cast to a Number").Равно(1);

EndProcedure

Procedure TypeDescriptionCastsNumericStringsInRussian() Export

	NumberType = New TypeDescription("Number");
	Casted = NumberType.ПривестиЗначение("2");

	ЮТест.ОжидаетЧто(Casted, "the Russian spelling must name the same method").Равно(2);

EndProcedure

Procedure IsStructureAcceptsStructure() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsStructure(New Structure())).ЭтоИстина();

EndProcedure

// A Map is not a Structure: the two must not be conflated.
Procedure IsStructureRejectsMap() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsStructure(New Map())).ЭтоЛожь();

EndProcedure

Procedure IsMapAcceptsMap() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsMap(New Map())).ЭтоИстина();

EndProcedure

Procedure IsArrayAcceptsArray() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsArray(New Array())).ЭтоИстина();

EndProcedure

Procedure IsObjectRejectsPlainValue() Export

	ЮТест.ОжидаетЧто(mol_Helpers.IsObject("text"), "a scalar is not an object")
		.ЭтоЛожь();

EndProcedure

// ToJSONString passes an already-serialized string through untouched.
Procedure ToJSONStringReturnsStringsUnchanged() Export

	ЮТест.ОжидаетЧто(mol_Helpers.ToJSONString("already a string"))
		.Равно("already a string");

EndProcedure

Procedure FromJSONStringReadsObjectProperty() Export

	Parsed = mol_Helpers.FromJSONString("{""answer"": 42}");

	ЮТест.ОжидаетЧто(Parsed.answer, "the parsed object must expose its property")
		.Равно(42);

EndProcedure

Procedure FromJSONStringReadsArrayElements() Export

	Parsed = mol_Helpers.FromJSONString("[1, 2, 3]");

	ЮТест.ОжидаетЧто(Parsed.Количество(), "an array literal must parse into a collection")
		.Равно(3);

EndProcedure

// The two halves must compose: whatever ToJSONString writes, FromJSONString reads back.
Procedure JSONRoundTripPreservesValues() Export

	Source = New Structure("number, text, flag", 42, "value", True);

	Restored = mol_Helpers.FromJSONString(mol_Helpers.ToJSONString(Source));

	ЮТест.ОжидаетЧто(Restored.number, "numbers must survive the round trip").Равно(42);
	ЮТест.ОжидаетЧто(Restored.text, "strings must survive the round trip").Равно("value");
	ЮТест.ОжидаетЧто(Restored.flag, "booleans must survive the round trip").ЭтоИстина();

EndProcedure

// The lookup behaviour depends on the container, so each is pinned separately.
//
// Structure answers to Property(), which the platform matches case-insensitively, so
// IgnoreCase changes nothing for it.
Procedure GetOnStructureIgnoresCase() Export

	Source = New Structure("key", "value");

	ЮТест.ОжидаетЧто(mol_Helpers.Get(Source, "KEY", "missing"),
			"Structure.Property matches regardless of case")
		.Равно("value");

EndProcedure

// Map answers to Get(), which is case sensitive, so this is where IgnoreCase matters.
Procedure GetOnMapIsCaseSensitiveByDefault() Export

	Source = New Map();
	Source.Insert("key", "value");

	ЮТест.ОжидаетЧто(mol_Helpers.Get(Source, "KEY", "missing"),
			"a Map lookup must not match a different case by default")
		.Равно("missing");

EndProcedure

Procedure GetOnMapCanIgnoreCase() Export

	Source = New Map();
	Source.Insert("key", "value");

	ЮТест.ОжидаетЧто(mol_Helpers.Get(Source, "KEY", "missing", True),
			"IgnoreCase must match a differently cased Map key")
		.Равно("value");

EndProcedure

// NewRequestParameters is the contract shared with the transport, so its keys are pinned.
Procedure NewRequestParametersDeclaresTheTransportContract() Export

	Parameters = mol_Helpers.NewRequestParameters();

	For Each Expected In StrSplit("method,path,headers,query,useSSL,endpoint,port,timeout", ",") Do
		ЮТест.ОжидаетЧто(Parameters.Property(Expected), StrTemplate("key %1 must be declared", Expected))
			.ЭтоИстина();
	EndDo;

EndProcedure

#EndRegion
