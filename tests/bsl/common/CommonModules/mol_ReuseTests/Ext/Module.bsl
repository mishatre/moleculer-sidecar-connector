////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Behavioural tests for mol_Reuse — the module that owns reusable values.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Reuse")
		.ДобавитьСерверныйТест("GetRegexCacheEscapesLeadingDollar")
		.ДобавитьСерверныйТест("GetRegexCacheTurnsQuestionMarkIntoAnyCharacter")
		.ДобавитьСерверныйТест("GetRegexCacheTurnsSingleStarIntoOneSegment")
		.ДобавитьСерверныйТест("GetRegexCacheTurnsDoubleStarIntoManySegments")
		.ДобавитьСерверныйТест("GetAlignmentBufferFillsEveryByte");

EndProcedure

// A pattern starting with "$" must stay literal, so the dollar is escaped.
Procedure GetRegexCacheEscapesLeadingDollar() Export

	ЮТест.ОжидаетЧто(mol_Reuse.GetRegexCache("$metadata"),
			"a leading dollar must be escaped so it stays literal")
		.Равно("^\\$metadata$");

EndProcedure

Procedure GetRegexCacheTurnsQuestionMarkIntoAnyCharacter() Export

	ЮТест.ОжидаетЧто(mol_Reuse.GetRegexCache("a?b"))
		.Равно("^a.b$");

EndProcedure

// A single "*" spans one path segment, so it must not match a dot.
Procedure GetRegexCacheTurnsSingleStarIntoOneSegment() Export

	ЮТест.ОжидаетЧто(mol_Reuse.GetRegexCache("a*b"))
		.Равно("^a[^\\.]*b$");

EndProcedure

// A double "**" spans any number of segments.
Procedure GetRegexCacheTurnsDoubleStarIntoManySegments() Export

	ЮТест.ОжидаетЧто(mol_Reuse.GetRegexCache("a**b"))
		.Равно("^a.*b$");

EndProcedure

// BinaryDataBuffer exposes no size accessor, so the block size is validated by reading
// every byte of the block: a buffer shorter than BlockSize would raise on the last read.
Procedure GetAlignmentBufferFillsEveryByte() Export

	BlockSize = 4;
	FillValue = 65;
	Buffer = mol_Reuse.GetAlignmentBuffer(BlockSize, FillValue);

	For Index = 0 To BlockSize - 1 Do

		ЮТест.ОжидаетЧто(Buffer.Get(Index),
				StrTemplate("byte %1 must carry the fill value", Index))
			.Равно(FillValue);

	EndDo;

EndProcedure

#EndRegion
