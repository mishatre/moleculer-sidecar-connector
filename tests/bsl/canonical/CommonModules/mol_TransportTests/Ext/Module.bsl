////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Behavioural tests for the outbound transport half.
//
// Mechanism under test: mol_Transport's wire contract. T018's stop condition said the outbound paths
// cannot be exercised without a live sidecar, so the transport was split along its network boundary and
// the suite reaches the halves directly. What each test drives, by name:
//
//   ToPacket                        the packet the transport builds from a payload
//   SetPacketAsRequestResponseBody  the body: JSON, or a multipart form when the packet carries a stream
//   FromJSONPacketBody              the JSON parser, including the bare error object a failed call returns
//   FromMultipartPacketBody         the multipart parser
//   PrepareHTTPRequest              the header set, the signed subset and the timeout, before any call
//   ResponseFromStatus              the non-2xx branch, turned into an error response
//   ExecuteRequest                  the whole path, used to check safe mode survives a failure
//
// Mode note: canonical only. The standalone variant merges mol_Transport into Moleculer; the variant's own
// transport defects are T032 and T035, not this suite's subject.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Transport")
		.ДобавитьСерверныйТест("ThePacketCarriesThePayloadAndTheSender")
		.ДобавитьСерверныйТест("AStreamPayloadBecomesThePacketStream")
		.ДобавитьСерверныйТест("TheJSONFormRoundTripsIntoTheSamePacket")
		.ДобавитьСерверныйТест("TheStreamFormIsMultipartAndRoundTrips")
		.ДобавитьСерверныйТест("TheOutboundHeaderSetCarriesTheSignedSubset")
		.ДобавитьСерверныйТест("TheTimeoutComesFromThePayload")
		.ДобавитьСерверныйТест("ABareErrorObjectBecomesAnErrorResponse")
		.ДобавитьСерверныйТест("ASuccessfulResponseCarriesThePacketData")
		.ДобавитьСерверныйТест("TheFailurePathRestoresSafeMode");

EndProcedure

Procedure ThePacketCarriesThePayloadAndTheSender() Export

	// mol_Transport.ToPacket — the envelope built from the payload. The sender is compared with the
	// configuration it comes from rather than with a literal, so a fixture cannot drift away from it.
	Payload = PayloadFixture();
	Packet  = mol_Transport.ToPacket(Payload, ContextFixture());

	ЮТест.ОжидаетЧто(Packet.sender, "the sender is the configured node identifier")
		.Равно(mol_Broker.NodeID());
	ЮТест.ОжидаетЧто(Packet.data.action, "the payload travels as the packet data")
		.Равно("probe.action");
	ЮТест.ОжидаетЧто(Packet.stream, "a payload without a stream carries no stream marker")
		.Равно(Ложь);
	ЮТест.ОжидаетЧто(ТипЗнч(Packet.meta), "meta travels as a map").Равно(Тип("Соответствие"));

EndProcedure

Procedure AStreamPayloadBecomesThePacketStream() Export

	// mol_Transport.ToPacket — the branch that decides a packet carries a stream, which is what makes the
	// encoder pick the multipart form instead of JSON.
	Stream = StreamFixture("stream-payload");
	Packet = mol_Transport.ToPacket(PayloadFixture(), ContextFixture(Stream));

	ЮТест.ОжидаетЧто(mol_Helpers.IsStream(Packet.stream), "the stream travels on the packet").ЭтоИстина();

EndProcedure

Procedure TheJSONFormRoundTripsIntoTheSamePacket() Export

	// mol_Helpers.ToJSONString + mol_Transport.FromJSONPacketBody — the non-stream body form. The packet is
	// the unit under test: what goes out and comes back must describe the same call, because that is
	// exactly what the sidecar receives.
	Packet = mol_Transport.ToPacket(PayloadFixture(), ContextFixture());
	Back   = mol_Transport.FromJSONPacketBody(mol_Helpers.ToJSONString(Packet));

	ЮТест.ОжидаетЧто(Back.data.action, "the action survives the round trip").Равно(Packet.data.action);
	ЮТест.ОжидаетЧто(Back.sender, "the sender survives the round trip").Равно(Packet.sender);
	ЮТест.ОжидаетЧто(Back.Количество(), "the packet keeps its field count: " + Строка(Back.Количество()))
		.Равно(Packet.Количество());

EndProcedure

Procedure TheStreamFormIsMultipartAndRoundTrips() Export

	// mol_Transport.SetPacketAsRequestResponseBody + mol_Helpers.DecodeMultipartData +
	// mol_Transport.FromMultipartPacketBody — the body form for a stream payload. Two parts are expected:
	// the packet as JSON and the stream as a file. No sidecar is needed because the encoder writes into the
	// request object, which a test can then read back.
	Request = New HTTPRequest();
	Packet  = mol_Transport.ToPacket(PayloadFixture(), ContextFixture(StreamFixture("stream-payload")));

	PackingResult = mol_Transport.SetPacketAsRequestResponseBody(Request, Packet);

	ЮТест.ОжидаетЧто(СтрНайти(PackingResult.ContentType, "multipart/form-data") = 1,
		"a stream payload is a multipart form, got: " + PackingResult.ContentType).ЭтоИстина();
	ЮТест.ОжидаетЧто(PackingResult.Size > 0, "the form has a body").ЭтоИстина();

	Headers = Новый Соответствие;
	Headers.Вставить("Content-Type", PackingResult.ContentType);

	Body = Request.GetBodyAsStream();
	Body.Перейти(0, ПозицияВПотоке.Начало);

	Data = mol_Helpers.DecodeMultipartData(Body, Headers);
	Back = mol_Transport.FromMultipartPacketBody(Data);

	ЮТест.ОжидаетЧто(Back.data.action, "the packet part survives the form").Равно("probe.action");
	ЮТест.ОжидаетЧто(mol_Helpers.IsStream(Back.Stream), "the stream part comes back as a stream").ЭтоИстина();

EndProcedure

Procedure TheOutboundHeaderSetCarriesTheSignedSubset() Export

	// mol_Transport.PrepareHTTPRequest — what actually goes on the wire. Five headers are expected: two the
	// body decides, two SigV4 adds, and the authorization header itself. The names are collected from the
	// request instead of asserted one by one, so a failure prints the set that was really sent.
	Packet   = mol_Transport.ToPacket(PayloadFixture(), ContextFixture());
	Prepared = mol_Transport.PrepareHTTPRequest(LiveConnection(), Packet);
	Headers  = Prepared.Request.Headers;

	Names = "";
	For Each Pair In Headers Do
		Names = Names + Lower(Строка(Pair.Ключ)) + ";";
	EndDo;

	Missing = "";
	Found   = "";
	For Each Expected In HeaderNamesFixture() Do
		If mol_Helpers.Get(Headers, Expected, Неопределено, Истина) = Неопределено Then
			Missing = Missing + Expected + ";";
		Else
			Found = Found + Expected + ";";
		EndIf;
	EndDo;

	ЮТест.ОжидаетЧто(Missing,
		"the outbound header set is missing none of the expected names; sent: " + Names + " found: " + Found)
		.Равно("");

	ЮТест.ОжидаетЧто(Prepared.Request.ResourceAddress, "the request targets the sidecar path")
		.Равно("/sidecar");

	Authorization = mol_Helpers.Get(Headers, "authorization", "", Истина);

	ЮТест.ОжидаетЧто(СтрНайти(Authorization, "Credential=" + LiveConnection().AccessKey) > 0,
		"the authorization header names the credential: " + Authorization).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Authorization, "x-amz-content-sha256") > 0,
		"the signed subset covers the payload hash: " + Authorization).ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Authorization, "x-amz-date") > 0,
		"the signed subset covers the date: " + Authorization).ЭтоИстина();

EndProcedure

Procedure TheTimeoutComesFromThePayload() Export

	// mol_Transport.PrepareHTTPRequest — Moleculer counts the timeout in milliseconds and HTTPConnection in
	// seconds, so the conversion is part of the contract rather than a detail. A payload that does not carry
	// the field at all leaves the default; a payload that carries zero asks for none.
	Silent = PayloadFixture();
	Silent.Удалить("timeout");

	Prepared = mol_Transport.PrepareHTTPRequest(LiveConnection(), mol_Transport.ToPacket(Silent, ContextFixture()));
	ЮТест.ОжидаетЧто(Prepared.Timeout, "a payload without the field leaves the default timeout").Равно(120);

	Zero = PayloadFixture();

	Prepared = mol_Transport.PrepareHTTPRequest(LiveConnection(), mol_Transport.ToPacket(Zero, ContextFixture()));
	ЮТест.ОжидаетЧто(Prepared.Timeout, "a payload asking for zero milliseconds keeps zero").Равно(0);

	Converted = PayloadFixture();
	Converted.timeout = 5000;

	Prepared = mol_Transport.PrepareHTTPRequest(LiveConnection(), mol_Transport.ToPacket(Converted, ContextFixture()));
	ЮТест.ОжидаетЧто(Prepared.Timeout, "the payload's milliseconds become seconds").Равно(5);

EndProcedure

Procedure ABareErrorObjectBecomesAnErrorResponse() Export

	// mol_Transport.FromJSONPacketBody + mol_Transport.ResponseFromStatus — a failed call is answered with a
	// bare error object rather than a packet, and that object is the only diagnostic the caller gets. The
	// status branch has to turn it into an error response instead of a successful one.
	Error = mol_Errors.ServerError("ServiceUnavailable", 503, "the node is not available");

	Packet   = mol_Transport.FromJSONPacketBody(mol_Helpers.ToJSONString(Error));
	Response = mol_Transport.ResponseFromStatus(503, Packet);

	ЮТест.ОжидаетЧто(mol_Helpers.IsErrorResponse(Response), "a non-200 status is an error response")
		.ЭтоИстина();
	ЮТест.ОжидаетЧто(Response.Error.Message, "the remote message survives").Равно("the node is not available");
	ЮТест.ОжидаетЧто(Response.Error.Code, "the remote code survives").Равно(503);
	ЮТест.ОжидаетЧто(Response.Error.Type, "the remote type survives").Равно("ServiceUnavailable");

EndProcedure

Procedure ASuccessfulResponseCarriesThePacketData() Export

	// mol_Transport.ResponseFromStatus — the successful half, including the repair the transport makes when a
	// sidecar answers without a data field: the caller always sees one, so a caller that reads it does not
	// fail on a packet that simply had nothing to say.
	Packet   = Новый Структура("sender, data", "node-1", Новый Структура("ok", Истина));
	Response = mol_Transport.ResponseFromStatus(200, Packet);

	ЮТест.ОжидаетЧто(mol_Helpers.IsErrorResponse(Response), "a 200 is not an error response").ЭтоЛожь();
	ЮТест.ОжидаетЧто(Response.Result.data.ok, "the data reaches the caller").ЭтоИстина();
	ЮТест.ОжидаетЧто(Response.Result.sender, "the packet itself is the result").Равно("node-1");

	Silent   = Новый Структура("sender", "node-1");
	Repaired = mol_Transport.ResponseFromStatus(200, Silent);

	ЮТест.ОжидаетЧто(Repaired.Result.Property("data"), "the transport supplies the missing data field")
		.ЭтоИстина();

EndProcedure

Procedure TheFailurePathRestoresSafeMode() Export

	// mol_Transport.ExecuteRequest → Send → Transporter_HTTP_Send — the failure path, which is the one that
	// matters: the send turns safe mode off before the call and must turn it back on whatever happens.
	//
	// The control proves the flag is observable here at all. Without it a restored-but-inert flag would make
	// this test pass by doing nothing, which is the failure mode this suite exists to avoid.
	Before = ПолучитьОтключениеБезопасногоРежима();

	УстановитьОтключениеБезопасногоРежима(Истина);
	ЮТест.ОжидаетЧто(ПолучитьОтключениеБезопасногоРежима(), "the safe-mode flag is observable here")
		.ЭтоИстина();
	УстановитьОтключениеБезопасногоРежима(Ложь);

	Payload = PayloadFixture();
	Payload.timeout = 5000;

	Raised  = Ложь;
	Failure = "";

	Попытка
		mol_Transport.ExecuteRequest(ContextFixture(), DeadConnection());
	Исключение
		Raised  = Истина;
		Failure = ОписаниеОшибки();
	КонецПопытки;

	ЮТест.ОжидаетЧто(Raised, "a call to a closed port must raise: " + Failure).ЭтоИстина();
	ЮТест.ОжидаетЧто(ПолучитьОтключениеБезопасногоРежима(),
		"the failure path must restore safe mode; before=" + Строка(Before)).Равно(Before);

EndProcedure

#EndRegion

#Region Private

// The five headers the transport is expected to send. Kept as data so the loop above reports the whole set.
Function HeaderNamesFixture()

	Result = Новый Массив;
	Result.Добавить("content-type");
	Result.Добавить("content-length");
	Result.Добавить("x-amz-date");
	Result.Добавить("x-amz-content-sha256");
	Result.Добавить("authorization");

	Return Result;

EndFunction

// The outbound context, in the structure form of Action that mol_ContextFactory.ToPayload reads. Only the
// fields that function touches are populated, so a failure points at the contract rather than at a fixture
// that drifted.
Function ContextFixture(Stream = Неопределено)

	Context = Новый Структура;
	Context.Insert("Id"       , "probe-1");
	Context.Insert("Action"   , Новый Структура("Name", "probe.action"));
	Context.Insert("EventName"  , Неопределено);
	Context.Insert("EventGroups", Неопределено);
	Context.Insert("EventType"  , Неопределено);
	Context.Insert("Params"   , Новый Структура);
	Context.Insert("Meta"     , Новый Массив);
	Context.Insert("Locals"   , Новый Структура);
	Context.Insert("Level"    , 1);
	Context.Insert("Tracing"  , Ложь);
	Context.Insert("ParentID" , 0);
	Context.Insert("RequestID", "probe-1");
	Context.Insert("Caller"   , "probe");
	Context.Insert("NeedAck"  , Ложь);
	Context.Insert("Options"  , Новый Структура("Timeout, Stream", 5000, Stream));
	Context.Insert("Stream"   , Неопределено);

	Return Context;

EndFunction

// The action payload as data, matching what mol_ContextFactory.ToPayload emits.
Function PayloadFixture()

	Payload = Новый Структура;
	Payload.Insert("id"       , "probe-1");
	Payload.Insert("action"   , "probe.action");
	Payload.Insert("params"   , Новый Структура);
	Payload.Insert("meta"     , Новый Соответствие);
	Payload.Insert("timeout"  , 0);
	Payload.Insert("locals"   , Новый Структура);
	Payload.Insert("level"    , 1);
	Payload.Insert("tracing"  , Ложь);
	Payload.Insert("parentID" , 0);
	Payload.Insert("requestID", "probe-1");
	Payload.Insert("caller"   , "probe");
	Payload.Insert("stream"   , Ложь);

	Return Payload;

EndFunction

// A connection that is never contacted: the header tests stop before the call. It carries every field the
// transport reads from a connection, so the fixture cannot hide a missing one.
Function LiveConnection()

	Result = Новый Структура;
	Result.Insert("Id"         , "probe-connection");
	Result.Insert("Description", "never contacted");
	Result.Insert("Default"    , Ложь);
	Result.Insert("Type"       , "HTTP");
	Result.Insert("Endpoint"   , "127.0.0.1");
	Result.Insert("Port"       , 8314);
	Result.Insert("UseSSL"     , Ложь);
	Result.Insert("AccessKey"  , "AKIAEXAMPLE");
	Result.Insert("SecretKey"  , "secret-key");
	Result.Insert("Timeout"    , 1);
	Result.Insert("Proxy"      , Неопределено);

	Return Result;

EndFunction

// A connection that fails immediately: nothing listens on a closed loopback port, so the send reaches its
// failure path without a sidecar and without waiting for a network timeout.
Function DeadConnection()

	Result = LiveConnection();
	Result.Id = "dead-connection";
	Result.Port = 1;

	Return Result;

EndFunction

// Writes through a DataWriter rather than the stream's own write method, because that is the pattern the
// encoder itself uses, so a fixture cannot disagree with the transport about what a stream looks like.
Function StreamFixture(Content)

	Result = Новый ПотокВПамяти;
	Writer = New DataWriter(Result, КодировкаТекста.UTF8, ПорядокБайтов.LittleEndian, "", "", Ложь);
	Writer.Write(ПолучитьДвоичныеДанныеИзСтроки(Content, КодировкаТекста.UTF8, Ложь));
	Writer.Close();

	Return Result;

EndFunction

#EndRegion
