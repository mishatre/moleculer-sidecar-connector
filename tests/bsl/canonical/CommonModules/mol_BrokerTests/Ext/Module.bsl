// Behavioural tests for mol_Broker — the module that routes calls and events.
//
// The interesting parts of the broker talk to the sidecar (Call, Emit, Broadcast, the
// publication registry), so the suite covers what is reachable without one: the identifier
// generation that the packet envelope depends on.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("mol_Broker")
		.ДобавитьСерверныйТест("GenerateUidReturnsAValue")
		.ДобавитьСерверныйТест("GenerateUidIsUniquePerCall");

EndProcedure

// NewPacket stamps every outgoing packet with an identifier, so the generator has to keep
// producing usable values.
Procedure GenerateUidReturnsAValue() Export

	Uid = mol_Broker.GenerateUid();

	ЮТест.ОжидаетЧто(Uid, "a generated identifier must not be empty").Заполнено();

EndProcedure

Procedure GenerateUidIsUniquePerCall() Export

	First = mol_Broker.GenerateUid();
	Second = mol_Broker.GenerateUid();

	ЮТест.ОжидаетЧто(First, "two calls must not produce the same identifier")
		.НеРавно(Second);

EndProcedure

#EndRegion
