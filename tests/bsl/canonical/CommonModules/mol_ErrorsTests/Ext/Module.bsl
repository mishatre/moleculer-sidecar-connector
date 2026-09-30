// Behavioural tests for mol_Errors — the error factories shared by every module.
//
// Mode note: the canonical extension keeps mol_Errors as its own common module, so the
// suite addresses it directly. The standalone variant merges it into Moleculer, where the
// same functions answer as Moleculer.*; that surface is covered by the standalone suite.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Errors")
		.ДобавитьСерверныйТест("TypeErrorIsAClientErrorWithCode400")
		.ДобавитьСерверныйТест("ServiceNotFoundIsRetryableWithCode404")
		.ДобавитьСерверныйТест("ValidationErrorCarriesCode422")
		.ДобавитьСерверныйТест("RequestTimeoutCarriesCode504")
		.ДобавитьСерверныйТест("CustomErrorDispatchesToTheNamedFactory")
		.ДобавитьСерверныйТест("CustomErrorRefusesAnUnknownType")
		.ДобавитьСерверныйТест("RaiseCustomErrorRecordsANumericCode")
		.ДобавитьСерверныйТест("MessageIsPreserved")
		.ДобавитьСерверныйТест("RegenerateErrorPreservesTheErrorShape")
		.ДобавитьСерверныйТест("ToStringIncludesTypeAndCode")
		.ДобавитьСерверныйТест("RaiseCustomErrorRaises");

EndProcedure

Procedure TypeErrorIsAClientErrorWithCode400() Export

	Error = mol_Errors.TypeError("boom");

	ЮТест.ОжидаетЧто(Error.Type, "TypeError must carry the TYPE_ERROR type").Равно("TYPE_ERROR");
	ЮТест.ОжидаетЧто(Error.Code, "client errors default to 400").Равно(400);
	ЮТест.ОжидаетЧто(Error.Name, "TypeError must be a client error").Равно("MoleculerClientError");

EndProcedure

Procedure ServiceNotFoundIsRetryableWithCode404() Export

	Error = mol_Errors.ServiceNotFound("no such service");

	ЮТест.ОжидаетЧто(Error.Code, "ServiceNotFound must be 404").Равно(404);
	ЮТест.ОжидаетЧто(Error.Name, "ServiceNotFound must be retryable").Равно("MoleculerRetryableError");

EndProcedure

Procedure ValidationErrorCarriesCode422() Export

	ЮТест.ОжидаетЧто(mol_Errors.ValidationError("bad input").Code).Равно(422);

EndProcedure

Procedure RequestTimeoutCarriesCode504() Export

	Error = mol_Errors.RequestTimeout("too slow");

	ЮТест.ОжидаетЧто(Error.Code, "RequestTimeout must be 504").Равно(504);
	ЮТест.ОжидаетЧто(Error.Name, "RequestTimeout must be a server error").Равно("MoleculerServerError");

EndProcedure

// CustomError must route a known type name to its dedicated factory.
Procedure CustomErrorDispatchesToTheNamedFactory() Export

	Error = mol_Errors.CustomError("ValidationError", "bad input");

	ЮТест.ОжидаетЧто(Error.Type, "the dedicated factory must supply the type").Равно("VALIDATION_ERROR");
	ЮТест.ОжидаетЧто(Error.Code, "the dedicated factory must supply the code").Равно(422);

EndProcedure

// An unknown type name must still produce a usable error carrying that type.
//
// The fallback used to call the base factory as Error(Type, "Error", , Message, ...), which
// put the literal "Error" in the Code position. RaiseError renders the code as Type:Code, so
// such an error read "Error: Error". Code and Name now come from the factory defaults.
Procedure CustomErrorRefusesAnUnknownType() Export

	// This test pinned the opposite until T023: an unknown type silently degraded to a generic
	// MoleculerError, so a caller that named a type the taxonomy does not have never found out. The
	// fallback now raises through RaiseError and names the type, which is what makes an undocumented type
	// a defect rather than a quiet downgrade.
	Thrown = Неопределено;

	Попытка
		Error = mol_Errors.CustomError("SomethingElse", "unexpected");
	Исключение
		Thrown = mol_Errors.GetCurrentError();
	КонецПопытки;

	// The refusal is a raised error value, so its text is read back through the ambient error rather than
	// through ОписаниеОшибки, which describes the exception and not the error the connector built.
	ЮТест.ОжидаетЧто(Thrown <> Неопределено, "an unknown type must be refused, not degraded").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Thrown.Message, "SomethingElse") > 0,
		"the refusal names the offending type").ЭтоИстина();

EndProcedure

// End-to-end guard on the same defect through the path real callers use: Moleculer raises
// an error with the type "Error" in several places, which is not one of the dispatched types
// and therefore goes through the fallback.
Procedure RaiseCustomErrorRecordsANumericCode() Export

	Thrown = False;

	Try
		mol_Errors.RaiseCustomError("Error", "boom");
	Except
		Thrown = True;
	EndTry;

	ЮТест.ОжидаетЧто(Thrown, "RaiseCustomError must raise").ЭтоИстина();
	ЮТест.ОжидаетЧто(mol_Errors.GetCurrentError().Code,
			"a raised error must carry a numeric code, not a type name")
		.Равно(500);

EndProcedure

Procedure MessageIsPreserved() Export

	ЮТест.ОжидаетЧто(mol_Errors.TypeError("the message").Message)
		.Равно("the message");

EndProcedure

Procedure RegenerateErrorPreservesTheErrorShape() Export

	Original = mol_Errors.ValidationError("bad input");
	Regenerated = mol_Errors.RegenerateError(Original);

	ЮТест.ОжидаетЧто(Regenerated.Type, "type must survive a round trip").Равно(Original.Type);
	ЮТест.ОжидаетЧто(Regenerated.Code, "code must survive a round trip").Равно(Original.Code);
	ЮТест.ОжидаетЧто(Regenerated.Name, "name must survive a round trip").Равно(Original.Name);
	ЮТест.ОжидаетЧто(Regenerated.Message, "message must survive a round trip").Равно(Original.Message);

EndProcedure

Procedure ToStringIncludesTypeAndCode() Export

	Rendered = mol_Errors.ToString(mol_Errors.ValidationError("bad input"));

	ЮТест.ОжидаетЧто(Rendered, "the rendered error must mention its type").Содержит("VALIDATION_ERROR");
	ЮТест.ОжидаетЧто(Rendered, "the rendered error must mention its code").Содержит("422");

EndProcedure

Procedure RaiseCustomErrorRaises() Export

	Thrown = False;

	Try
		mol_Errors.RaiseCustomError("ValidationError", "bad input");
	Except
		Thrown = True;
	EndTry;

	ЮТест.ОжидаетЧто(Thrown, "RaiseCustomError must raise an exception").ЭтоИстина();

EndProcedure

#EndRegion
