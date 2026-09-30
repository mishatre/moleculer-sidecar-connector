# Module structure — 1C standard #std455

Every numbered section below carries a rule ID such as `BSL-455-4.4`. Tasks and reviews cite
that ID instead of a paragraph, so it is the stable name of the rule.

This is the English working reference for the 1C:Enterprise development standard *Module
structure* (`v8std` #std455), restated rather than translated. [provenance.md](provenance.md)
records the source and its authority.

Applies to general modules, object modules, object manager modules, form modules,
command modules and similar.

## 1. Module sections

`BSL-455-1`

A module may contain the following sections, in this order:

1. module header
2. variable declarations
3. public program interface — the export procedures and functions that make up
   the module's API
4. event handlers of the object (or form)
5. private procedures and functions — the internal implementation
6. initialization section

Some sections exist only in certain module kinds:

- form element event handlers exist only in form modules;
- the variable and initialization sections must not be declared in non-global
  common modules, object manager modules, record set modules, constant value
  modules or the session module.

Splitting module code into sections raises readability and makes it easier for
several authors to change the code, both in team development and in local
adaptations.

## 2. Sections, sub-sections and regions

`BSL-455-2`

- Large sections are split into sub-sections by responsibility.
- Sections and sub-sections are `#Region` / `#EndRegion` regions.
- Region names follow the variable naming rules.
- A module must not contain empty regions.

## 3. Region templates

`BSL-455-3`

### 3.1 Common modules

`BSL-455-3.1`

```bsl
#Region Public
// Procedures and functions
#EndRegion

#Region Internal
// Procedures and functions
#EndRegion

#Region Private
// Procedures and functions
#EndRegion
```

- **Public** — export procedures and functions intended for use by other
  configuration objects or other programs (for example through an external
  connection).
- **Internal** — for modules that are part of a functional subsystem. It holds
  export procedures and functions that may be called only from other subsystems
  of the same library. It is not part of the module's public interface, so every
  exported routine in it carries the `// @internal` marker, described in
  [procedure and function description § 5.9](procedure-and-function-description.md#59-marking-the-internal-api).
  Some modules in this repository still name the region `Protected`; the two names
  mean the same thing here, and [T040](https://github.com/mishatre/moleculer-sidecar-connector/issues/3)
  renames them.
- **Private** — the internal implementation of the common module. When a common
  module is part of a functional subsystem with several metadata objects, this
  section may also hold private export procedures and functions intended to be
  called only from other objects of that subsystem. Split large modules into
  sub-sections by responsibility, for example:

```bsl
#Region InfobaseUpdate
// Procedures and functions
#EndRegion
```

### 3.2 Object, manager, record set, data processor and report modules

`BSL-455-3.2`

```bsl
#Region Variables
#EndRegion

#Region Public
// Procedures and functions
#EndRegion

#Region EventHandlers
// Procedures and functions
#EndRegion

#Region Internal
// Procedures and functions
#EndRegion

#Region Private
// Procedures and functions
#EndRegion

#Region Initialize
#EndRegion
```

- **Public** — export procedures and functions intended for use in other
  configuration modules or by other programs. Do not place export procedures and
  functions here when they are called exclusively from the object's own modules,
  forms and commands. For example, the procedures that fill a document's tabular
  section, called from the object module's fill handler and from the document
  form's command handler, are not the object module's API: they are called only
  inside the object's own module and forms, so they belong in **Private**.
- **EventHandlers** — the object module's event handlers (`BeforeWrite`,
  `OnPost` and so on).
- **Internal** and **Private** — same purpose as in common modules.

### 3.3 Form modules

`BSL-455-3.3`

```bsl
#Region Variables
#EndRegion

#Region FormEventHandlers
// Procedures and functions
#EndRegion

#Region FormHeaderItemsEventHandlers
// Procedures and functions
#EndRegion

#Region FormTableItemsEventHandlers<FormTableName>
// Procedures and functions
#EndRegion

#Region FormCommandsEventHandlers
// Procedures and functions
#EndRegion

#Region Private
// Procedures and functions
#EndRegion
```

- **FormEventHandlers** — form event handlers such as `OnCreateAtServer`,
  `OnOpen` and so on.
- **FormHeaderItemsEventHandlers** — handlers of the controls in the main part of
  the form, that is everything not tied to a form table.
- **FormTableItemsEventHandlers\<FormTableName\>** — handlers of a form table and
  its items. Create one separate region per form table.
- **FormCommandsEventHandlers** — form command handlers, whose names are set in
  the command's `Action` property.
- **Private** — same purpose as in common modules.

### 3.4 Command modules

`BSL-455-3.4`

```bsl
#Region EventHandlers
// Procedures and functions
#EndRegion

#Region Private
// Procedures and functions
#EndRegion
```

- **EventHandlers** — the command handler.
- **Private** — same purpose as in common modules.

## 4. General requirements for module sections

`BSL-455-4`

### 4.1 Module header

`BSL-455-4.1`

The module header is a comment at the very start of the module. It has two parts,
in this order:

1. the copyright and license block;
2. the module description.

The description must be as compressed as possible: one or two lines that say what
the module is for. Do not put design decisions, a list of the module's sections or
regions, or usage examples in the header. They belong in the body of the module, in
the documented routines, or in the task that owns the change. This is stricter than
#std455, which also allowed stating the conditions of use.

For a form module, naming the form parameters is the one extra detail worth a line.

Every first-party source file carries the same copyright and license block, so a BSL
module opens like this:

```bsl
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Thin wrapper over the connector's public facade, used by the admin-panel forms.
```

Keep the box the same width (80 columns) and the block byte-for-byte the same in
every file, so it is recognisable at a glance and can be checked mechanically. The
only per-file part is the description after the box. The chosen license is recorded
in the repository-root `LICENSE` file, and the copyright holder matches the
configuration's `<Vendor>`.

External sources copied into the repository, such as files under `oscript_modules/`
`vendor/`, keep their own headers and are not modified, and the
`moleculer-sidecar-next/` Node subproject is out of scope and keeps its own terms.

### 4.2 Variable declarations

`BSL-455-4.2`

Variable names follow the general naming rules, and their use is described in the
standard on module-level variables.

Every module variable must carry a comment sufficient to understand its purpose.
Place the comment on the same line as the declaration where practical.

```bsl
#Region Variables
Var PresentationCurrency;
Var SupportEmail;
#EndRegion
```

### 4.3 Public program interface

`BSL-455-4.3`

The export procedures and functions that form the module's API are placed
immediately after the variable declarations. They are intended for use by other
configuration objects or other programs, so they must sit in a visible place in
the module.

### 4.4 Form, command and form-item event handlers

`BSL-455-4.4`

In a form module, form event handlers and the handlers of form commands and
form items are placed before the private procedures and functions.

Group the handlers of one form item together, following the order in which the
items appear in the form editor's property panel.

Every event must have its own handler procedure. When the same action must run
for events of different form items:

1. create a separate procedure (or function) that performs the required action;
2. create a separate handler for each form item, using the default name;
3. call the required procedure (or function) from each handler.

```bsl
// Correct.
&AtClient
Procedure OnAuthorChange(Item)
    SetListFilter();
EndProcedure

&AtClient
Procedure OnPerformerChange(Item)
    SetListFilter();
EndProcedure

&AtServer
Procedure SetListFilter()
    FilterParameters = New Map();
    FilterParameters.Insert("ByAuthor", ByAuthor);
    FilterParameters.Insert("ByPerformer", ByPerformer);
    SetListFilterValue(List, FilterParameters);
EndProcedure
```

An event handler is not intended to be called from module code; the platform calls
it directly. Mixing the two scenarios in one procedure needlessly complicates its
logic and reduces its robustness, because the procedure must then handle the
platform event and any direct calls.

### 4.5 Object and manager event handlers

`BSL-455-4.5`

The object and object manager event handlers are placed after the public program
interface section but before the module's private procedures and functions.

Where practical, order them as they appear in the embedded language description.

### 4.6 Private procedures and functions

`BSL-455-4.6`

The private procedures and functions that form the module's internal
implementation are placed after the event handlers.

When a common module is part of a functional subsystem with several metadata
objects, this section may also hold private export procedures and functions
intended to be called only from other objects of that subsystem.

Keep procedures and functions that are related by nature or by logic together.

In form modules, do not explicitly group procedures and functions into server,
client and no-context ones. That "technological" ordering makes the module's logic
harder to understand, because it draws attention to implementation details.

### 4.7 Initialization section

`BSL-455-4.7`

The initialization section contains the statements that initialize the module
variables or the object (or form).

```bsl
#Region Initialize
SupportEmail = "v8@1c.ru";
PerformInitialization();
#EndRegion
```
