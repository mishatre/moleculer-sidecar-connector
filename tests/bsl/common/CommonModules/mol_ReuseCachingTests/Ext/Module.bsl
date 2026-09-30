////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Behavioural tests for the reuse-caching mechanism.
//
// Mechanism under test: the platform's return-value reuse, not a cache written in the connector. The
// declarations are what make it real — mol_Reuse is `ReturnValuesReuse = DuringSession` and
// mol_ReuseCalls is `DuringRequest` — and every other common module in the extension is `DontUse`. So
// mol_Reuse is the only place where a returned value is shared across calls, which is also why it
// forwards to the forced-recompute entry points: Moleculer.GetConfig(True) and its siblings.
//
// How the mechanism is observed: a reused value is the *same object* on the next call, not merely an
// equal one. The HTTP connection cache returns a Map, so writing into it and reading it back through a
// second call shows whether the platform handed the same value over. RefreshReusableValues() is then
// the documented way to drop it.
//
// This suite lives in the shared tree, so it runs in both extension mode and standalone mode. The
// content of the cached helpers (the regex and alignment builders) is covered by mol_ReuseTests; this
// suite is about the caching itself.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Reuse caching")
		.ДобавитьСерверныйТест("TheConnectionCacheIsReusedWithinTheSession")
		.ДобавитьСерверныйТест("RefreshReusableValuesDropsTheReusedValue")
		.ДобавитьСерверныйТест("TheForcedLookupsBypassTheCache")
		.ДобавитьСерверныйТест("BSPVersionAsNumberFollowsTheSubsystemVersion");

EndProcedure

Procedure TheConnectionCacheIsReusedWithinTheSession() Export

	// DuringSession means the first caller creates the Map and every later caller receives the same one.
	// A marker key is the evidence: if a fresh Map came back, the marker would not be there.
	mol_Reuse.GetHTTPConnectionCache().Insert("reuse-probe", 1);

	Again = mol_Reuse.GetHTTPConnectionCache();

	ЮТест.ОжидаетЧто(Again.Get("reuse-probe"), "the same Map is returned while the session lasts").Равно(1);

	// Hygiene: this suite is not the only consumer of the extension's cached values.
	RefreshReusableValues();

EndProcedure

Procedure RefreshReusableValuesDropsTheReusedValue() Export

	// The invalidation path callers are meant to use when the settings behind a cached value change.
	mol_Reuse.GetHTTPConnectionCache().Insert("reuse-probe", 1);
	ЮТест.ОжидаетЧто(mol_Reuse.GetHTTPConnectionCache().Get("reuse-probe"), "the marker is cached first").Равно(1);

	RefreshReusableValues();

	ЮТест.ОжидаетЧто(mol_Reuse.GetHTTPConnectionCache().Get("reuse-probe") = Неопределено,
		"the refreshed call returns a fresh value, so the marker is gone").ЭтоИстина();

EndProcedure

Procedure TheForcedLookupsBypassTheCache() Export

	// The module forwards to the forced-recompute entry point, so a caller asking through mol_Reuse gets
	// current settings while the platform still pays for the recompute once per session. Routing this
	// through the facade makes the two paths indistinguishable, which is the point. The assertion
	// compares values rather than object identity, because equal values are what a caller sees.
	ЮТест.ОжидаетЧто(mol_Reuse.GetConfig().Name, "the reuse lookup answers with current settings")
		.Равно(Moleculer.GetConfig(Истина).Name);

EndProcedure

Procedure BSPVersionAsNumberFollowsTheSubsystemVersion() Export

	// The variant has no BSP integration at all: the builder leaves the region empty, so both functions
	// exist only in extension mode. This is the one test in the suite whose expectation differs by
	// variant, and the variant branch is decided by IsStandalone(), not by the infobase.
	If Moleculer.IsStandalone() Then

		// Pinning the variant's shape: the call fails rather than answering a version it cannot know, and
		// nothing in the variant calls it.
		Raised  = Ложь;
		Failure = "";

		Попытка
			mol_Reuse.BSPVersionAsNumber();
		Исключение
			Raised  = Истина;
			Failure = ОписаниеОшибки();
		КонецПопытки;

		ЮТест.ОжидаетЧто(Raised, "the variant has no BSP integration: " + Failure).ЭтоИстина();

		Return;

	EndIf;

	// The integration degrades rather than failing when the subsystem is absent: no version means zero.
	// Which branch is taken depends on the infobase, so both are asserted with the observed version
	// carried in the message.
	Version  = mol_Reuse.BSPVersion();
	AsNumber = mol_Reuse.BSPVersionAsNumber();

	If Not ValueIsFilled(Version) Then

		ЮТест.ОжидаетЧто(AsNumber, "an absent subsystem version reads as zero").Равно(0);

	Else

		Parts = StrSplit(Version, ".");
		ЮТест.ОжидаетЧто(AsNumber, "the number is derived from the version " + Version)
			.Равно(Number(Parts[0]) * 100 + Number(Parts[1]));

	EndIf;

EndProcedure

#EndRegion
