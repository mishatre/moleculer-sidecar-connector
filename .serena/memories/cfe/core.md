# Connector Extension

- Extension root: `src/cfe/MoleculerSidecarConnector/`; root metadata: `Configuration.xml`.
- Configuration name is `MoleculerSidecarConnector`; extension purpose is `AddOn`.
- Canonical release version source is the extension's `Configuration.xml`; normalize it as SemVer for tags and artifacts. Current source text is pre-release style and task T005 defines its normalization.
- Main behavior is distributed across `CommonModules/`, HTTP service `HTTPServices/mol_Moleculer/`, catalogs, forms, application modules, and supporting metadata.
- Central Moleculer module is regioned into Public, Protected, and Private namespaces. Use Serena symbol tools for module navigation; avoid whole-file reads when a symbol query suffices.
- Release contract: tag `v{semver}`; asset `MoleculerSidecarConnector-v{semver}.cfe`; installer asset `MoleculerSidecarConnectorInstaller-v{semver}.epf`; checksums `SHA256SUMS.txt`.
- Build with `vrunner compileexttocfe`; generated CFE stays under `build/`. Do not put generated CFE bytes into source-review diffs.
- GitHub repository for release contract: `mishatre/moleculer-ones`.