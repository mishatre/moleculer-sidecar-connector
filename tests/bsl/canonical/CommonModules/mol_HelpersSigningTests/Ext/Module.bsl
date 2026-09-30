// Behavioural tests for mol_Helpers' signing and stream reading.
//
// Why separate from mol_HelpersTests: that suite covers the validators, the case-insensitive lookups
// and the JSON round-trips through ToJSONString/FromJSONString. What is left of the acceptance's
// serialization item is the stream reader, and the acceptance's SignV4 item is a distinct subject, so
// this suite holds both.
//
// SignV4 is the AWS4 authorization header builder. It is deterministic by construction — every input
// feeds the HMAC chain — and that is exactly what is worth pinning: a signature that drifted between
// two identical calls would break every signed request, and a signature that did not change when an
// input changed would not be a signature at all.
//
// Mode note: canonical only, because it addresses mol_Helpers directly; the standalone variant merges
// the helpers into Moleculer and does not carry the S3 path.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Helpers signing and stream input")
		.ДобавитьСерверныйТест("SignV4IsDeterministicForFixedInputs")
		.ДобавитьСерверныйТест("SignV4ChangesWhenAnInputChanges")
		.ДобавитьСерверныйТест("SignV4ListsOnlyTheHeadersItSigns")
		.ДобавитьСерверныйТест("SignV4RefusesAnEmptyCredential")
		.ДобавитьСерверныйТест("SignV4RefusesHeadersThatAreNotAMap")
		.ДобавитьСерверныйТест("FromJSONStreamReturnsNothingWhenTheReadFails");

EndProcedure

Procedure SignV4IsDeterministicForFixedInputs() Export

	First  = SignFixture("us-east-1", "UNSIGNED-PAYLOAD");
	Second = SignFixture("us-east-1", "UNSIGNED-PAYLOAD");

	ЮТест.ОжидаетЧто(Second, "two identical calls produce the same signature").Равно(First);
	ЮТест.ОжидаетЧто(СтрНайти(First, "AWS4-HMAC-SHA256 Credential=") > 0,
		"the result is an AWS4 authorization header: " + First).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(First, ", Signature=") > 0, "the header carries a signature").ЭтоИстина();

EndProcedure

Procedure SignV4ChangesWhenAnInputChanges() Export

	// The point of a signature: every input feeds it. Region is the cheapest input to vary without
	// touching the fixture's shape.
	UsEast = SignFixture("us-east-1", "UNSIGNED-PAYLOAD");
	EuWest = SignFixture("eu-west-1", "UNSIGNED-PAYLOAD");

	ЮТест.ОжидаетЧто(EuWest = UsEast, "a different region must produce a different signature").ЭтоЛожь();

EndProcedure

Procedure SignV4ListsOnlyTheHeadersItSigns() Export

	// The ignored headers are the AWS4 ones that proxies and browsers rewrite. They must not appear in
	// SignedHeaders, or the signature would depend on something the sender does not control.
	Signature = SignFixture("us-east-1", "UNSIGNED-PAYLOAD", "text/plain");

	ЮТест.ОжидаетЧто(СтрНайти(Signature, "SignedHeaders=host;x-amz-date") > 0,
		"only host and x-amz-date are signed: " + Signature).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Signature, "content-type") = 0,
		"an ignored header is not listed: " + Signature).ЭтоИстина();

EndProcedure

Procedure SignV4RefusesAnEmptyCredential() Export

	// Signing without a key would produce a header that can never be validated, so it is refused rather
	// than returned.
	Raised  = Ложь;
	Failure = "";

	Попытка
		SignFixture("us-east-1", "UNSIGNED-PAYLOAD", "", "");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "an empty credential is refused").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "AccessKey") > 0, "the refusal names the credential: " + Failure).ЭтоИстина();

EndProcedure

Procedure SignV4RefusesHeadersThatAreNotAMap() Export

	// The header guard again, reached through the signing entry point: a Structure would silently lose
	// header order and case, so the type is enforced by the callee.
	Request = Новый Структура;
	Request.Insert("Method", "GET");
	Request.Insert("Path", "/bucket/key");
	Request.Insert("Headers", Новый Структура("host", "s3.amazonaws.com"));

	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_Helpers.SignV4(Request, "AKIAEXAMPLE", "secret", "us-east-1", Дата(2026, 9, 30), "UNSIGNED-PAYLOAD", "s3");
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "a non-Map header collection is refused").ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Failure, "Headers") > 0, "the refusal names the argument: " + Failure).ЭтоИстина();

EndProcedure

Procedure FromJSONStreamReturnsNothingWhenTheReadFails() Export

	// Current behaviour, pinned deliberately: the reader catches its exception, logs at Info level and
	// returns nothing, so a caller cannot tell a failed read from an empty document. Written to be
	// rewritten when the failure is reported rather than swallowed.
	//
	// Undefined is passed instead of a malformed stream, which reaches the same contract without the test
	// having to encode text into bytes. The successful path is not covered, and is recorded in the task:
	// building a stream from text needs a BinaryDataBuffer, which is how mol_Helpers itself does it.
	Result = mol_Helpers.FromJSONStream(Неопределено);

	ЮТест.ОжидаетЧто(Result = Неопределено,
		"CURRENT BEHAVIOUR: a failed read is reported as nothing rather than raised").ЭтоИстина();

EndProcedure

// Builds the documented fixture: a struct with the method, path and header map, plus fixed credentials.
// Empty-string credentials are accepted as arguments so the refusal path can be exercised.
Function SignFixture(Region, Sha256sum, ContentType = "", AccessKey = "AKIAEXAMPLE")

	Headers = Новый Соответствие;
	Headers.Insert("host", "s3.amazonaws.com");
	Headers.Insert("x-amz-date", "20260930T000000Z");
	If ValueIsFilled(ContentType) Then
		Headers.Insert("content-type", ContentType);
	EndIf;

	Request = Новый Структура;
	Request.Insert("Method", "GET");
	Request.Insert("Path", "/bucket/key");
	Request.Insert("Headers", Headers);

	Secret = ?(ValueIsFilled(AccessKey), "secret-key", "");

	Return mol_Helpers.SignV4(Request, AccessKey, Secret, Region, Дата(2026, 9, 30), Sha256sum, "s3");

EndFunction

#EndRegion
