"""Regression tests for the builder's stand-alone guard stripping.

The strip removes branches that can only run outside standalone mode. Removing the whole statement
instead of the dead branch silently emptied `LogLevels()` and `AuthTypes()` in the generated variant:
the logger could no longer match any level, and a correctly declared publication auth type was refused
while an absent one was answered with token auth. These cases pin the survivors.

Container-only and platform-free, like the rest of this directory. Run with:

    python3 -m unittest discover -s tests/standalone-builder -v
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

BUILDER_PATH = Path(__file__).resolve().parents[2] / "tools" / "standalone-builder" / "build-standalone.py"


def load_builder():
    spec = importlib.util.spec_from_file_location("build_standalone_strip", BUILDER_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class StripDeadStandaloneBranches(unittest.TestCase):

    def setUp(self):
        self.builder = load_builder()

    def strip(self, text: str) -> str:
        stripped, _removed = self.builder.strip_dead_standalone_branches(text)
        return stripped

    def test_a_live_else_survives_a_dead_if(self):
        source = "If Not IsStandalone() Then\n\tDead();\nElse\n\tLive();\nEndIf;"

        self.assertEqual(self.strip(source).strip(), "Live();")

    def test_a_live_else_body_is_dedented_to_the_statement_level(self):
        # A bare Else needs no statement around it, so the level its If gave the body has to go.
        source = "Procedure P()\n\tIf Not IsStandalone() Then\n\t\tDead();\n\tElse\n\t\tLive();\n\tEndIf;\nEndProcedure"

        self.assertIn("\tLive();", self.strip(source))

    def test_a_dead_if_without_an_else_disappears_entirely(self):
        source = "Before();\nIf Not IsStandalone() Then\n\tDead();\nEndIf;\nAfter();"

        stripped = self.strip(source)

        self.assertNotIn("Dead", stripped)
        self.assertNotIn("EndIf", stripped)
        self.assertIn("Before();", stripped)
        self.assertIn("After();", stripped)

    def test_a_live_elsif_is_promoted_to_if(self):
        source = "If Not IsStandalone() Then\n\tDead();\nElsIf Other() Then\n\tLive();\nElse\n\tAlso();\nEndIf;"

        stripped = self.strip(source)

        self.assertIn("If Other() Then", stripped)
        self.assertNotIn("ElsIf", stripped)
        self.assertIn("Live();", stripped)
        self.assertIn("Also();", stripped)

    def test_a_nested_if_inside_a_live_else_is_preserved(self):
        source = "If Not IsStandalone() Then\n\tDead();\nElse\n\tIf Nested() Then\n\t\tKept();\n\tEndIf;\nEndIf;"

        stripped = self.strip(source)

        self.assertIn("If Nested() Then", stripped)
        self.assertIn("Kept();", stripped)
        self.assertIn("EndIf;", stripped)

    def test_a_dead_elsif_is_dropped_but_its_neighbours_survive(self):
        source = "If Other() Then\n\tFirst();\nElsIf Not IsStandalone() Then\n\tDead();\nElse\n\tLast();\nEndIf;"

        stripped = self.strip(source)

        self.assertIn("First();", stripped)
        self.assertIn("Last();", stripped)
        self.assertNotIn("Dead", stripped)
        self.assertNotIn("ElsIf", stripped)

    def test_preprocessor_directives_are_not_treated_as_branches(self):
        source = "#If Server Then\n\tIf Not IsStandalone() Then\n\t\tDead();\n\tEndIf;\n#EndIf"

        stripped = self.strip(source)

        self.assertIn("#If Server Then", stripped)
        self.assertIn("#EndIf", stripped)
        self.assertNotIn("Dead", stripped)


if __name__ == "__main__":
    unittest.main()
