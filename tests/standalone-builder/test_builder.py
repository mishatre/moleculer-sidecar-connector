"""Tests for the standalone CFE builder.

Container-only: they never launch the 1C platform.  Run with:

    python3 -m unittest discover -s tests/standalone-builder -v

The BSL-facing half of the project cannot be tested here because the container has
no runnable 1C client; see docs/plan/tasks/T014-verify-toolchain-and-test-runner.md.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BUILDER_PATH = REPO_ROOT / "tools" / "standalone-builder" / "build-standalone.py"
PROFILE_PATH = REPO_ROOT / "tools" / "standalone-builder" / "profiles" / "default.json"


def load_builder():
    spec = importlib.util.spec_from_file_location("build_standalone", BUILDER_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


builder = load_builder()


class SegmentScannerTests(unittest.TestCase):
    """A quote inside a comment must not desynchronise the scanner."""

    def test_comment_with_quote_does_not_hide_following_code(self):
        text = '// don\'t use "this\nReturn RealCode();\n'
        hits = builder.count_outside_strings(text, r"RealCode")
        self.assertEqual(1, hits)

    def test_replacements_skip_literals(self):
        text = 'x = "mol_Broker";\ny = mol_Broker;\n'
        result = builder.replace_outside_strings(text, r"mol_Broker", "Moleculer")
        self.assertIn('"mol_Broker"', result)
        self.assertIn("y = Moleculer;", result)

    def test_replacements_skip_comments_and_directives(self):
        text = "#Region mol_Broker\n// mol_Broker\nz = mol_Broker;\n"
        result = builder.replace_outside_strings(text, r"mol_Broker", "Moleculer")
        self.assertIn("#Region mol_Broker", result)
        self.assertIn("// mol_Broker", result)
        self.assertIn("z = Moleculer;", result)

    def test_escaped_quotes_inside_literal(self):
        text = 'a = "he said ""hi"""; b = mol_Broker;\n'
        result = builder.replace_outside_strings(text, r"mol_Broker", "Moleculer")
        self.assertIn('"he said ""hi"""', result)
        self.assertIn("b = Moleculer;", result)

    def test_directive_is_only_recognised_at_line_start(self):
        text = "x = 1; #NotADirective mol_Broker\n"
        result = builder.replace_outside_strings(text, r"mol_Broker", "Moleculer")
        self.assertIn("Moleculer", result)


class DefinitionScanTests(unittest.TestCase):
    def test_export_flag_is_detected(self):
        text = "Function A() Export\nEndFunction\n\nProcedure B()\nEndProcedure\n"
        self.assertEqual([("a", True), ("b", False)], builder.definition_names(text))

    def test_multiline_signature_is_recognised(self):
        text = "Function Long(Name, Other = 1) Export\nEndFunction\n"
        self.assertEqual([("long", True)], builder.definition_names(text))


class ProfileTests(unittest.TestCase):
    def test_default_profile_is_valid(self):
        profile = builder.load_profile(None)
        source_root = REPO_ROOT / profile["sourceRoot"]
        builder.validate_profile(profile, source_root)

    def test_shipped_profile_is_valid(self):
        profile = builder.load_profile(PROFILE_PATH)
        source_root = REPO_ROOT / profile["sourceRoot"]
        builder.validate_profile(profile, source_root)
        self.assertEqual("Moleculer", profile["targetModule"])

    def test_profile_overrides_defaults(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "profile.json"
            path.write_text(json.dumps({"extensionName": "CustomVariant"}), encoding="utf-8")
            profile = builder.load_profile(path)
            self.assertEqual("CustomVariant", profile["extensionName"])
            self.assertEqual(builder.DEFAULT_PROFILE["targetModule"], profile["targetModule"])

    def test_invalid_extension_name_is_rejected(self):
        profile = builder.load_profile(None)
        profile["extensionName"] = "not a name"
        with self.assertRaises(builder.BuildError):
            builder.validate_profile(profile, REPO_ROOT / profile["sourceRoot"])

    def test_missing_source_root_is_rejected(self):
        profile = builder.load_profile(None)
        with self.assertRaises(builder.BuildError):
            builder.validate_profile(profile, Path("/nonexistent/source/root"))

    def test_invalid_compatibility_mode_is_rejected(self):
        profile = builder.load_profile(None)
        profile["compatibilityMode"] = "8.3.21"
        with self.assertRaises(builder.BuildError):
            builder.validate_profile(profile, REPO_ROOT / profile["sourceRoot"])

    def test_connection_requires_id_endpoint_and_port(self):
        profile = builder.load_profile(None)
        profile["settings"]["connections"] = [{"endpoint": "localhost", "port": 5103}]
        with self.assertRaises(builder.BuildError):
            builder.validate_profile(profile, REPO_ROOT / profile["sourceRoot"])


class CanonicalMergeTests(unittest.TestCase):
    """Merge the real canonical sources once and assert the invariants."""

    @classmethod
    def setUpClass(cls):
        cls.profile = builder.load_profile(PROFILE_PATH)
        cls.source_root = REPO_ROOT / cls.profile["sourceRoot"]
        cls.merged, cls.stats = builder.merge_modules(cls.source_root, cls.profile)

    def test_static_checks_pass(self):
        problems, _observations = builder.validate_merged(self.merged, self.profile)
        self.assertEqual([], problems)

    def test_no_definitions_are_duplicated(self):
        names = [name for name, _export in builder.definition_names(self.merged)]
        duplicates = {name for name in names if names.count(name) > 1}
        self.assertEqual(set(), duplicates)

    def test_removed_modules_are_not_referenced_in_code(self):
        for module in builder.DROPPED_MODULES:
            pattern = rf"(?<![.\w]){module}(?![\w])"
            self.assertEqual(
                0,
                builder.count_outside_strings(self.merged, pattern),
                f"{module} is still referenced",
            )

    def test_no_qualifier_for_merged_modules_remains_in_code(self):
        for module in builder.MERGED_MODULES:
            self.assertEqual(
                0,
                builder.count_outside_strings(self.merged, rf"\b{module}\s*\.\s*"),
                f"{module}. qualifier survived the merge",
            )

    def test_reuse_caches_are_explicit(self):
        self.assertIn("If ReuseCallsStack = Undefined Then", self.merged)
        self.assertIn("If HTTPConnectionCache = Undefined Then", self.merged)
        self.assertIn("Перем ReuseCallsStack;", self.merged)

    def test_platform_facts_are_patched(self):
        self.assertIn("CompileServiceSchema(Moleculer)", self.merged)
        self.assertNotIn("Constants.mol_TestConnection.Get()", self.merged)
        self.assertNotIn("YAML.ToObject(Text);", self.merged)
        self.assertIn("ReuseCallsStack = Undefined;", self.merged)

    def test_internal_service_constructor_keeps_its_discovered_name(self):
        names = {name for name, _export in builder.definition_names(self.merged)}
        self.assertIn("constructor", names)

    def test_blocks_are_balanced(self):
        self.assertEqual(
            builder.count_outside_strings(self.merged, r"\b(?:Procedure|Процедура)\b"),
            builder.count_outside_strings(self.merged, r"\bEndProcedure\b"),
        )
        self.assertEqual(
            builder.count_outside_strings(self.merged, r"\b(?:Function|Функция)\b"),
            builder.count_outside_strings(self.merged, r"\bEndFunction\b"),
        )


class EmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = builder.load_profile(PROFILE_PATH)
        cls.source_root = REPO_ROOT / cls.profile["sourceRoot"]
        cls.merged, _stats = builder.merge_modules(cls.source_root, cls.profile)

    def _emit(self, directory: Path) -> list[str]:
        return builder.emit_tree(self.profile, self.merged, directory, self.source_root)

    def test_tree_contains_only_database_free_objects(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "default"
            files = self._emit(output)
            self.assertEqual(
                sorted(
                    [
                        "CommonModules/Moleculer.xml",
                        "CommonModules/Moleculer/Ext/Module.bsl",
                        "CommonModules/MoleculerOverridable.xml",
                        "CommonModules/MoleculerOverridable/Ext/Module.bsl",
                        "Configuration.xml",
                        "HTTPServices/mol_Moleculer.xml",
                        "HTTPServices/mol_Moleculer/Ext/Module.bsl",
                        "Languages/Русский.xml",
                    ]
                ),
                files,
            )

    def test_configuration_declares_seven_contained_objects(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "default"
            self._emit(output)
            configuration = (output / "Configuration.xml").read_text(encoding="utf-8")
            self.assertEqual(7, configuration.count("<xr:ContainedObject>"))
            for collection in ("Catalog", "Constant", "Enum", "DataProcessor", "Role", "CommonForm"):
                self.assertNotIn(f"<{collection}>", configuration)

    def test_configuration_declares_no_infobase_objects(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "default"
            self._emit(output)
            configuration = (output / "Configuration.xml").read_text(encoding="utf-8")
            self.assertNotIn("mol_Services", configuration)
            self.assertNotIn("mol_Connections", configuration)
            self.assertNotIn("mol_Namespaces", configuration)

    def test_language_is_adopted(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "default"
            self._emit(output)
            language = (output / "Languages" / "Русский.xml").read_text(encoding="utf-8")
            self.assertIn("<ObjectBelonging>Adopted</ObjectBelonging>", language)

    def test_provider_has_no_standalone_guard_and_carries_settings(self):
        profile = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
        body = builder.provider_module_bsl(profile)
        self.assertNotIn("IsStandalone", body)
        self.assertNotIn('"UUID"', body)
        for procedure in ("GetConfig", "GetConnections", "GetPublications", "GetServiceModules", "GetServices"):
            self.assertIn(f"Procedure {procedure}(", body)


class CommandLineTests(unittest.TestCase):
    def test_no_compile_emits_tree_without_compiling(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                [
                    sys.executable,
                    str(BUILDER_PATH),
                    "--profile",
                    str(PROFILE_PATH),
                    "--out-root",
                    tmp,
                    "--no-compile",
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, result.returncode, result.stdout + result.stderr)
            self.assertTrue((Path(tmp) / "default" / "Configuration.xml").is_file())
            self.assertEqual([], list(Path(tmp).glob("*.cfe")))

    def test_rerun_replaces_the_previous_tree(self):
        with tempfile.TemporaryDirectory() as tmp:
            command = [
                sys.executable,
                str(BUILDER_PATH),
                "--profile",
                str(PROFILE_PATH),
                "--out-root",
                tmp,
                "--no-compile",
            ]
            self.assertEqual(0, subprocess.run(command, capture_output=True, text=True).returncode)
            marker = Path(tmp) / "default" / "stale.txt"
            marker.write_text("stale", encoding="utf-8")
            self.assertEqual(0, subprocess.run(command, capture_output=True, text=True).returncode)
            self.assertFalse(marker.exists())

    def test_unknown_profile_path_fails(self):
        result = subprocess.run(
            [sys.executable, str(BUILDER_PATH), "--profile", "/nonexistent/profile.json", "--no-compile"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(1, result.returncode)
        self.assertIn("BUILD FAILED", result.stderr)


if __name__ == "__main__":
    unittest.main()
