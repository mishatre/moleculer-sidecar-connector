// Behavioural tests for the overridable provider in extension mode.
//
// Mode note: this module is a seam, not an implementation. In extension mode every procedure returns
// without touching its argument, because the mol_* catalogs are the source of truth there; the
// standalone builder replaces the whole module with a generated one whose bodies do fill the
// collections from a deployment profile. So the contract asserted here is inertness, and the
// filling contract is asserted by tests/bsl/standalone.
//
// The gateway is Moleculer.IsStandalone(), which reports whether Catalog.mol_Services resolves. That
// makes the gate load-bearing: if the provider ever filled data in extension mode, connections and
// publications would be duplicated rather than merely redundant.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export

	ЮТТесты
		.ДобавитьТестовыйНабор("Overridable provider (extension mode)")
		.ДобавитьСерверныйТест("ExtensionModeIsNotStandalone")
		.ДобавитьСерверныйТест("EveryProcedureIsCallableWithEmptyCollections")
		.ДобавитьСерверныйТест("GetConfigIsInertInExtensionMode")
		.ДобавитьСерверныйТест("GetConnectionsIsInertInExtensionMode")
		.ДобавитьСерверныйТест("GetPublicationsIsInertInExtensionMode")
		.ДобавитьСерверныйТест("GetServiceModulesIsInertInExtensionMode")
		.ДобавитьСерверныйТест("GetServicesIsInertInExtensionMode");

EndProcedure

Procedure ExtensionModeIsNotStandalone() Export

	// Every other test here asserts what the provider does in extension mode. If that gate ever
	// changes, all of those expectations become wrong, so the premise is asserted rather than assumed.
	ЮТест.ОжидаетЧто(Moleculer.IsStandalone(), "the canonical extension is not standalone").ЭтоЛожь();

EndProcedure

Procedure EveryProcedureIsCallableWithEmptyCollections() Export

	// The acceptance asks that every provider procedure is reached. In this mode each is reached and
	// deliberately does nothing, so accepting the documented argument types and returning quietly is
	// the whole contract.
	Config       = Moleculer.NewConfigParams();
	Connections  = Новый Массив;
	Publications = Новый Массив;
	Modules      = Новый Массив;
	Services     = Новый Массив;

	MoleculerOverridable.GetConfig(Config);
	MoleculerOverridable.GetConnections(Connections);
	MoleculerOverridable.GetPublications(Publications);
	MoleculerOverridable.GetServiceModules(Modules);
	MoleculerOverridable.GetServices(Services);

	ЮТест.ОжидаетЧто(Connections.Количество(), "connections stay empty").Равно(0);
	ЮТест.ОжидаетЧто(Publications.Количество(), "publications stay empty").Равно(0);
	ЮТест.ОжидаетЧто(Modules.Количество(), "service modules stay empty").Равно(0);
	ЮТест.ОжидаетЧто(Services.Количество(), "services stay empty").Равно(0);

EndProcedure

Procedure GetConfigIsInertInExtensionMode() Export

	// A sentinel in each nesting level, so a provider that filled the top level but reached into the
	// launch parameters would still be caught.
	Config = Moleculer.NewConfigParams();
	Config.Name = "marker";
	Config.LaunchParameters.Enable = "marker";

	MoleculerOverridable.GetConfig(Config);

	ЮТест.ОжидаетЧто(Config.Name, "the provider fills nothing in extension mode").Равно("marker");
	ЮТест.ОжидаетЧто(Config.LaunchParameters.Enable, "nested fields are left alone too").Равно("marker");
	ЮТест.ОжидаетЧто(Config.UUID = Неопределено, "a field nobody set stays undefined").ЭтоИстина();

EndProcedure

Procedure GetConnectionsIsInertInExtensionMode() Export

	// The catalogs are the source of truth here, so a connection invented by the provider would be
	// duplicated or wrong. The marker also proves the caller's collection is left alone rather than
	// replaced, which is the mutation semantics the acceptance asks to pin.
	Connections = Новый Массив;
	Marker = Moleculer.NewConnectionParams();
	Marker.Id = "marker";
	Connections.Add(Marker);

	MoleculerOverridable.GetConnections(Connections);

	ЮТест.ОжидаетЧто(Connections.Количество(), "the provider adds nothing in extension mode").Равно(1);
	ЮТест.ОжидаетЧто(Connections[0].Id, "the caller's collection is left alone").Равно("marker");

EndProcedure

Procedure GetPublicationsIsInertInExtensionMode() Export

	Publications = Новый Массив;
	Marker = Moleculer.NewPublicationParams();
	Marker.Id = "marker";
	Publications.Add(Marker);

	MoleculerOverridable.GetPublications(Publications);

	ЮТест.ОжидаетЧто(Publications.Количество(), "the provider adds nothing in extension mode").Равно(1);
	ЮТест.ОжидаетЧто(Publications[0].Id, "the caller's collection is left alone").Равно("marker");

EndProcedure

Procedure GetServiceModulesIsInertInExtensionMode() Export

	Modules = Новый Массив;
	Modules.Add("marker");

	MoleculerOverridable.GetServiceModules(Modules);

	ЮТест.ОжидаетЧто(Modules.Количество(), "the provider adds nothing in extension mode").Равно(1);
	ЮТест.ОжидаетЧто(Modules[0], "the caller's collection is left alone").Равно("marker");

EndProcedure

Procedure GetServicesIsInertInExtensionMode() Export

	Services = Новый Массив;
	Services.Add("marker");

	MoleculerOverridable.GetServices(Services);

	ЮТест.ОжидаетЧто(Services.Количество(), "the provider adds nothing in extension mode").Равно(1);
	ЮТест.ОжидаетЧто(Services[0], "the caller's collection is left alone").Равно("marker");

EndProcedure

#EndRegion
