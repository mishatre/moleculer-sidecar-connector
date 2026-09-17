# Suggested Commands

Run from `/workspace`.

## Environment checks

```bash
source /root/.bashrc
pwd
oscript -version
opm --version
vrunner --help
command -v oscript opm vrunner 1cv8 1cv8c ibcmd
```

- Use `oscript -version`; `oscript --version` prints the engine banner plus usage.
- Do not use `vrunner --version`; it reports an unsupported argument despite exit code 0.
- VS Code tasks contain Windows `SET` syntax/backslash paths and are not valid Bash command sources.
- Deleted root scripts such as `build.cmd`, `test.cmd`, and `prepare.cmd` are not available.
- Never use `--updatedb` as an environment check.

## Direct build forms

Installer source build:
```bash
vrunner compileepf src/epf/installer build/out/epf \
  --ibconnection /F./build/ib --v8version 8.3 --root /workspace \
  --ordinaryapp -1 --nocacheuse
```

Connector release build (substitute the task's canonical SemVer in the output filename):
```bash
vrunner compileexttocfe \
  --src ./src/cfe/MoleculerSidecarConnector \
  --out ./build/release/MoleculerSidecarConnector-v{semver}.cfe \
  --ibcmd --ibconnection /F./build/ib --v8version 8.3 \
  --root /workspace --ordinaryapp -1 --nocacheuse
```

Staged installer release build:
```bash
vrunner compileepf build/staging/installer build/release \
  --ibconnection /F./build/ib --v8version 8.3 --root /workspace \
  --ordinaryapp -1 --nocacheuse
```

Use exact task-specific commands from `docs/plan/tasks/` when they differ; runtime/integration commands are not yet established.