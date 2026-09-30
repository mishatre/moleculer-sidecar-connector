////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Behavioural tests for the inbound handler path.
//
// Source function exercised: mol_ContextFactory.Handler, which is the inbound counterpart of the
// broker's outbound entry points and the only place in the connector that pushes an ambient context and
// pops it again. The acceptance asks for handler resolution, rejection of an unlisted handler, and
// push/pop cleanup on both success and failure, so each of those is asserted here rather than inferred
// from the code.
//
// Contrast worth keeping: the push in mol_Broker.Call/Emit/Broadcast is never popped, because it happens
// after the transport answers. Here the pop is in the function's own tail, outside the Try block, so both
// the success and the failure path restore the stack. That difference is why this suite can assert
// balance in-process while the broker's sites cannot be reached without a sidecar.
//
// The handler is resolved from Context.Locals.Handler as a dotted module.function name, which is what
// mol_Transport.RequestHandler writes there before calling this.
//
// Mode note: canonical only. The standalone variant merges mol_ContextFactory into Moleculer.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Inbound dispatch")
		.ДобавитьСерверныйТест("AResolvableHandlerRunsAndItsResultIsReturned")
		.ДобавитьСерверныйТест("TheStackIsBalancedAfterASuccessfulHandler")
		.ДобавитьСерверныйТест("AnUnresolvableHandlerIsReportedNotRaised")
		.ДобавитьСерверныйТест("TheStackIsBalancedAfterAFailingHandler")
		.ДобавитьСерверныйТест("AContextWithNeitherActionNorEventIsReported");

EndProcedure

Procedure AResolvableHandlerRunsAndItsResultIsReturned() Export

	// mol_ContextFactory.Handler — resolution through Locals.Handler. mol_Internal.PingAction is used
	// because it is a real exported handler of a real service module, not a fixture written for this test.
	Response = mol_ContextFactory.Handler(InboundContext("mol_Internal.PingAction"));

	ЮТест.ОжидаетЧто(mol_Helpers.IsErrorResponse(Response), "a resolvable handler produces no error").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Response.Result, "the handler's result is returned").Равно("pong");

EndProcedure

Procedure TheStackIsBalancedAfterASuccessfulHandler() Export

	// mol_ContextFactory.Handler — the pop is in the function's tail, so a completed call must leave the
	// stack exactly as it found it. The sentinel that was current before the call has to be current after.
	Sentinel = Новый Структура("id", "sentinel");
	mol_ContextFactory.SetCurrentContext(Sentinel);

	mol_ContextFactory.Handler(InboundContext("mol_Internal.PingAction"));

	ЮТест.ОжидаетЧто(mol_ContextFactory.GetCurrentContext().id,
		"the context that was current before the call is current again").Равно("sentinel");

EndProcedure

Procedure AnUnresolvableHandlerIsReportedNotRaised() Export

	// mol_ContextFactory.Handler — an unlisted handler is a caller error, and the acceptance wants it
	// rejected. It arrives as an error response rather than an exception, because the raise happens inside
	// the Try that the function catches.
	Response = mol_ContextFactory.Handler(InboundContext("mol_Internal.NoSuchAction"));

	ЮТест.ОжидаетЧто(mol_Helpers.IsErrorResponse(Response), "an unlisted handler is reported as an error").ЭтоИстина();

EndProcedure

Procedure TheStackIsBalancedAfterAFailingHandler() Export

	// The same balance requirement on the failure path. A pop that only ran after a successful call would
	// leak one entry per failure, and failures are the common case on a busy connector.
	Sentinel = Новый Структура("id", "sentinel");
	mol_ContextFactory.SetCurrentContext(Sentinel);

	mol_ContextFactory.Handler(InboundContext("mol_Internal.NoSuchAction"));

	ЮТест.ОжидаетЧто(mol_ContextFactory.GetCurrentContext().id,
		"a failed call leaves the stack as it found it").Равно("sentinel");

EndProcedure

Procedure AContextWithNeitherActionNorEventIsReported() Export

	// mol_ContextFactory.Handler — a context that names no destination cannot be dispatched. The function
	// raises inside its Try and reports the result, so the assertion is on the response and on the message
	// that was captured, not on an exception escaping the caller.
	Context = InboundContext("mol_Internal.PingAction");
	Context.Action = Неопределено;

	Response = mol_ContextFactory.Handler(Context);

	ЮТест.ОжидаетЧто(mol_Helpers.IsErrorResponse(Response), "a context with no destination is an error").ЭтоИстина();

	Failure = Response.Error.Message;
	ЮТест.ОжидаетЧто(СтрНайти(Строка(Failure), "Malformed context") > 0, "the refusal says why: " + Строка(Failure)).ЭтоИстина();

EndProcedure

// Builds the context mol_Transport.RequestHandler hands over: a destination and a resolved handler. Only
// the keys Handler reads are populated, so a failure points at the contract rather than at a fixture that
// drifted.
Function InboundContext(HandlerName)

	Context = Новый Структура;
	Context.Insert("Action", "probe.action");
	Context.Insert("Event" , Неопределено);
	Context.Insert("Locals", Новый Структура("Handler", HandlerName));

	Return Context;

EndFunction

#EndRegion
