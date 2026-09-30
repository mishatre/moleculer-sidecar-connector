#!/usr/bin/env python3
"""Build a standalone, database-free variant of the MoleculerSidecarConnector CFE.

The canonical extension combines runtime code with persistence, administration and
developer-tool objects.  This generator reads the canonical sources, drops the
objects that need an infobase, merges the remaining common modules into a single
public module, injects the deployment settings into the provider module, and emits
a fresh extension source tree that is compiled with `vrunner cfe compile`.

The canonical sources are never modified.  Everything is written under the output
root (default `build/standalone`).

Why Python: the job is XML/BSL text generation and rewriting.  The repository's
OneScript packages do not expose an XML library and the bundled `json` package has
no global reader, so a Python generator removes two dependency risks at once.  It
is a developer tool, not shipped product code.

See docs/plan/tasks/history/T015-standalone-builder.md for the design and the verified
compiler commands.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

# --------------------------------------------------------------------------------------
# Declarative profile defaults
# --------------------------------------------------------------------------------------

DEFAULT_PROFILE = {
    "variant": "default",
    "sourceRoot": "src/cfe/MoleculerSidecarConnector",
    "outputRoot": "build/standalone",
    "extensionName": "MoleculerSidecarConnectorStandalone",
    "namePrefix": "mol_",
    "version": "0.2.0 beta 4",
    "purpose": "AddOn",
    "scriptVariant": "English",
    "compatibilityMode": "Version8_3_24",
    "targetModule": "Moleculer",
    "providerModule": "MoleculerOverridable",
    "compile": True,
    "v8version": "8.3",
}

DEFAULT_PROFILE_PATH = Path(__file__).resolve().parent / "profiles" / "default.json"

PLAN_KEYS = (
    "mergedModules",
    "keptModules",
    "droppedModules",
    "renames",
    "removedDefinitions",
    "patches",
    "reportedReferences",
)


class BuildError(RuntimeError):
    """Raised when the profile, the sources or the generated variant are invalid."""


# --------------------------------------------------------------------------------------
# BSL-aware text rewriting
# --------------------------------------------------------------------------------------


def split_string_segments(text: str):
    """Yield (kind, chunk) pairs where kind is code, literal or comment.

    BSL has one string form (`"` with `""` as the escape) and one comment form
    (`//` to end of line).  Comments must be recognised as well as literals: a
    comment containing a stray quote would otherwise desynchronise the scanner and
    hide the code that follows it.
    """
    segments = []
    index = 0
    length = len(text)
    code_start = 0

    def flush_code(end: int) -> None:
        if end > code_start:
            segments.append(("code", text[code_start:end]))

    def starts_line(position: int) -> bool:
        """True when only horizontal whitespace separates `position` from a line start."""
        line_start = text.rfind("\n", code_start, position) + 1
        return not text[line_start:position].strip(" \t")

    while index < length:
        char = text[index]

        if char == "#" and starts_line(index):
            flush_code(index)
            directive_start = index

            while index < length and text[index] != "\n":
                index += 1

            segments.append(("directive", text[directive_start:index]))
            code_start = index
            continue

        if char == '"':
            flush_code(index)
            literal_start = index
            index += 1

            while index < length:
                if text[index] == '"':
                    if index + 1 < length and text[index + 1] == '"':
                        index += 2
                        continue
                    index += 1
                    break
                index += 1

            segments.append(("literal", text[literal_start:index]))
            code_start = index
            continue

        if char == "/" and index + 1 < length and text[index + 1] == "/":
            flush_code(index)
            comment_start = index

            while index < length and text[index] != "\n":
                index += 1

            segments.append(("comment", text[comment_start:index]))
            code_start = index
            continue

        index += 1

    flush_code(length)

    return segments


def replace_outside_strings(text: str, pattern: str, replacement: str, flags=re.IGNORECASE) -> str:
    """Apply a regex only to the code parts of the text."""
    compiled = re.compile(pattern, flags)
    result = []

    for kind, chunk in split_string_segments(text):
        if kind == "code":
            result.append(compiled.sub(replacement, chunk))
        else:
            result.append(chunk)

    return "".join(result)


def count_outside_strings(text: str, pattern: str) -> int:
    compiled = re.compile(pattern, re.IGNORECASE)
    total = 0

    for kind, chunk in split_string_segments(text):
        if kind == "code":
            total += len(compiled.findall(chunk))

    return total


def plan_of(profile: dict) -> dict:
    """Everything the engine needs to know about *these* sources.

    The plan is data, not code.  Which modules are merged, kept or dropped, how
    colliding symbols are renamed, which text patches apply and which definitions are
    removed all live in the profile, so the engine below stays generic and a change in
    the canonical sources becomes a data diff instead of a code change.

    Shape:
        mergedModules      [str]  modules folded into targetModule, in emit order
        keptModules        [str]  modules emitted separately, unchanged
        droppedModules     [str]  modules left out; only used by the guard checks
        renames            {module: {lowercase symbol: new name}}
        removedDefinitions {module: [symbol]}
        patches            [{description, pattern, replacement}]
        modulePatches      {module: [{description, pattern, replacement}]}  optional;
                           applied to that module's own text before the merge, for the
                           facts that must differ per module and that folding them into
                           one module would otherwise blur
        reportedReferences [str]  substrings that must not survive in code
    """
    plan = profile.get("plan")

    if not isinstance(plan, dict):
        raise BuildError(
            "The profile has no 'plan' section. The module plan is data: copy it from "
            f"{DEFAULT_PROFILE_PATH} and adapt it to these sources."
        )

    for key in PLAN_KEYS:
        if key not in plan:
            raise BuildError(f"The profile's plan is missing '{key}'")

    for patch in plan["patches"]:
        for field in ("description", "pattern", "replacement"):
            if field not in patch:
                raise BuildError(f"A plan patch is missing '{field}': {patch}")

    for module, replacements in plan.get("modulePatches", {}).items():
        for patch in replacements:
            for field in ("description", "pattern", "replacement"):
                if field not in patch:
                    raise BuildError(f"A module patch for {module} is missing '{field}': {patch}")

    return plan


def definition_names(text: str) -> list[tuple[str, bool]]:
    """Return (lowercased name, is_export) for every top-level definition."""
    pattern = re.compile(
        r"^[ \t]*(?:Процедура|Функция|Procedure|Function)[ \t]+"
        r"([A-Za-zА-Яа-яЁё_][A-Za-zА-Яа-яЁё0-9_]*)(.*)$",
        re.IGNORECASE | re.MULTILINE,
    )
    found = []

    for match in pattern.finditer(text):
        tail = match.group(2)
        found.append((match.group(1).lower(), "export" in tail.lower()))

    return found


DEAD_CONDITION = re.compile(
    r"Not\s+(?:Moleculer\s*\.\s*)?IsStandalone\s*\(\s*\)", re.IGNORECASE
)
BRANCH_START = re.compile(r"^([ \t]*)(If|ElsIf)\b(.*)$", re.IGNORECASE)
BRANCH_END = re.compile(r"^([ \t]*)(ElsIf|Else|EndIf)\b", re.IGNORECASE)
IS_IF = re.compile(r"^[ \t]*If\b", re.IGNORECASE)
IS_ENDIF = re.compile(r"^[ \t]*EndIf\b", re.IGNORECASE)
BRANCH_HEADER = re.compile(r"^([ \t]*)(If|ElsIf|Else)\b(.*)$", re.IGNORECASE)


def if_statement_layout(
    lines: list[str], start: int
) -> tuple[int, list[tuple[str, int, int, int]]]:
    """Describe the `If` statement that begins at `start`.

    Returns `(end_index, branches)`, where `end_index` is the matching `EndIf` and each branch is
    `(keyword, header_index, body_start, body_end)` at the statement's own level. Nesting is tracked
    by counting `If` and `EndIf` rather than by indentation, so unindented BSL is handled too.
    """
    branches: list[tuple[str, int, int, int]] = []
    depth = 0
    header_index = start
    keyword = "if"
    position = start

    while position < len(lines):
        current = lines[position]

        # Preprocessor directives (`#If`, `#EndIf`) are not branches.
        if current.lstrip().startswith("#"):
            position += 1
            continue

        if IS_IF.match(current):
            depth += 1
            if depth == 1:
                header_index, keyword = position, "if"
            position += 1
            continue

        if IS_ENDIF.match(current):
            depth -= 1
            if depth == 0:
                branches.append((keyword, header_index, header_index + 1, position))
                return position, branches
            position += 1
            continue

        header = BRANCH_HEADER.match(current)
        if header and depth == 1 and header.group(2).lower() in ("elsif", "else"):
            branches.append((keyword, header_index, header_index + 1, position))
            header_index = position
            keyword = header.group(2).lower()

        position += 1

    raise ValueError("unterminated If statement")


def dedent_body(lines: list[str], body_start: int, body_end: int, indent: str) -> list[str]:
    """Remove one statement level from a body that is emitted without its own header.

    A branch that becomes the statement's `If` keeps its indentation, because the header stays at the
    same level. A bare `Else` body does not: it becomes statement-level code, so the level the removed
    `If` gave it has to go, or the generated module reads as if it were still nested.
    """
    body = lines[body_start:body_end]
    first = next((line for line in body if line.strip()), "")
    prefix = first[: len(first) - len(first.lstrip())]

    if not prefix.startswith(indent):
        return list(body)

    extra = prefix[len(indent) :]
    return [line[len(extra) :] if line.startswith(extra) else line for line in body]


def render_surviving_branches(
    lines: list[str], indent: str, live: list[tuple[str, int, int, int]]
) -> list[str]:
    """Emit the branches of a stripped `If` statement that are still reachable.

    The first survivor becomes the statement's `If`, so an `ElsIf` that outlives a dead `If` is
    promoted, and a bare `Else` needs no statement around it at all.
    """
    keyword, header_index, body_start, body_end = live[0]

    if keyword == "else":
        return dedent_body(lines, body_start, body_end, indent)

    emitted = []
    header = BRANCH_HEADER.match(lines[header_index])
    emitted.append(f"{header.group(1)}If{header.group(3)}")
    emitted.extend(lines[body_start:body_end])

    for keyword, header_index, body_start, body_end in live[1:]:
        if keyword == "else":
            emitted.append(f"{indent}Else")
        else:
            header = BRANCH_HEADER.match(lines[header_index])
            emitted.append(f"{header.group(1)}ElsIf{header.group(3)}")
        emitted.extend(lines[body_start:body_end])

    emitted.append(f"{indent}EndIf")
    return emitted


def dead_branch_lines(text: str) -> list[str]:
    """Branch headers whose condition can only be true outside standalone mode.

    A ternary `?(Not IsStandalone(), ..., Undefined)` is not a branch: the platform
    evaluates only the selected operand, so it stays and is not reported here.
    """
    found = []

    for line in text.split("\n"):
        if line.lstrip().startswith("#"):
            continue
        match = BRANCH_START.match(line)
        if match and DEAD_CONDITION.search(match.group(3)):
            found.append(line)

    return found


def strip_dead_standalone_branches(text: str) -> tuple[str, int]:
    """Delete the branches that can only run when the extension is *not* standalone.

    The variant has no `Catalog.mol_Services`, so `IsStandalone()` is always true and
    every `Not IsStandalone()` branch is dead.  Deleting them removes the queries and
    type references that point at metadata the variant deliberately does not contain,
    which the platform's metadata check tolerates but BSL Language Server reports as
    `QueryToMissingMetadata` errors.
    """
    lines = text.split("\n")
    kept: list[str] = []
    removed = 0
    index = 0

    while index < len(lines):
        line = lines[index]
        match = BRANCH_START.match(line)
        keyword = match.group(2).lower() if match else ""

        # Preprocessor directives (`#If`, `#EndIf`) are not branches.
        is_directive = line.lstrip().startswith("#")

        if match and not is_directive and DEAD_CONDITION.search(match.group(3)):
            indent = match.group(1)

            if keyword == "if":
                # Only the dead branch goes. A statement whose `Else` or `ElsIf` is still reachable
                # keeps those branches, because they are what the variant actually runs: dropping the
                # whole statement is what silently emptied LogLevels() and AuthTypes().
                end_index, branches = if_statement_layout(lines, index)
                live = []

                for branch in branches:
                    branch_keyword, header_index = branch[0], branch[1]
                    if branch_keyword != "else":
                        branch_header = BRANCH_HEADER.match(lines[header_index])
                        condition = branch_header.group(3) if branch_header else ""
                        if DEAD_CONDITION.search(condition):
                            continue
                    live.append(branch)

                if live:
                    kept.extend(render_surviving_branches(lines, indent, live))

                index = end_index + 1
                removed += 1
                continue

            # An `ElsIf` branch ends at the next branch keyword at the same indent.
            index += 1
            while index < len(lines):
                end_match = BRANCH_END.match(lines[index])
                if end_match and end_match.group(1) == indent:
                    break
                index += 1
            removed += 1
            continue

        kept.append(line)
        index += 1

    return "\n".join(kept), removed


def remove_definitions(text: str, names) -> tuple[str, int]:
    """Delete whole procedure/function definitions by name."""
    wanted = {name.lower() for name in names}
    header = re.compile(
        r"^[ \t]*(?:Процедура|Функция|Procedure|Function)[ \t]+"
        r"([A-Za-zА-Яа-яЁё_][A-Za-zА-Яа-яЁё0-9_]*)",
        re.IGNORECASE,
    )
    terminator = re.compile(r"^[ \t]*End(?:Procedure|Function)\b", re.IGNORECASE)
    lines = text.split("\n")
    kept: list[str] = []
    removed = 0
    index = 0

    while index < len(lines):
        match = header.match(lines[index])

        if match and match.group(1).lower() in wanted:
            index += 1
            while index < len(lines) and not terminator.match(lines[index]):
                index += 1
            index += 1
            removed += 1
            continue

        kept.append(lines[index])
        index += 1

    return "\n".join(kept), removed


def strip_client_flags(descriptor: str) -> str:
    """Make a common module descriptor server-only.

    The variant drops client-context support, so every emitted module runs on the
    server only.  Leaving a module flagged for the ordinary client while it calls the
    server-only merged module makes BSL Language Server report
    `CommonModuleInvalidType`.
    """
    for element in ("ClientManagedApplication", "ClientOrdinaryApplication", "ServerCall"):
        descriptor = re.sub(
            rf"<{element}>.*?</{element}>",
            f"<{element}>false</{element}>",
            descriptor,
            count=1,
        )

    return descriptor


# --------------------------------------------------------------------------------------
# Profile handling
# --------------------------------------------------------------------------------------


def load_profile(path: Path | None) -> dict:
    """Load a profile: generic defaults, then the shipped profile, then the override.

    An override only has to contain the fields it changes.  The plan travels with the
    shipped profile, so overriding, say, the extension name does not require copying it.
    """
    if not DEFAULT_PROFILE_PATH.is_file():
        raise BuildError(f"Shipped profile not found: {DEFAULT_PROFILE_PATH}")

    profile = json.loads(json.dumps(DEFAULT_PROFILE))
    profile.update(json.loads(DEFAULT_PROFILE_PATH.read_text(encoding="utf-8")))

    if path is not None:
        if not path.is_file():
            raise BuildError(f"Profile not found: {path}")
        profile.update(json.loads(path.read_text(encoding="utf-8")))

    profile.setdefault("settings", {})
    return profile


def validate_profile(profile: dict, source_root: Path) -> None:
    plan = plan_of(profile)

    for key in ("extensionName", "namePrefix", "version", "targetModule", "providerModule"):
        if not str(profile.get(key, "")).strip():
            raise BuildError(f"Profile field '{key}' must not be empty")

    if not re.fullmatch(r"[A-Za-zА-Яа-яЁё_][A-Za-zА-Яа-яЁё0-9_]*", profile["extensionName"]):
        raise BuildError(f"Invalid extension name: {profile['extensionName']}")

    if not source_root.is_dir():
        raise BuildError(f"Source root not found: {source_root}")

    compatibility = profile.get("compatibilityMode", "")
    if compatibility and not re.fullmatch(r"Version\d+(?:_\d+)*|DontUse", compatibility):
        raise BuildError(f"Invalid compatibility mode: {compatibility}")

    settings = profile.get("settings", {})
    for connection in settings.get("connections", []):
        for field in ("id", "endpoint", "port"):
            if field not in connection:
                raise BuildError(f"Connection entry is missing '{field}': {connection}")


# --------------------------------------------------------------------------------------
# Merge
# --------------------------------------------------------------------------------------


def read_module(source_root: Path, module: str) -> str:
    module_file = source_root / "CommonModules" / module / "Ext" / "Module.bsl"

    if not module_file.is_file():
        raise BuildError(f"Module source not found: {module_file}")

    return module_file.read_text(encoding="utf-8-sig")


def merge_modules(source_root: Path, profile: dict) -> tuple[str, dict]:
    plan = plan_of(profile)
    merged_modules = plan["mergedModules"]
    target_module = profile["targetModule"]
    texts = {module: read_module(source_root, module) for module in merged_modules}
    stats = {
        "renames": 0,
        "qualified_calls": 0,
        "module_references": 0,
        "patches": 0,
        "module_patches": 0,
        "dead_branches": 0,
        "removed_definitions": 0,
    }

    # 0. Drop definitions that exist only for database-backed features.
    for module, names in plan["removedDefinitions"].items():
        if module in texts:
            texts[module], removed = remove_definitions(texts[module], names)
            stats["removed_definitions"] += removed

    # 0b. Replacements that must differ per module, applied while each module is still its
    #     own text and before anything is renamed.  The reason this exists: step 4 turns
    #     every module reference into the merged module, so a module's own identity — the
    #     key it files its private stack under — would become "Moleculer" for all of them
    #     and three stacks would share one name (T035).  The patterns therefore describe
    #     the canonical sources rather than the renamed output.  A patch that stops
    #     matching fails the build, like a stale plan patch does.
    for module, replacements in plan.get("modulePatches", {}).items():
        if module not in texts:
            continue

        for patch in replacements:
            hits = len(re.findall(patch["pattern"], texts[module], re.IGNORECASE))

            if not hits:
                raise BuildError(
                    f"module patch no longer applies in {module}: {patch['description']}"
                )

            texts[module] = re.sub(
                patch["pattern"],
                patch["replacement"],
                texts[module],
                flags=re.IGNORECASE | re.MULTILINE,
            )
            stats["module_patches"] += hits

    # 1. Rename the qualified calls that cross a module boundary (Module.Symbol).
    for module, renames in plan["renames"].items():
        if module not in texts:
            continue

        for old_name, new_name in renames.items():
            pattern = rf"\b{re.escape(module)}\s*\.\s*{re.escape(old_name)}\b"

            for owner in texts:
                hits = count_outside_strings(texts[owner], pattern)
                if hits:
                    texts[owner] = replace_outside_strings(texts[owner], pattern, new_name)
                    stats["renames"] += hits

    # 2. Rename the local definitions and local calls inside their own module.
    for module, renames in plan["renames"].items():
        if module not in texts:
            continue

        for old_name, new_name in renames.items():
            pattern = rf"(?<![.\w]){re.escape(old_name)}(?![\w])"
            hits = count_outside_strings(texts[module], pattern)
            if hits:
                texts[module] = replace_outside_strings(texts[module], pattern, new_name)
                stats["renames"] += hits

    merged = "\n\n".join(
        f"// ===== merged from CommonModule.{module} =====\n{texts[module].strip()}\n"
        for module in merged_modules
    )

    # 3. Local calls: drop the qualifier of the merged modules.
    for module in merged_modules:
        pattern = rf"\b{re.escape(module)}\s*\.\s*"
        hits = count_outside_strings(merged, pattern)
        if hits:
            merged = replace_outside_strings(merged, pattern, "")
            stats["qualified_calls"] += hits

    # 4. Module references: a bare module name becomes the merged module.  The
    #    qualifier of a remaining `Metadata.CommonModules.<module>` is kept.
    for module in merged_modules:
        pattern = rf"(?<![\w]){re.escape(module)}(?![\w])"
        hits = count_outside_strings(merged, pattern)
        if hits:
            merged = replace_outside_strings(merged, pattern, target_module)
            stats["module_references"] += hits

    # 4b. Delete the branches that can only run outside standalone mode.
    merged, dead_branches = strip_dead_standalone_branches(merged)
    stats["dead_branches"] = dead_branches

    # 5. Declarative patches for the facts a textual merge cannot infer.  These run
    #    on the raw text because some of them span a string literal.  A patch that no
    #    longer matches means the canonical sources moved on and the plan is stale;
    #    that used to pass silently, which made the generator quietly wrong.
    for patch in plan["patches"]:
        hits = len(re.findall(patch["pattern"], merged, re.IGNORECASE))

        if not hits:
            raise BuildError(f"plan patch no longer applies: {patch['description']}")

        merged = re.sub(
            patch["pattern"],
            patch["replacement"],
            merged,
            flags=re.IGNORECASE | re.MULTILINE,
        )
        stats["patches"] += hits

    return merged, stats


def validate_merged(merged: str, profile: dict) -> tuple[list[str], list[str]]:
    """Static checks that stand in for the unavailable BSL syntax check.

    Returns (fatal problems, reported observations).
    """
    problems = []
    observations = []
    plan = plan_of(profile)
    target_module = profile["targetModule"]

    definitions: dict[str, list[int]] = {}
    for position, (name, _is_export) in enumerate(definition_names(merged)):
        definitions.setdefault(name, []).append(position)

    for name, positions in sorted(definitions.items()):
        if len(positions) > 1:
            problems.append(f"duplicate definition after merge: {name} ({len(positions)} definitions)")

    for module in plan["mergedModules"] + plan["droppedModules"]:
        if module == target_module:
            continue
        if count_outside_strings(merged, rf"(?<![.\w]){re.escape(module)}(?![\w])"):
            problems.append(f"unresolved reference to removed module: {module}")

    for reference in plan["reportedReferences"]:
        hits = count_outside_strings(merged, re.escape(reference))
        if hits:
            observations.append(f"{hits} guarded infobase reference(s) retained: {reference}")

    module_variables = re.findall(r"^[ \t]*(?:Перем|Var)[ \t]", merged, re.IGNORECASE | re.MULTILINE)
    if module_variables:
        problems.append(
            "the platform does not allow module variables in a common module: "
            f"{len(module_variables)} declaration(s)"
        )

    if dead_branch_lines(merged):
        survivors = len(dead_branch_lines(merged))
        problems.append(f"{survivors} dead `Not IsStandalone()` branch(es) survived the strip step")

    compatibility = re.search(r"Version(\d+)_(\d+)_(\d+)", str(profile.get("compatibilityMode", "")))
    if compatibility:
        version = tuple(int(part) for part in compatibility.groups())
        if version < (8, 3, 23):
            observations.append(
                f"compatibilityMode {profile['compatibilityMode']} is below 8.3.23, but the "
                "merged sources use ОшибкаРаботыСРечью and ОшибкаТабличногоПространстваБазыДанных, "
                "which the platform only exposes from 8.3.23"
            )

    opened = count_outside_strings(merged, r"\b(?:Procedure|Процедура)\b")
    closed = count_outside_strings(merged, r"\bEndProcedure\b")
    if opened != closed:
        problems.append(f"Procedure/EndProcedure mismatch: {opened} opened, {closed} closed")

    functions = count_outside_strings(merged, r"\b(?:Function|Функция)\b")
    end_functions = count_outside_strings(merged, r"\bEndFunction\b")
    if functions != end_functions:
        problems.append(f"Function/EndFunction mismatch: {functions} opened, {end_functions} closed")

    return problems, observations


# --------------------------------------------------------------------------------------
# Emission
# --------------------------------------------------------------------------------------


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def configuration_xml(profile: dict) -> str:
    language_uuid = str(uuid.uuid4())
    compatibility = profile.get("compatibilityMode", "").strip()
    compatibility_line = (
        f"\t\t\t<ConfigurationExtensionCompatibilityMode>{compatibility}</ConfigurationExtensionCompatibilityMode>\n"
        if compatibility
        else ""
    )
    contained = "\n".join(
        "\t\t\t<xr:ContainedObject><xr:ClassId>{}</xr:ClassId><xr:ObjectId>{}</xr:ObjectId></xr:ContainedObject>".format(
            class_id, object_id
        )
        for class_id, object_id in CONTAINED_OBJECTS
    )
    kept_modules = "".join(
        f"\t\t\t<CommonModule>{module}</CommonModule>\n" for module in plan_of(profile)["keptModules"]
    )

    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:v8="http://v8.1c.ru/8.1/data/core"'
        ' xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
        ' version="2.17">\n'
        '\t<Configuration uuid="' + str(uuid.uuid4()) + '">\n'
        "\t\t<InternalInfo>\n"
        f"{contained}\n"
        "\t\t</InternalInfo>\n"
        "\t\t<Properties>\n"
        f"\t\t\t<Name>{profile['extensionName']}</Name>\n"
        "\t\t\t<Synonym>\n"
        "\t\t\t\t<v8:item>\n"
        "\t\t\t\t\t<v8:lang>ru</v8:lang>\n"
        f"\t\t\t\t\t<v8:content>{profile['extensionName']}</v8:content>\n"
        "\t\t\t\t</v8:item>\n"
        "\t\t\t</Synonym>\n"
        "\t\t\t<Comment>Standalone, database-free variant generated by tools/standalone-builder</Comment>\n"
        f"\t\t\t<ConfigurationExtensionPurpose>{profile['purpose']}</ConfigurationExtensionPurpose>\n"
        "\t\t\t<ObjectBelonging>Adopted</ObjectBelonging>\n"
        f"{compatibility_line}"
        f"\t\t\t<NamePrefix>{profile['namePrefix']}</NamePrefix>\n"
        f"\t\t\t<ScriptVariant>{profile['scriptVariant']}</ScriptVariant>\n"
        f"\t\t\t<Version>{profile['version']}</Version>\n"
        "\t\t</Properties>\n"
        "\t\t<ChildObjects>\n"
        "\t\t\t<Language>Русский</Language>\n"
        f"\t\t\t<CommonModule>{profile['targetModule']}</CommonModule>\n"
        f"\t\t\t<CommonModule>{profile['providerModule']}</CommonModule>\n"
        f"{kept_modules}"
        "\t\t\t<HTTPService>mol_Moleculer</HTTPService>\n"
        "\t\t</ChildObjects>\n"
        "\t</Configuration>\n"
        "</MetaDataObject>\n"
    )


# The platform requires exactly these seven contained-object class ids in a
# configuration's InternalInfo; the object ids are allocated per build.
CONTAINED_OBJECTS = [
    ("9cd510cd-abfc-11d4-9434-004095e12fc7", "a1000000-0000-4000-8000-000000000001"),
    ("9fcd25a0-4822-11d4-9414-008048da11f9", "a1000000-0000-4000-8000-000000000002"),
    ("e3687481-0a87-462c-a166-9f34594f9bba", "a1000000-0000-4000-8000-000000000003"),
    ("9de14907-ec23-4a07-96f0-85521cb6b53b", "a1000000-0000-4000-8000-000000000004"),
    ("51f2d5d8-ea4d-4064-8892-82951750031e", "a1000000-0000-4000-8000-000000000005"),
    ("e68182ea-4237-4383-967f-90c1e3370bc7", "a1000000-0000-4000-8000-000000000006"),
    ("fb282519-d103-4dd3-bc12-cb271d631dfc", "a1000000-0000-4000-8000-000000000007"),
]


def language_xml() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:v8="http://v8.1c.ru/8.1/data/core"'
        ' xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
        ' version="2.17">\n'
        f'\t<Language uuid="{uuid.uuid4()}">\n'
        "\t\t<InternalInfo/>\n"
        "\t\t<Properties>\n"
        "\t\t\t<ObjectBelonging>Adopted</ObjectBelonging>\n"
        "\t\t\t<Name>Русский</Name>\n"
        "\t\t\t<Comment/>\n"
        "\t\t\t<LanguageCode>ru</LanguageCode>\n"
        "\t\t</Properties>\n"
        "\t</Language>\n"
        "</MetaDataObject>\n"
    )


def common_module_xml(name: str, server_call: bool) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:v8="http://v8.1c.ru/8.1/data/core"'
        ' xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
        ' version="2.17">\n'
        f'\t<CommonModule uuid="{uuid.uuid4()}">\n'
        "\t\t<Properties>\n"
        f"\t\t\t<Name>{name}</Name>\n"
        "\t\t\t<Synonym>\n"
        "\t\t\t\t<v8:item>\n"
        "\t\t\t\t\t<v8:lang>ru</v8:lang>\n"
        f"\t\t\t\t\t<v8:content>{name}</v8:content>\n"
        "\t\t\t\t</v8:item>\n"
        "\t\t\t</Synonym>\n"
        "\t\t\t<Comment/>\n"
        "\t\t\t<Global>false</Global>\n"
        "\t\t\t<ClientManagedApplication>false</ClientManagedApplication>\n"
        "\t\t\t<Server>true</Server>\n"
        "\t\t\t<ExternalConnection>false</ExternalConnection>\n"
        "\t\t\t<ClientOrdinaryApplication>false</ClientOrdinaryApplication>\n"
        f"\t\t\t<ServerCall>{'true' if server_call else 'false'}</ServerCall>\n"
        "\t\t\t<Privileged>false</Privileged>\n"
        "\t\t\t<ReturnValuesReuse>DontUse</ReturnValuesReuse>\n"
        "\t\t</Properties>\n"
        "\t</CommonModule>\n"
        "</MetaDataObject>\n"
    )


def provider_module_bsl(profile: dict) -> str:
    settings = profile.get("settings", {})
    config = settings.get("config", {})
    lines = [
        "// Provider seam for the standalone variant.",
        "//",
        "// The canonical extension reads this data from the mol_* catalogs and constants.",
        "// The standalone variant has no catalog and no constant, so the deployment",
        "// settings are declared here. Edit this module to change them, or regenerate the",
        "// variant with a different profile.",
        "",
        f"Procedure GetConfig(Config) Export",
        "",
        f'\tConfig.Namespace    = "{config.get("namespace", "")}";',
        f'\tConfig.ModulePrefix = "{config.get("modulePrefix", "Service")}";',
        f'\tConfig.LogLevel     = "{config.get("logLevel", "Info")}";',
        f'\tConfig.ExtVersion   = "{config.get("extVersion", profile["version"])}";',
        f'\tConfig.ExtAdminRole = "{config.get("extAdminRole", "")}";',
        "",
        "EndProcedure",
        "",
        "Procedure GetConnections(Connections) Export",
        "",
    ]

    connections = settings.get("connections", [])
    if not connections:
        lines.append("\t// No connections declared in the profile.")
    for connection in connections:
        lines.extend(
            [
                "\tNewParams = Moleculer.NewConnectionParams();",
                f'\tNewParams.Id          = "{connection["id"]}";',
                f'\tNewParams.Description = "{connection.get("description", "")}";',
                f'\tNewParams.Default     = {"True" if connection.get("default") else "False"};',
                f'\tNewParams.Type        = "HTTP";',
                f'\tNewParams.Endpoint    = "{connection["endpoint"]}";',
                f'\tNewParams.Port        = {int(connection["port"])};',
                f'\tNewParams.UseSSL      = {"True" if connection.get("useSSL") else "False"};',
                f'\tNewParams.AccessKey   = "{connection.get("accessKey", "")}";',
                f'\tNewParams.SecretKey   = "{connection.get("secretKey", "")}";',
                f'\tNewParams.Timeout     = {int(connection.get("timeout", 120))};',
                "\tConnections.Add(NewParams);",
                "",
            ]
        )

    lines.extend(["EndProcedure", "", "Procedure GetPublications(Publications) Export", ""])

    publications = settings.get("publications", [])
    if not publications:
        lines.append("\t// No publications declared in the profile.")
    for publication in publications:
        lines.extend(
            [
                "\tNewParams = Moleculer.NewPublicationParams();",
                f'\tNewParams.id          = "{publication["id"]}";',
                f'\tNewParams.description = "{publication.get("description", "")}";',
                f'\tNewParams.endpoint    = "{publication["endpoint"]}";',
                f'\tNewParams.port        = {int(publication["port"])};',
                f'\tNewParams.useSSL      = {"True" if publication.get("useSSL") else "False"};',
                f'\tNewParams.path        = "{publication.get("path", "")}";',
                "\tPublications.Add(NewParams);",
                "",
            ]
        )

    lines.extend(
        [
            "EndProcedure",
            "",
            "Procedure GetServiceModules(Modules) Export",
            "",
            "\t// Host service modules are discovered by the configured module prefix.",
            "",
            "EndProcedure",
            "",
            "Procedure GetServices(Services) Export",
            "",
            "\t// No extra service definitions are declared by the provider.",
            "",
            "EndProcedure",
        ]
    )

    return "\n".join(lines) + "\n"


def httpservice_handler_bsl(profile: dict) -> str:
    return (
        "\nFunction GatewayPOST(Request)\n"
        "\t\n"
        f"\tReturn {profile['targetModule']}.Transporter_HTTP_Receive(Request);\n"
        "\t\n"
        "EndFunction\n"
    )


def emit_tree(profile: dict, merged_bsl: str, output_dir: Path, source_root: Path) -> list[str]:
    target_module = profile["targetModule"]
    provider_module = profile["providerModule"]

    # The HTTP service descriptor has no infobase dependency, so the proven canonical
    # document is reused instead of being regenerated.
    httpservice_descriptor = (source_root / "HTTPServices" / "mol_Moleculer.xml").read_text(
        encoding="utf-8-sig"
    )

    write_text(output_dir / "Configuration.xml", configuration_xml(profile))
    write_text(output_dir / "Languages" / "Русский.xml", language_xml())

    write_text(output_dir / "CommonModules" / f"{target_module}.xml", common_module_xml(target_module, False))
    write_text(output_dir / "CommonModules" / target_module / "Ext" / "Module.bsl", merged_bsl)

    write_text(output_dir / "CommonModules" / f"{provider_module}.xml", common_module_xml(provider_module, False))
    write_text(
        output_dir / "CommonModules" / provider_module / "Ext" / "Module.bsl",
        provider_module_bsl(profile),
    )

    kept_modules = plan_of(profile)["keptModules"]
    removed_definitions = plan_of(profile)["removedDefinitions"]

    # The reuse modules keep their own descriptors, so their ReturnValuesReuse setting
    # survives, and their unchanged bodies.
    for module in kept_modules:
        descriptor = strip_client_flags(
            (source_root / "CommonModules" / f"{module}.xml").read_text(encoding="utf-8-sig")
        )
        body = read_module(source_root, module)
        body, _removed = remove_definitions(body, removed_definitions.get(module, ()))
        write_text(output_dir / "CommonModules" / f"{module}.xml", descriptor)
        write_text(output_dir / "CommonModules" / f"{module}" / "Ext" / "Module.bsl", body)

    write_text(output_dir / "HTTPServices" / "mol_Moleculer.xml", httpservice_descriptor)
    write_text(
        output_dir / "HTTPServices" / "mol_Moleculer" / "Ext" / "Module.bsl",
        httpservice_handler_bsl(profile),
    )

    return sorted(path.relative_to(output_dir).as_posix() for path in output_dir.rglob("*") if path.is_file())


def compile_variant(profile: dict, output_dir: Path) -> Path:
    artifact = output_dir.parent / f"{profile['extensionName']}.cfe"
    command = [
        "vrunner",
        "cfe",
        "compile",
        "--src",
        str(output_dir),
        "--extension-name",
        str(profile["extensionName"]),
        "--ibcmd",
        "--v8version",
        str(profile["v8version"]),
        str(artifact),
    ]

    print("+ " + " ".join(command))

    # Run from a neutral directory on purpose.  `vrunner` picks up
    # `autumn-properties.json` from the working directory, and this repository's copy
    # pins `ibconnection` to `/F./build/ib`.  Inheriting that makes the compiler load
    # the variant into the dev infobase instead of a temporary one, which both defeats
    # the "never touch build/ib" guarantee and fails when that base is locked.  Every
    # path passed here is absolute, so the working directory is free to be anywhere.
    result = subprocess.run(
        command,
        cwd=tempfile.gettempdir(),
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        raise BuildError(
            "cfe compile failed with exit code "
            f"{result.returncode}\n{result.stdout}\n{result.stderr}"
        )

    if not artifact.is_file():
        raise BuildError(f"cfe compile reported success but produced no artifact: {artifact}")

    return artifact


# --------------------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------------------


def write_install_guide(profile: dict, output_dir: Path) -> str:
    """Write the administrator-facing guide that ships with the variant.

    The variant differs from the canonical extension in a way nobody can read out of
    the artifact: both common modules are server-only, so nothing connects from an
    ordinary client context. That difference has to be stated next to the artifact,
    which is what this file is for.
    """

    text = f"""# Установка расширения {profile["extensionName"]}

Это автономный (standalone) вариант коннектора, собранный генератором
`tools/standalone-builder`. От канонического расширения он отличается одним:
оба общих модуля помечены как серверные, поэтому из клиентского контекста
ничего не подключается — подключение выполняет серверная сторона.

## Установка как расширения

1. Установите `{profile["extensionName"]}.cfe` на нужную информационную базу.
2. Константы, справочники, перечисления и формы вариант не использует: каталог
   `mol_Services` и база-источник ему не нужны, поэтому способ обнаружения
   автономного режима — отсутствие этого справочника.
3. Проверьте подключение вызовом серверного метода
   `{profile["targetModule"]}.Broker().Call(...)`.

## Перенос в конфигурацию-хозяина вручную

1. Перенесите общие модули `{profile["targetModule"]}` и
   `{profile["providerModule"]}`.
2. Перенесите общие модули `mol_Reuse` и `mol_ReuseCalls` отдельно: они не
   объединены с остальными, потому что их время жизни кэша (сессия и запрос) в
   объединённом модуле не выражается.
3. Перенесите HTTP-сервис `mol_Moleculer` вместе с его обработчиком.
4. Задайте параметры окружения в модуле `{profile["providerModule"]}` — в этом
   варианте они встроены в него, а не хранятся в константах.

## Сведения о сборке

Ревизия исходников, список файлов и хеши записаны в
`standalone-manifest.json`. Сборка создана для режима совместимости
`{profile["compatibilityMode"]}`, версия расширения `{profile["version"]}`.
"""

    relative = "INSTALL.md"
    write_text(output_dir / relative, text)

    return relative


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--profile", type=Path, default=None, help="JSON profile overriding the defaults")
    parser.add_argument("--out-root", type=Path, default=None, help="Override the output root directory")
    parser.add_argument("--no-compile", action="store_true", help="Emit the source tree without compiling it")
    parser.add_argument("--keep-tree", action="store_true", help="Keep an existing output tree instead of replacing it")
    return parser.parse_args(argv)


def ensure_output_is_outside_sources(output_dir: Path, source_root: Path) -> None:
    """Refuse an output tree that would be written over the sources.

    The generator replaces an existing output tree before it writes the new one, so
    a redirected output root is the one input that can destroy canonical work. Both
    the source root and the whole `src/` folder are off limits, because a variant
    written anywhere under `src/` would be picked up as canonical source later.
    """

    resolved_output = output_dir.resolve()
    forbidden_roots = (source_root.resolve(), (REPO_ROOT / "src").resolve())

    for forbidden in forbidden_roots:
        if resolved_output == forbidden or forbidden in resolved_output.parents:
            raise BuildError(
                f"Refusing to write the variant into the sources: {output_dir}\n"
                f"Choose an output root outside {forbidden}"
            )


def source_revision() -> str:
    """The repository revision the canonical sources were read at.

    Recorded in the manifest so a built artifact can be traced back to the exact
    sources it was generated from. A checkout without a revision records "unknown"
    rather than failing the build.
    """

    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return "unknown"

    return result.stdout.strip() or "unknown"


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    profile = load_profile(args.profile)

    source_root = REPO_ROOT / profile["sourceRoot"]
    validate_profile(profile, source_root)

    output_root = Path(args.out_root) if args.out_root else REPO_ROOT / profile["outputRoot"]
    output_dir = output_root / profile["variant"]

    ensure_output_is_outside_sources(output_dir, source_root)

    if output_dir.exists():
        if not args.keep_tree:
            shutil.rmtree(output_dir)
        else:
            raise BuildError(f"Output tree already exists: {output_dir}")

    print(f"Building variant '{profile['variant']}' from {source_root}")

    merged_bsl, stats = merge_modules(source_root, profile)
    print(
        "Merge: {renames} rename(s), {qualified_calls} local call(s), "
        "{module_references} module reference(s), {patches} patch(es), "
        "{module_patches} per-module replacement(s)".format(**stats)
    )

    problems, observations = validate_merged(merged_bsl, profile)
    for observation in observations:
        print(f"  [note] {observation}")
    if problems:
        for problem in problems:
            print(f"  [FAIL] {problem}", file=sys.stderr)
        raise BuildError(f"Merged module failed {len(problems)} static check(s)")

    print("Static checks: passed")

    written = emit_tree(profile, merged_bsl, output_dir, source_root)
    written.append(write_install_guide(profile, output_dir))
    print(f"Emitted {len(written)} file(s) under {output_dir}")
    for relative in written:
        print(f"  {relative}")

    manifest = {
        "profile": profile,
        "sourceRevision": source_revision(),
        "mergeStats": stats,
        "files": written,
        "fileHashes": {
            relative: hashlib.sha256((output_dir / relative).read_bytes()).hexdigest()
            for relative in written
        },
        "mergedModuleSha256": hashlib.sha256(merged_bsl.encode("utf-8")).hexdigest(),
        "observations": observations,
        "unverified": [
            "The static checks prove the generated module's shape, not its runtime behaviour.",
            "The variant's runtime behaviour is covered by the extension harness and by loading",
            "the artifact into a database-free infobase; see T021.",
        ],
    }

    manifest_path = output_dir / "standalone-manifest.json"
    write_text(manifest_path, json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    print(f"Manifest: {manifest_path}")

    if profile.get("compile", True) and not args.no_compile:
        artifact = compile_variant(profile, output_dir)
        digest = hashlib.sha256(artifact.read_bytes()).hexdigest()
        print(f"Artifact: {artifact} ({artifact.stat().st_size} bytes, sha256 {digest})")
    else:
        print("Compilation skipped")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except BuildError as error:
        print(f"BUILD FAILED: {error}", file=sys.stderr)
        sys.exit(1)
