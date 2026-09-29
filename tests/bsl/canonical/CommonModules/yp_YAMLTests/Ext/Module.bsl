// Tests for the vendored Native API YAML component, and the measurements that decide
// whether the connector can use it.
//
// The component ships as vendor/YamlParserNative/YamlParser.cfe: a common module yp_YAML
// plus a binary template holding YamlParser_linux_x86_64.so and YamlParser_win_x86_64.dll.
// run-tests.sh loads it as an extra extension in canonical mode, so these tests call it
// across extensions exactly as a consumer would.
//
// Two of the tests are not about parsing:
//
//   * ItRefusesToRunInsideASafeModeWindow pins the constraint that decides the whole
//     integration. CompileServiceSchema wraps the service constructor in SetSafeMode(True),
//     and the platform forbids connecting an external component while safe mode is on, so a
//     YAML constructor cannot reach this component as the connector stands today.
//   * ReportsWhatAParseCosts measures the three layers separately, because the plausible
//     answer to "is it fast enough" depends on which layer was measured: the raw component
//     call, the module path a caller would actually use, and the platform JSON read that
//     both end with.
//
// The entry-point name is fixed by the framework: ЮТЧитательСлужебный.ИмяМетодаСценариев()
// returns the literal "ИсполняемыеСценарии".

#Region Public

Procedure ИсполняемыеСценарии() Export
	
	ЮТТесты
		.ДобавитьТестовыйНабор("yp_YAML")
		.ДобавитьСерверныйТест("TheComponentLoadsAndReportsItsVersion")
		.ДобавитьСерверныйТест("ParsesScalarsSequencesAndMappings")
		.ДобавитьСерверныйТест("ReturnsYAMLObjectsAsAMap")
		.ДобавитьСерверныйТест("ReturnsAStructureWhenTheKeysAllowIt")
		.ДобавитьСерверныйТест("ExposesTheRawComponentAnswer")
		.ДобавитьСерверныйТест("AReadFailureNamesThePosition")
		.ДобавитьСерверныйТест("RejectsAnUnknownOptionInsteadOfIgnoringIt")
		.ДобавитьСерверныйТест("ItRefusesToRunInsideASafeModeWindow")
		.ДобавитьСерверныйТест("ReportsWhatAParseCosts");
	
EndProcedure

#Region Parsing

Procedure TheComponentLoadsAndReportsItsVersion() Export
	
	Версия = yp_YAML.ВерсияКомпоненты();
	
	ЮТест.ОжидаетЧто(ТипЗнч(Версия), "the version comes back as text").Равно(Тип("Строка"));
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Версия),
		"reaching this line already proves the Linux library loaded in the platform")
		.ЭтоИстина();
	
EndProcedure

Procedure ParsesScalarsSequencesAndMappings() Export
	
	Документ = yp_YAML.РазобратьYAML(ПредставительныйДокумент());
	
	ЮТест.ОжидаетЧто(Документ["name"], "a plain scalar").Равно("probe");
	ЮТест.ОжидаетЧто(Документ["version"], "a scalar keeps its number type").Равно(1);
	
	Действие = Документ["actions"]["ping"];
	ЮТест.ОжидаетЧто(Действие["handler"], "a nested mapping").Равно("PingAction");
	ЮТест.ОжидаетЧто(Действие["params"]["value"]["type"], "a deeply nested scalar")
		.Равно("string");
	ЮТест.ОжидаетЧто(Действие["params"]["value"]["optional"], "a YAML boolean becomes a platform boolean")
		.Равно(Ложь);
	
	ЮТест.ОжидаетЧто(Документ["ports"][0], "a sequence arrives as a platform Array, so it is indexed from zero")
		.Равно(8080);
	
EndProcedure

Procedure ReturnsYAMLObjectsAsAMap() Export
	
	Документ = yp_YAML.РазобратьYAML(ПредставительныйДокумент());
	
	ЮТест.ОжидаетЧто(ТипЗнч(Документ),
		"a Map is the default because YAML keys may be 'my-key' or '1', which a Structure rejects")
		.Равно(Тип("Соответствие"));
	
EndProcedure

Procedure ReturnsAStructureWhenTheKeysAllowIt() Export
	
	Документ = yp_YAML.РазобратьYAML("name: probe" + Символы.ПС + "port: 8080", Неопределено, Истина);
	
	ЮТест.ОжидаетЧто(ТипЗнч(Документ), "the caller asked for the convenient shape")
		.Равно(Тип("Структура"));
	ЮТест.ОжидаетЧто(Документ.port, "and the values are the same ones").Равно(8080);
	
EndProcedure

Procedure ExposesTheRawComponentAnswer() Export
	
	Ответ = yp_YAML.РазобратьYAMLСОтветом("answer: 42");
	
	ЮТест.ОжидаетЧто(Ответ["ok"], "a successful parse is reported as such").Равно(Истина);
	ЮТест.ОжидаетЧто(Ответ["result"]["answer"], "the document lives under 'result'").Равно(42);
	
EndProcedure

Procedure AReadFailureNamesThePosition() Export
	
	Описание = "";
	Try
		yp_YAML.РазобратьYAML("good: 1" + Символы.ПС + "bad: [1, 2");
	Except
		Описание = ИнформацияОбОшибке().Описание;
	EndTry;
	
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Описание),
		"an unparsable document raises rather than returning something half-built")
		.ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Описание, "строк") > 0, "and it names the line")
		.ЭтоИстина();
	
EndProcedure

Procedure RejectsAnUnknownOptionInsteadOfIgnoringIt() Export
	
	Настройки = Новый Структура("duplicateKeys", "error");
	Описание = "";
	Try
		yp_YAML.РазобратьYAML("a: 1" + Символы.ПС + "a: 2", Настройки);
	Except
		Описание = ИнформацияОбОшибке().Описание;
	EndTry;
	
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Описание),
		"duplicateKeys=error has to reject the duplicate rather than let the last one win")
		.ЭтоИстина();
	
EndProcedure

#EndRegion

#Region Constraint

Procedure ItRefusesToRunInsideASafeModeWindow() Export
	
	// The same window CompileServiceSchema creates around a service constructor: safe mode on,
	// the service's own code running inside it. The component cannot be connected there, and
	// the module raises instead of silently doing nothing.
	УстановитьБезопасныйРежим(Истина);
	
	Описание = "";
	Try
		yp_YAML.РазобратьYAML("name: probe");
	Except
		Описание = ИнформацияОбОшибке().Описание;
	EndTry;
	
	УстановитьБезопасныйРежим(Ложь);
	
	ЮТест.ОжидаетЧто(Не ПустаяСтрока(Описание),
		"a YAML constructor cannot reach the component while the connector holds safe mode on")
		.ЭтоИстина();
	ЮТест.ОжидаетЧто(СтрНайти(Описание, "безопасн") > 0,
		"and the refusal explains safe mode rather than blaming the document")
		.ЭтоИстина();
	
EndProcedure

#EndRegion

#Region Measurement

Procedure ReportsWhatAParseCosts() Export
	
	Текст = ПредставительныйДокумент();
	Итераций = 100;
	
	// The first call pays for loading the library and connecting it.
	Прогрев = ТекущаяУниверсальнаяДатаВМиллисекундах();
	yp_YAML.РазобратьYAML(Текст);
	ПрогревМс = ТекущаяУниверсальнаяДатаВМиллисекундах() - Прогрев;
	
	// Layer 1: the raw component call. The module reconnects the component on every call, so
	// this includes the connection cost and returns JSON, not platform values.
	СыройJSON = yp_YAML.ПодключитьКомпоненту().РазобратьYAML(Текст, "");
	
	// Layer 0: connect once and call the same instance repeatedly. The module cannot cache the
	// component, so the gap between this and layer 1 is what reconnecting costs — the question
	// that decides whether a caller should connect once and hold the instance.
	Экземпляр = yp_YAML.ПодключитьКомпоненту();
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Для Счётчик = 1 По Итераций Цикл
		Экземпляр.РазобратьYAML(Текст, "");
	КонецЦикла;
	ОднаждыМс = ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Для Счётчик = 1 По Итераций Цикл
		yp_YAML.ПодключитьКомпоненту().РазобратьYAML(Текст, "");
	КонецЦикла;
	КомпонентаМс = ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	
	// Layer 2: what a caller would actually use — the component plus the platform JSON read
	// that turns the answer into Map/Structure/Array.
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Для Счётчик = 1 По Итераций Цикл
		yp_YAML.РазобратьYAML(Текст);
	КонецЦикла;
	МодульМс = ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	
	// Layer 3: the floor both routes share, because the sidecar also answers in JSON that the
	// platform has to read.
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Для Счётчик = 1 По Итераций Цикл
		Чтение = Новый ЧтениеJSON;
		Чтение.УстановитьСтроку(СыройJSON);
		// Истина reads JSON objects into a Map. The default reads them into a Structure, which
		// rejects keys like "$noVersionPrefix" — measured, and the reason the module passes it too.
		ПрочитатьJSON(Чтение, Истина);
		Чтение.Закрыть();
	КонецЦикла;
	JSONМс = ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	
	Сообщить(СтрШаблон(
			"yp_YAML timing, component %1, %2 iterations of a %3-byte document: warm-up %4 ms; "
			+ "reused instance %5 ms; component call %6 ms; module call %7 ms; platform JSON read %8 ms; %9",
			yp_YAML.ВерсияКомпоненты(), Итераций, СтрДлина(Текст),
			Строка(ПрогревМс), Строка(ОднаждыМс), Строка(КомпонентаМс),
			Строка(МодульМс), Строка(JSONМс), ТекстОЗагрузкеБиблиотеки()));
	ЮТест.ОжидаетЧто(МодульМс, "a parse must finish in well under a second, or it is unusable at start-up")
		.Меньше(Итераций * 1000);
	ЮТест.ОжидаетЧто(JSONМс, "the shared floor is measured too, so the component's share is interpretable")
		.Меньше(Итераций * 1000);
	
EndProcedure

// Does the time to load the library track its size? Every build still on disk under
// build/yaml-parser-builds/ is loaded here in ONE session, and each one is also read as bytes as a
// control, because a load cannot be faster than the read that feeds it. Comparing builds inside a
// single session is the point: an earlier answer got this wrong by comparing two sessions and
// measuring one order, and read a real ~11% effect as noise.
//
// Returned as text rather than printed: only the LAST Сообщить of a run reaches the log, which
// was observed twice, so a suite that prints from two tests silently loses the earlier one.
Function ТекстОЗагрузкеБиблиотеки()
	
	Найденные = НайтиФайлы("build/yaml-parser-builds", "YamlParser_linux_x86_64.so", Истина);
	Если Найденные.Количество() = 0 Тогда
		Возврат "library builds: none under build/yaml-parser-builds";
	КонецЕсли;
	
	Сборки = Новый Массив;
	Для Каждого Файл Из Найденные Цикл
		Сборки.Добавить(Файл);
	КонецЦикла;
	
	// Exchange sort by size so the report reads smallest to largest and the trend is visible
	// without cross-referencing numbers.
	Для Первый = 0 По Сборки.Количество() - 2 Цикл
		Для Второй = Первый + 1 По Сборки.Количество() - 1 Цикл
			Если Сборки[Второй].Размер() < Сборки[Первый].Размер() Тогда
				Обмен = Сборки[Первый];
				Сборки[Первый] = Сборки[Второй];
				Сборки[Второй] = Обмен;
			КонецЕсли;
		КонецЦикла;
	КонецЦикла;
	
	Итераций = 30;
	Части = Новый Массив;
	Имена = СтрРазделить("YPBuildA,YPBuildB,YPBuildC,YPBuildD", ",");
	
	// The path form matters: the relative path below was refused where an absolute one worked, so
	// both are tried and the report says which was used.
	Для Индекс = 0 По Сборки.Количество() - 1 Цикл
		Файл = Сборки[Индекс];
		Путь = Файл.ПолноеИмя;
		Сегменты = СтрРазделить(Файл.Путь, "/");
		Метка = Сегменты[Сегменты.Количество() - 1];
		Имя = Имена[Индекс];
		
		// Warm the page cache so the first read is not charged to any one build.
		ПрочитатьФайл(Путь);
		ЧтениеМс = ЗамеритьЧтение(Путь, Итераций);
		
		ПодключениеМс = ЗамеритьПодключение(Путь, Имя, Итераций);
		Форма = "relative";
		
		Если ПодключениеМс = Неопределено Тогда
			Абсолютный = "/tmp/yaml-parser-builds/" + Метка + "/YamlParser_linux_x86_64.so";
			ПодключениеМс = ЗамеритьПодключение(Абсолютный, Имя, Итераций);
			Форма = "absolute";
		КонецЕсли;
		
		Если ПодключениеМс = Неопределено Тогда
			Части.Добавить(СтрШаблон("%1 %2 B read %3 ms connect refused",
				Метка, Строка(Файл.Размер()), Строка(ЧтениеМс)));
		Иначе
			Части.Добавить(СтрШаблон("%1 %2 B read %3 ms connect %4 ms (%5)",
				Метка, Строка(Файл.Размер()), Строка(ЧтениеМс), Строка(ПодключениеМс), Форма));
		КонецЕсли;
	КонецЦикла;
	
	Возврат "library builds (" + Строка(Итераций) + " iterations each): "
		+ СтрСоединить(Части, "; ");
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// A document the size and shape of a real service definition: a few mappings, a nested action
// with typed params, and a sequence.
Function ПредставительныйДокумент()
	
	Возврат "name: probe
	|version: 1
	|settings:
	|  $noVersionPrefix: true
	|actions:
	|  ping:
	|    handler: PingAction
	|    params:
	|      value:
	|        type: string
	|        optional: false
	|  echo:
	|    handler: EchoAction
	|events:
	|  changed: {}
	|ports:
	|  - 8080
	|  - 8443";
	
EndFunction

Function ПрочитатьФайл(Путь)
	
	Возврат Новый ДвоичныеДанные(Путь);
	
EndFunction

Function ЗамеритьЧтение(Путь, Итераций)
	
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Для Счётчик = 1 По Итераций Цикл
		ПрочитатьФайл(Путь);
	КонецЦикла;
	
	Возврат ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	
EndFunction


Function ЗамеритьПодключение(Путь, Имя, Итераций)
	
	Если Не ПодключитьВнешнююКомпоненту(Путь, Имя, ТипВнешнейКомпоненты.Native) Тогда
		// Deliberately not raised: a probe that cannot connect one build must still report the
		// others, and it must never take the parse measurement down with it.
		Возврат Неопределено;
	КонецЕсли;
	
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Для Счётчик = 1 По Итераций Цикл
		ПодключитьВнешнююКомпоненту(Путь, Имя, ТипВнешнейКомпоненты.Native);
	КонецЦикла;
	
	Возврат ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	
EndFunction

#EndRegion