# Environment — container discovery verified, 2026-09-10

## Paths and runtime

Repository root: current checkout; container root `/workspace`.
Container: Compose service `dev`, platform `linux/amd64`, remote user `root`.
Base image: `local/vrunner2:8.3.24.1667` (configured, not runtime-verified).
Platform path in debugger config: `/opt/1C/v8.3/x86_64` (unverified).
Configured post-create check: `oscript --version && opm --version`.
Codex extension requested: `openai.chatgpt`.

Source: `src/cf/`, `src/cfe/MoleculerSidecarConnector/`, `src/epf/`.
Generated data/infobases: `build/`; dependencies: `oscript_modules/`.
Packagedef declares OneScript environment 2.0.0 and vanessa-runner 2.6.1;
installed runtime/package versions require an in-container check.

## Safe initial checks

Run from `/workspace`: `pwd`, `oscript --version`, `opm --version`.
Locate installed `vrunner` and actual 1C tools without executing a build/update.
Inspect tool help only after identifying the executable. Do not dump credentials,
connection config or entire logs into chat.

## Build/export/test route

The OneScript launch entry mentions `vrunner compileext` with extension source
and `--updatedb`. It also mixes a Linux cwd with Windows environment paths.
It is evidence of intended tooling, not a validated command to copy and run.
The VS Code test entries use Windows `SET` and backslash paths; they are not
validated bash commands. The root README references scripts now absent from the
working tree. Find or establish the current commands before accepting a build task.

Canonical release version source: connector
`src/cfe/MoleculerSidecarConnector/Configuration.xml`, normalized as SemVer.
Generated connector and installer artifacts belong under `build/`.
**Superseded 2026-09-29:** the installed runner is vanessa-runner 3.0.0 and does
not implement `vrunner compileexttocfe` or `vrunner compileepf`. Use the verified
command set in "Verified toolchain — 2026-09-29" below. The commands recorded in
T002 and T005 still use the removed 2.x syntax and must be corrected before use.
The missing Autumn executable and mixed Windows/Linux VS Code commands are not
build entry points.
Disposable test infobase: `/workspace/build/ib`.
The user authorizes install, update, removal, and reset of this infobase only for
implementation tasks whose acceptance checks require those mutations.
Runtime/integration test: unknown.
GitHub CLI/authenticated release tooling: unavailable in the current container.
T005 produces a local draft-release directory; creating/publishing a GitHub
release remains a separate delivery action.

Keep these unknowns explicit. Read-only onboarding does not authorize installing
dependencies, reconstructing deleted scripts, changing application code or
updating a database. User can authorize those as the next task if required.

## T000 observed container evidence — 2026-09-10

Both cwd and Git root are `/workspace`; `/.dockerenv` exists. The shell's default
sandbox fails with bwrap namespace denial; approved escalated execution worked.

| Check | Observed result |
|---|---|
| `oscript --version` | Engine 2.1.0 banner plus usage; use `oscript -version` |
| `oscript -version` | 2.1.0 |
| `opm --version` | 1.4.1 |
| `vrunner --help` | vanessa-runner v2.6.1; documents `vrunner version` |
| `vrunner --version` | Unsupported argument; returns exit 0 despite error |
| `command -v oscript opm vrunner` | `/home/usr1cv8/.local/share/ovm/current/bin/` |
| `command -v 1cv8 1cv8c ibcmd rac ragent ras` | All found under `/opt/1cv8/current/` |
| `readlink -f /opt/1cv8/current` | `/opt/1cv8/x86_64/8.3.24.1667` |
| Configured `/opt/1C/v8.3/x86_64` | Absent; debugger configuration remains unchanged |

The 1C files have executable permissions; none was launched. Version-directory
inspection does not validate compilation, runtime, licensing or connectivity.
Earlier host/configuration observations above are retained as historical context;
the observed paths and versions in this section supersede their unknowns.

All four operation prompts, workflow, index and four templates are discoverable.
The six project agent roles are exposed by the session with matching declared
models/efforts. One `task_worker` child found the extension root Configuration.xml.
Actual coordinator and child runtime model/effort metadata is unavailable, so
loading of model defaults and model routing remain unverified. Configuration
requests two concurrent threads; session tools expose three total slots.
Graft/Serena tools are not exposed. No tools were installed or reconfigured.

Detailed acceptance evidence: [T000](tasks/workflow/history/T000-verify-workflow.md).
The direct runner command shapes and disposable target are identified. Exact
per-task commands, compilation success, runtime behavior, and deployment remain
unverified until the applicable implementation task.

## Release contract

- Git tag: `v{semver}`
- Connector asset: `MoleculerSidecarConnector-v{semver}.cfe`
- Installer asset: `MoleculerSidecarConnectorInstaller-v{semver}.epf`
- Checksums: `SHA256SUMS.txt`
- GitHub repository: `mishatre/moleculer-ones`
- The installer bundles the exact CFE released beside it.
- The CFE is **not** byte-reproducible, measured 2026-09-30: two builds of the same tree with the same
  profile produced `sha256 c5a5312c65cb…` and `sha256 9d40771201ec…`. The inputs are reproducible —
  `standalone-manifest.json` records `sourceRevision`, 13 file hashes and 64 merged-module hashes — so the
  difference comes from `vrunner cfe compile`. Trace an artifact through the manifest, never through the
  CFE hash. T005 owns the outcome this affects.
- Artifact file names must not contain spaces: a space breaks `vrunner --src` and
  `--ext` argument handling (observed 2026-09-29).

## Verified toolchain — 2026-09-29

Verified in the dev container from `/workspace`. Full evidence in
[T014](tasks/tooling/history/T014-verify-toolchain-and-test-runner.md).

### Versions and commands

| Item | Verified value |
|---|---|
| `oscript -version` | 2.1.0 |
| `opm --version` | 1.4.1 |
| `vrunner` | 3.0.0 early prerelease build |
| `vrunner` groups | `infobase`, `cfe`, `cf`, `epf`, `test`, `run`, `validate`, `repo`, `cluster` |
| `vrunner cfe` | `compile`, `unload`, `load`, `convert`, `compare`, `decompile` |
| `vrunner test` | `xunit`, `vanessa`, `yaxunit` |
| `ibcmd --version` | 8.3.24.1667 |
| `1testrunner` | 1.9.2, container-only, jUnit output |
| `1bdd` | not usable as installed (`Библиотека не найдена: 'packageinfo'`) |

### 1C client execution: libraries fixed, licence missing

Originally `1cv8` and `1cv8c` could not start at all: `libwebkit2gtk-4.0.so.37`,
`libjavascriptcoregtk-4.0.so.18` and `libsoup-2.4.so.1` were missing, and Ubuntu
24.04 ships only the 4.1/3.0 generations of those libraries.

**Resolved 2026-09-29.** `tools/1c-platform/install-client-runtime.sh` installs the
4.0-ABI libraries from Ubuntu 22.04 and replaces the platform's bundled
`libstdc++.so.6.0.28` with a symlink to the system one (the bundled copy is older
than the WebKit libraries require). The script is wired into
`.devcontainer/Dockerfile` and is idempotent — it reports
"already installed" and "already the system one" on a second run. `ldd` on `1cv8c`
now reports no missing libraries.

**Remaining blocker: a 1C licence.** The designer now starts and fails only with:

```text
Не найдена лицензия. Не обнаружен ключ защиты программы или полученная программная лицензия!
```

There is no command-line licence activation in the platform: the `licenses` entry
next to the binaries is a documentation directory, not a tool. `login.1c.ru`
redirects to the `portal.1c.ru` single-page application, so credentials cannot be
used headlessly. Activation therefore has to be done interactively once, from the
launcher or the client; the licence is then stored under `~/.1cv8/1C/` (a
`1Cv8Licence` file in `~/.1cv8/1C/` or `/var/1C/licenses/` also works, as does a
HASP key).

### Launching the infobases

The platform needs the `hostname` and `ip` commands to assemble the system report
it uses for licence validation. When they are missing it does not say so directly:
the launcher logs `/bin/sh: 1: /sbin/ip: not found` and the platform answers a
valid developer licence with **"Использование лицензии для разработчиков
запрещено"**.

Resolved 2026-09-29 by installing `inetutils-tools`, `iproute2`, `net-tools` and
`dmidecode`, wired into `.devcontainer/Dockerfile`. Verified afterwards:
`hostname` -> `ca1f5e0b996f`, `ip -o addr` lists `lo` and `eth0`, and `/sbin/ip`
resolves.

Both disposable infobases are registered in the launcher list so they can be opened
interactively for licence activation:

| List file | Contents |
|---|---|
| `~/.1C/1cestart/ibases.v8i` | the platform created this path, so it is the authoritative one |
| `~/.1cv8/1CE/ibases.v8i` | written with the same content as a fallback |

The file must be UTF-8 **with a BOM** and use **CRLF** line endings — the platform
rewrites the file in that format, and a malformed file makes the launcher show an
empty list. Entries are placed at `Folder=/` so they appear at the top level.

Helper: `tools/1c-platform/open-infobase.sh [client|designer|launcher] [ib|standalone]`,
for example `tools/1c-platform/open-infobase.sh client ib`. Direct equivalents:

```bash
/opt/1cv8/current/1cv8c "/F/workspace/build/ib"          # thin client
/opt/1cv8/current/1cv8 DESIGNER "/F/workspace/build/ib"  # designer
/opt/1cv8/current/1cv8                                   # launcher
```

Note: launching needs a display (the container exposes `DISPLAY`), and the licence
is stored inside the container, so it does not survive a container rebuild unless
`/root/.1cv8` is mounted as a volume.

Until then, still blocked: `vrunner run enterprise`,
`vrunner validate syntax-check`, and every `vrunner test yaxunit|xunit|vanessa` run.

### Alternative: verify BSL without a licence

`1c-syntax/bsl-language-server` parses BSL and reports diagnostics, and its jar is
already on disk (downloaded by the installed VS Code extension) at
`/root/.vscode-server/data/User/globalStorage/1c-syntax.language-1c-bsl/bsl-language-server/v1.0.7/bsl-language-server/lib/app/bsl-language-server-1.0.7-exec.jar`.
**Corrected 2026-09-30:** this section used to end "it needs a headless JRE, which
the image does not have". That is wrong — `/usr/bin/java` is OpenJDK 21.0.12 and
`java -jar <jar> --version` answers `version: 1.0.7`, so the analysis does run here.
`tools/bsl-checks/bsl-language-server.py` wraps it: with the default rule set the
connector's 38 modules report 780 findings (35 Error, 133 Warning, 143 Information,
469 Hint), and with the rule set selected in `.bsl-language-server.json`, 63. See
[toolkit research](notes/toolkit-research.md) for the original notes.

### Verified headless commands (use these)

```bash
# Compile an extension from XML sources (temporary base, does not touch build/ib)
vrunner cfe compile --src <XML-SRC-DIR> --ibcmd --v8version 8.3 <OUT.cfe>

# Build a disposable test infobase from a configuration source plus extensions
vrunner infobase init --src <CONFIG-SRC> --ext <CFE> \
  --ibconnection /F<BASE-PATH> --ibcmd --v8version 8.3

# Metadata-correctness check of an extension already applied to a base
ibcmd config check --db-path=<BASE-PATH> --extension=<NAME>

# Platform syntax check over an infobase that already has the extension applied
vrunner validate syntax-check --ibconnection /F<BASE-PATH> --v8version 8.3 \
  --mode ExtendedModulesCheck --junitpath <REPORT.xml> \
  --exception-file tools/syntax-check-excludes.txt

# Container-only unit tests with a jUnit report
oscript oscript_modules/1testrunner/src/main.os -runall <TESTS-DIR> xddReportPath <REPORT-DIR>
```

Notes: the positional `OUT` of `cfe compile` must follow the options; a minimal
extension source tree needs no `ConfigDumpInfo.xml`; `<Version>` accepts both
`1.0.0.0` and `0.2.0 beta 4`; an object that exists in the extended configuration
must declare `<ObjectBelonging>Adopted</ObjectBelonging>` or the extension fails
to apply.

`syntax-check` was verified on 2026-09-30 (T022) against `build/ib-tests`: it answers
`Проверка конфигурации завершена: ошибок не обнаружено` in 3 s and writes the JUnit
report. Two things about it are worth knowing. Its exception file is looked up at
`tools/syntax-check-excludes.txt` by default — the run only warns `Файл исключений не
найден` when it is missing, so a recorded command should pass `--exception-file`
explicitly. And it does not compile module bodies, so it does not see a call to a
method that does not exist; that is the BSL Language Server layer's job, and the
division is why both exist.

**`vrunner epf compile` is not a compile check either.** It packs the XML tree into an
`.epf` and never loads the module, so an external processing whose form module calls
procedures that do not exist packs successfully. Measured 2026-09-30: a refactor that
renamed call sites without their definitions passed this command and produced a
163 280-byte artifact, while the reviewer's grep showed four calls to names defined
nowhere. `vrunner cfe compile`, the designer's `/CheckModules` and `syntax-check` share
the blind spot, which is why `tools/bsl-checks/bsl-language-server.py` is the only layer
that resolves a call to a name that is not there — and why a form module needs that
layer, or a careful name inventory, before anything is claimed about it.

### Test bases

`build/ib` remains the extension-mode disposable base. Standalone-mode tests need
a second disposable base, creatable with the `infobase init` command above once
T015 produces the product; a spike base was created and verified and has been
removed.

Current state: `build/ib` is the canonical harness base (base configuration plus
the connector and YAxUnit), `build/ib-tests` is the standalone one.
`tests/bsl/run-tests.sh` recreates either with `--rebuild-base`. Hard-killing
`1cv8` can leave a file infobase corrupted; both are disposable.

### Where to look up 1C platform syntax

**Use this before guessing a platform API name.** The language extension
`1c-syntax.language-1c-bsl` ships a syntax dictionary that the language server
itself does not:

```
/root/.vscode-server/extensions/1c-syntax.language-1c-bsl-*/lib/bslGlobals.json
```

Contents, verified 2026-09-29 on extension 2.1.1:

| Key | Entries | Carries |
|---|---|---|
| `globalfunctions` | 443 | Russian and English name, description, return type, signature with parameter types |
| `globalvariables` | 84 | global properties such as `Metadata`, `БиблиотекаКартинок` |
| `systemEnum` | 616 | enumerations and their values |
| `classes` | 59 | constructible classes, each with `methods`, `properties` and `constructors` |
| `keywords` | 2 | keyword spellings per script variant |

Wrapper: `tools/1c-platform/bsl-syntax.py`.

```bash
tools/1c-platform/bsl-syntax.py AdjustValue          # by English name
tools/1c-platform/bsl-syntax.py ПривестиЗначение     # by Russian name
tools/1c-platform/bsl-syntax.py TypeDescription      # a class, with its members
tools/1c-platform/bsl-syntax.py --list classes
tools/1c-platform/bsl-syntax.py --search версия
```

Paths may be overridden with `--dict` or `BSL_GLOBALS_JSON`.

**Coverage is partial.** It holds the constructible classes, not the whole
platform API: `Metadata.*`, metadata objects, form elements, events and most
object properties are absent, so `--search РегистрСведений` finds nothing. It is
a lookup aid, not a reference for everything.

**Why it matters.** The platform accepts the Russian and the English spelling of
the same member regardless of the configuration's `ScriptVariant`, so either
compiles, but a wrong name is expensive to find: `vrunner cfe compile` and the
designer's `/CheckModules` both load metadata without compiling module bodies, so
the mistake surfaces only when code actually runs, as `Метод объекта не обнаружен
(X)`. This is how `CastValue` was ruled out for `ПривестиЗначение`: the real
English name is `AdjustValue`.

Other sources checked, and why they are not the answer:

- `/opt/1cv8/current/1cv8_ru.hbk` — the platform's own syntax assistant. It is a
  packed help file; `strings` yields nothing usable.
- The BSL language server jar ships **no** syntax resources. The dictionary above
  belongs to the VS Code extension.
- `1c-syntax/bsl-help-toc-parser` parses the platform help table of contents and
  is the route to broader coverage if this dictionary ever proves too thin.

Two syntax traps worth remembering:

- A `New <Type>(...)` expression cannot be chained with a member call:
  `New TypeDescription("Number").AdjustValue("1")` fails with `Неопознанный
  оператор`. Assign to a variable first.
- Because module bodies are not compiled at load time, neither the builder nor the
  harness can catch these statically. A platform call is only proven by executing
  it, which is what the YAxUnit suites do.
