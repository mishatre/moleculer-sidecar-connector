////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Behavioural tests for mol_ContextFactory — the module that builds and tracks the
// execution context passed along the Moleculer call chain.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_ContextFactory")
		.ДобавитьСерверныйТест("ModuleInitialises");

EndProcedure

// Regression guard for a defect that no static check could see.
//
// Emit used to be declared as a Function that assigned the result of mol_Broker.Emit,
// which is a Procedure. The platform rejects "Обращение к процедуре как к функции", the
// module body never compiled, and every call into mol_ContextFactory failed at runtime.
// Neither cfe compile, ibcmd config check nor the designer's /CheckModules reported it,
// because all three load metadata without compiling module bodies.
//
// Reaching any call in this module is therefore the assertion: a module that does not
// compile cannot be entered. The assertion below documents that intent; the value is the
// call itself.
Procedure ModuleInitialises() Export

	mol_ContextFactory.GetCurrentContext();

	ЮТест.ОжидаетЧто(True, "the call above only succeeds when the module compiled and initialised")
		.ЭтоИстина();

EndProcedure

#EndRegion
