# Тесты

Две независимые группы:

- **BSL-тесты** (`tests/bsl/`) — поведенческие тесты коннектора на языке 1С, исполняются
  внутри 1С через YAxUnit. Требуют лицензию 1С.
- **Тесты конструктора** (`tests/standalone-builder/`) — контейнерные Python-тесты
  генератора автономного варианта. Лицензия не нужна.

## BSL-тесты (YAxUnit)

### Запуск

```bash
tools/standalone-builder/build-standalone.py    # пересобрать проверяемый вариант
tests/bsl/run-tests.sh                          # собрать тестовое расширение и прогнать
tests/bsl/run-tests.sh --rebuild-base           # пересоздать тестовую базу
tests/bsl/run-tests.sh --tests MoleculerTests.IsStringAcceptsString
```

Отчёт: `build/test/reports/yaxunit.xml` (jUnit), журнал `build/test/reports/run.log`,
код возврата — в `build/test/reports/exitcode.txt`. Ненулевой код возврата означает
проваленный тест или ошибку исполнения.

Зависимости: JDK 21, `vrunner`, `build/vendor/yaxunit/YAxUnit.cfe`,
`build/vendor/md-sparrow/md-sparrow-0.6.3-all.jar`.

### Как это устроено

`run-tests.sh` собирает **тестовое расширение** `MoleculerTests`:

1. каркас расширения создаётся `md-sparrow init-empty-cfe`;
2. каждый каталог `tests/bsl/CommonModules/<Имя>` регистрируется как общий модуль
   (`md-sparrow add-md-object --type COMMON_MODULE`), его `Ext/Module.bsl` копируется;
3. расширение компилируется `vrunner cfe compile`;
4. в одноразовую базу `build/ib-tests` грузятся три расширения — проверяемый коннектор,
   YAxUnit и тестовое расширение;
5. `vrunner test yaxunit --ext MoleculerTests` прогоняет тесты и пишет jUnit-отчёт.

Проверяемое расширение берётся готовым артефактом, поэтому перед прогоном нужен
`tools/standalone-builder/build-standalone.py`.

### Грабли, уже проверенные в этом контейнере

- **Безопасный режим.** `vrunner infobase init --ibcmd` оставляет расширениям режим по
  умолчанию — включённый. YAxUnit в безопасном режиме не может прочитать файл параметров
  и падает с «Расширение подключено в безопасном режиме. Чтение конфигурационного файла
  недоступно». Свойства снимаются через `vrunner cfe load --ibcmd --active`: именно флаг
  `--active` заставляет vrunner пойти в ветку установки свойств, которая заодно ставит
  `safe-mode=false`. Проверка: `ibcmd extension --db-path=<база> list` → `safe-mode : no`.
- **Дефис в имени.** `vrunner cfe load` не принимает имена со спецсимволами, поэтому
  `YAxUnit-25.12.cfe` загружается из копии `YAxUnit.cfe` — имя расширения `YAXUNIT`.
- **Точка входа.** Метод регистрации тестов жёстко задан фреймворком:
  `ЮТЧитательСлужебный.ИмяМетодаСценариев()` возвращает строку `"ИсполняемыеСценарии"`.
- **Нейтральный каталог.** `vrunner` автоматически подхватывает `autumn-properties.json`,
  который прибивает `ibconnection` к `build/ib`, поэтому компиляция идёт из временного
  каталога.
- **Проверки платформы не компилируют модули.** `vrunner cfe compile`, `ibcmd config check`
  и `/CheckModules` загружают метаданные, не разбирая тела модулей, поэтому
  компиляционная ошибка видна только при реальном исполнении.

### Режимность тестов

`tools/standalone-builder` **сливает** 10 общих модулей (`Moleculer`, `mol_Errors`,
`mol_Logger`, `mol_Helpers`, `mol_HelpersClientServer`, `mol_Transport`,
`mol_ContextFactory`, `mol_Broker`, `mol_SchemaFactory`, `mol_Internal`) в один модуль
`Moleculer` и **оставляет** только `mol_Reuse` и `mol_ReuseCalls`. Поверхность вызовов
различается:

| Набор | Что вызывает | Где применим |
|---|---|---|
| `mol_ReuseTests` | `mol_Reuse.*` | обе базы (модуль сохранён) |
| `MoleculerTests` | `Moleculer.*` | автономная база (слитая поверхность) |

Наборы для расширенной базы, обращающиеся к `mol_Helpers.*` напрямую, должны лежать
отдельно.

### Что уже найдено

- `mol_ContextFactory.Emit` вызывал процедуру `mol_Broker.Emit` как функцию — модуль не
  компилировался, и ни одна статическая проверка этого не видела. Исправлено (функция
  стала процедурой). Поиск таких мест для регрессии:
  `tools/bsl-checks/find-procedure-as-function.py`.

## Тесты конструктора

```bash
python3 -m unittest discover -s tests/standalone-builder -v
```

## Остальное

Скриптовые тесты OneScript (*.os) запускаются через 1testrunner или OneUnit. Бинарные
файлы тестов здесь не хранятся: дымовые наборы Vanessa-ADD поставляются в составе
пакета `add` (`oscript_modules`).
