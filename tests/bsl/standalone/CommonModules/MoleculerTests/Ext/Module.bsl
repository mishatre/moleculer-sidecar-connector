////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Behavioural tests for the merged standalone surface of the connector.
//
// Mode note: tools/standalone-builder merges mol_Helpers, mol_Errors, mol_Logger,
// mol_Transport, mol_ContextFactory, mol_Broker, mol_SchemaFactory and mol_Internal
// into the single Moleculer common module, and keeps only mol_Reuse and
// mol_ReuseCalls separate. The canonical extension produces the opposite shape: there
// Moleculer stays a thin facade and the helpers answer to their own module names.
// This suite therefore targets Moleculer.* and applies to the standalone base.
// Extension-mode suites addressing mol_Helpers directly belong in their own suite.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Moleculer (standalone surface)")
		.ДобавитьСерверныйТест("IsStringAcceptsString")
		.ДобавитьСерверныйТест("IsStringRejectsNumber")
		.ДобавитьСерверныйТест("IsStructureAcceptsStructure")
		.ДобавитьСерверныйТест("IsStructureRejectsMap")
		.ДобавитьСерверныйТест("IsMapAcceptsMap")
		.ДобавитьСерверныйТест("IsArrayAcceptsArray")
		.ДобавитьСерверныйТест("ToJSONStringReturnsStringsUnchanged")
		.ДобавитьСерверныйТест("FromJSONStringReadsObjectProperty")
		.ДобавитьСерверныйТест("FromJSONStringReadsArrayElements");

EndProcedure

Procedure IsStringAcceptsString() Export

	ЮТест.ОжидаетЧто(Moleculer.IsString("text")).ЭтоИстина();

EndProcedure

Procedure IsStringRejectsNumber() Export

	ЮТест.ОжидаетЧто(Moleculer.IsString(1)).ЭтоЛожь();

EndProcedure

Procedure IsStructureAcceptsStructure() Export

	ЮТест.ОжидаетЧто(Moleculer.IsStructure(New Structure())).ЭтоИстина();

EndProcedure

// A Map is not a Structure: the two must not be conflated.
Procedure IsStructureRejectsMap() Export

	ЮТест.ОжидаетЧто(Moleculer.IsStructure(New Map())).ЭтоЛожь();

EndProcedure

Procedure IsMapAcceptsMap() Export

	ЮТест.ОжидаетЧто(Moleculer.IsMap(New Map())).ЭтоИстина();

EndProcedure

Procedure IsArrayAcceptsArray() Export

	ЮТест.ОжидаетЧто(Moleculer.IsArray(New Array())).ЭтоИстина();

EndProcedure

// ToJSONString passes an already-serialized string through untouched.
Procedure ToJSONStringReturnsStringsUnchanged() Export

	ЮТест.ОжидаетЧто(Moleculer.ToJSONString("already a string"))
		.Равно("already a string");

EndProcedure

Procedure FromJSONStringReadsObjectProperty() Export

	Parsed = Moleculer.FromJSONString("{""answer"": 42}");

	ЮТест.ОжидаетЧто(Parsed.answer, "the parsed object must expose its property")
		.Равно(42);

EndProcedure

Procedure FromJSONStringReadsArrayElements() Export

	Parsed = Moleculer.FromJSONString("[1, 2, 3]");

	ЮТест.ОжидаетЧто(Parsed.Количество(), "an array literal must parse into a collection")
		.Равно(3);

EndProcedure

#EndRegion
