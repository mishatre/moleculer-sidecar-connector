# Installer External Processor

- Source root: `src/epf/installer/`; processor export root: `src/epf/installer/installer/`.
- Managed-form implementation: `installer/Forms/Форма/Ext/Form/Module.bsl`; bindings/layout: adjacent `Form.xml`.
- Form module currently uses Russian responsibility regions and module variables for extension data, platform data, and compatibility. Maintain handler/XML binding consistency and observable form-state behavior during refactors.
- Bundled connector template: `installer/Templates/MoleculerOneS/Ext/Template.bin`.
- Release assembly must copy installer source to `build/staging/installer`, replace only the staged template with the freshly built CFE, then compile the staged EPF. Source template bytes must not be overwritten by build output.
- Direct build uses `vrunner compileepf`; normal source result is `build/out/epf/installer.epf`.
- Installer smoke coverage includes absent, installed, unsupported, removal, and restart-related states. Compilation alone is insufficient.
- Installation/update/removal behavior and consumer-infobase mutation require explicit task authority; only `/workspace/build/ib` is the authorized disposable target when the task requires it.