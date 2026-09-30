# Procedure and function description — 1C standard #std453

Every numbered section below carries a rule ID such as `BSL-453-5.9`. Tasks and reviews cite
that ID instead of a paragraph, so it is the stable name of the rule. Section 5.9 is a project
rule, not part of the standard.

This is the English working reference for the 1C:Enterprise development standard *Procedure and
function description* (`v8std` #std453), restated rather than translated.
[provenance.md](provenance.md) records the source and its authority.

Applies to the managed application, the mobile application and the ordinary
application.

## 1. When to write a description

`BSL-453-1`

Write a procedure's or function's description as a comment above it. Whether to
comment individual blocks of code inside a procedure or function is the
developer's judgement, based on the complexity and how unusual the block is.

On platform 8.3 and later the comment text is also shown in the context hint for
procedures, functions and their parameters. In 1C:Enterprise Development Tools the
comment text is additionally used to refine the typing of parameters and the
return value, which helps find coding errors during development.

## 2. Mandatory descriptions

`BSL-453-2`

Procedures and functions that form a module's program interface require a
mandatory description. They are intended for use by other functional subsystems
(or other applications) that other developers may be responsible for, so they must
be well documented.

In other cases the comment may be absent or may be arbitrary text.

## 3. Other procedures and functions

`BSL-453-3`

Other procedures and functions, including the event handlers of forms, objects,
record sets, value managers and so on, should be commented when the purpose of the
procedure or function, or some peculiarity of its work, needs explaining. It is
also recommended to describe the reasons why some actions are skipped, when that
is not obvious for the given procedure or function.

When a procedure or function is simple to understand and its purpose and behaviour
follow from its name and the names of its formal parameters, the comment may be
omitted.

## 4. Comments that add nothing

`BSL-453-4`

Avoid comments that give no extra explanation of the work of a non-export
procedure or function.

For example, these comments are redundant, because the names already say that they
are event handlers, and the syntax assistant documents the handlers and their
parameters:

```bsl
// Event handler for the form's "OnOpen" event.
//
&AtClient
Procedure OnOpen()
```

```bsl
// Command handler for "Calculate".
//
&AtClient
Procedure Calculate()
```

```bsl
// Handler for the "EditOnlyInDialog" form item's "OnChange" event.
//
&AtClient
Procedure EditOnlyInDialogOnChange(Item)
```

The next comment gives no additional information about the function beyond its
name:

```bsl
// Returns the cash flow item from the document's data.
Function CashFlowItem(DocumentData)
```

## 5. Comment format

`BSL-453-5`

The comment is placed before the declaration of the procedure or function and has
the sections below.

### 5.1 Description

`BSL-453-5.1`

The `Description` section gives the purpose of the procedure or function, in enough
detail to understand the scenarios of its use without reading its source. It may
also contain a short description of the working principles and cross-references to
related procedures and functions.

It may be the only section for a procedure without parameters. The description must
not repeat the procedure's or function's name. For procedures and functions it must
start with a verb. For functions this is usually "Returns…". When the returned
result is not the main point of the function's work, start with the main action, for
example "Checks…", "Compares…", "Calculates…".

Do not start the description with the redundant words "Procedure…" or "Function…",
nor with the name of the procedure or function itself, if removing them does not
change the meaning.

Incorrect:

```bsl
// Constructor of the WSProxy object.
// ...
Function WSProxy(ProxyParameters) Export
```

```bsl
// The function ValueTableRowToStructure creates a structure with properties that ...
Function ValueTableRowToStructure(ValueTableRow) Export
```

Correct:

```bsl
// Creates a proxy from a web service definition and binds it to the
// web service connection point.
// In addition to the platform's New WSProxy constructor it:
// - includes a call to the WSDefinition constructor;
// - caches the WSDL file for the session to speed up frequent calls;
// - does not require an explicit InternetProxy (it is supplied automatically if configured);
// - performs a quick availability check of the web service using a Ping operation.
// ...
Function WSProxy(ProxyParameters) Export
```

```bsl
// Creates a structure with properties that ...
Function ValueTableRowToStructure(ValueTableRow) Export
```

### 5.2 Parameters

`BSL-453-5.2`

The `Parameters` section describes the parameters of the procedure or function.
When there are none, the section is skipped. It is preceded by the line
`// Parameters:`, then each parameter description starts on a new line.

#### 5.2.1 Parameter line format

`BSL-453-5.2.1`

A parameter description starts on a new line, then the parameter name, a dash, the
list of types, a dash and the parameter's text description.

Choose the parameter name so that its purpose is clear in the context of the
function without further explanation.

The type description is mandatory. The type may be stated explicitly, as either one
type or a list of types. A "list of types" means type names separated by commas. A
type name may be simple (one word) or composite (two words separated by a dot), for
example `String`, `Structure`, `Arbitrary`, `CatalogRef.Employees`.

Use only the types that exist in the platform, plus the special types provided by
EDT, such as `DefinedType.<Name>`, `CatalogRef`, `MetadataObjectReport`,
`FormDecorationExtensionForLabel` and similar.

Incorrect:

```bsl
// CollectionOfRows - ValueCollection - the collection to compare;
// GeneratedReport - MetadataObject: Report
// AttachedFileObject - an item of the files catalog.
```

Correct:

```bsl
// CollectionOfRows - ValueTable, Array, ValueList - the collection to compare.
// GeneratedReport - MetadataObjectReport
// AttachedFileObject - DefinedType.AttachedFileObject - an item of the files catalog.
```

Fill the parameter's text description when the parameter name alone is not enough
to understand its purpose, when extra information about the type is needed, or when
a clear example with the expected value is useful.

Incorrect, because the "Addresses" description adds nothing:

```bsl
// Checks that the passed addresses are included in the task. If the check fails, an exception is raised.
//
// Parameters:
// Addresses - String - a string containing email addresses
// TaskPerformer - TaskRef.TaskPerformer - the task being checked
//
Procedure CheckTaskAddresses(Addresses, TaskPerformer)
```

Correct, because it states the separator rule and gives an example:

```bsl
// Checks that the passed addresses are included in the task. If the check fails, an exception is raised.
//
// Parameters:
// Addresses - String - contains email addresses separated by a comma.
//             For example, support@mycorp.ru,v8@localdomain.
// TaskPerformer - TaskRef.TaskPerformer
//
Procedure CheckTaskAddresses(Addresses, TaskPerformer)
```

#### 5.2.2 Structures and value tables

`BSL-453-5.2.2`

For parameters of type `Structure` and `ValueTable` (`ValueTree`), the type
description must reference the function whose output is that structure or value
table, for example its constructor function.

```bsl
// Fills prices in a tabular section row.
//
// Parameters:
// CurrentRow - TabularSectionRow
// PriceFillingParameters - see PricingServer.PriceFillingParameters
//
Procedure FillPricesInTabularSectionRow(CurrentRow, PriceFillingParameters);
```

In the rare case when a method handles collections in a generic way, the properties
and columns do not need describing; just the type `Structure` or `ValueTable`
(`ValueTree`) is enough.

#### 5.2.3 Arrays

`BSL-453-5.2.3`

For parameters of type `Array`, state the element type with the keyword `of`.

Incorrect:

```bsl
// RedirectedTasks - Array - an array of redirected tasks.
// RedirectedTasks - Array - tasks (TaskRef.TaskPerformer) redirected to another performer.
```

Correct:

```bsl
// UpdateInfo - Array of see InfobaseUpdate.UpdateParameters
```

The element type may be omitted only in methods that handle arrays in a generic
way, for example the `AppendArray`, `DeleteAllValueOccurrencesFromArray` and similar
methods of the Standard Subsystems Library.

#### 5.2.4 Value table rows

`BSL-453-5.2.4`

For a parameter of type `ValueTableRow` (`ValueTreeRow`) the composition of
properties may be stated, matching the columns of its owning table (tree).

```bsl
// RegionInfo - ValueTableRow: see InformationRegisters.AddressObjects.SubjectsOfRF
```

where `SubjectsOfRF` is an export function of the `AddressObjects` information
register manager module that returns a value table.

#### 5.2.5 Additional type descriptions

`BSL-453-5.2.5`

For each parameter, one or more additional type descriptions may be given. Each
additional description starts on a new line, then a mandatory dash, then the list of
parameter types, a dash and the text description.

```bsl
// Parameters:
// Requisites - String - requisites listed with commas.
//              For example, "Code, Description, Parent".
//   - Structure, FixedStructure - the key is the alias of a field of the returned
//     result structure, and the value (optionally) is the actual field name in the
//     table. When the value is undefined, the field name is taken from the key.
//   - Array of String, FixedArray of String - requisite names.
```

#### 5.2.6 Constructor references

`BSL-453-5.2.6`

Descriptions may also be given as a reference to a constructor function in the form
`see MethodPath`.

```bsl
// SerialNumberingParameters - see NomenclatureClientServer.SerialNumberingParameters
// Duplicates - see DataProcessorObject.FindAndDeleteDuplicates.DuplicateGroups
// ComponentRequisites - Array of see ExternalComponents.ComponentRequisites
```

When code refers to the attributes of a specific metadata object or form, it may
reference that object's (or form's) attribute types:

```bsl
// Queries - see DataProcessor.QueryConsole.TabularSection.Queries
// DataTypes - see DataProcessor.QueryConsole.Attribute.AvailableDataTypes
// Attachments - see Catalog.MessageTemplates.ItemForm.Attachments
// ContactInfo - see Document.CustomerOrder.DocumentForm.Object.ContactInfo
```

In the rare case when no suitable constructor function exists and none can be
created, it is acceptable to reference a parameter of another procedure or function:

```bsl
// Parameters:
// SearchParameters - see FindAndDeleteDuplicatesOverridable.OnDefineDuplicateSearchParameters.SearchParameters
// AdditionalParameters - see FindAndDeleteDuplicatesOverridable.OnDefineDuplicateSearchParameters.AdditionalParameters
//
Procedure DuplicateSearchParameters(SearchParameters, AdditionalParameters) Export
```

When a procedure is an event described in a program interface, for example in an
overridable module, and repeats its set and order of parameters, use one reference
to that procedure:

```bsl
// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
```

### 5.3 Return value

`BSL-453-5.3`

The `Returns` section describes the type and content of the function's return
value. Procedures have no such section. It is preceded by the line
`// Returns:`, then the return type, a dash and the text description.

For a composite return type, write each type on a new line with a leading dash.

```bsl
// Returns:
// Boolean
```

```bsl
// Returns:
// Boolean - True when at least one of the passed roles is available to the current
// user, or when the user has administrative rights.
```

```bsl
// Returns:
//   - AnyRef - a reference to the predefined item.
//   - Undefined - when the predefined item exists in the metadata but has not been
//     created in the infobase.
```

```bsl
// Returns:
//   - CatalogRef.Users
//   - CatalogRef.ExternalUsers
```

Fill the return value's text description when the function description alone is not
enough, or when extra information about the type is needed, such as the composition
of the returned value's properties or columns. An example with the expected return
value may also be given, or a complete example may be placed in the `Example`
section below.

The format for describing an `Array` return value is the same as in section 5.2.3.
The format for `Structure` and `ValueTable` return values is given in the standard
on using structures and value tables as parameters.

### 5.4 Example

`BSL-453-5.4`

The `Example` section contains an example of using the procedure or function. It is
preceded by the line `// Example:`, then the example starts on a new line.

Write the procedure's or function's name together with the name of the common module
it is in. The example must make clear what is passed in and what is returned.

Incorrect:

```bsl
// Example:
// SubstituteStringParameters(TemplateString, ReplacementString);
```

Correct:

```bsl
// Example:
// StringFunctionsClientServer.SubstituteStringParameters(NStr("en='%1 went to the %2'"), "John", "zoo")
//   = "John went to the zoo".
```

In overridable modules, the `Example` section contains an example implementation of
the overridable procedure, not an example of calling it:

```bsl
// Example:
// GeneralParameters.MinimumRequiredPlatformVersion = "8.3.4.365";
// GeneralParameters.RecommendedRAMSize = 2;
```

### 5.5 Call options

`BSL-453-5.5`

In the rare case when several parameters have additional types, add a
`// Call options:` section describing the most common, or all, possible variants of
calling the function with different combinations of parameter types.

The section starts with the phrase `// Call options:` on a new line, then each
variant description starts on a new line. Each call variant is written as the
function name with the list of types in parentheses separated by commas, then a dash
and the text description of the variant.

```bsl
// Parameters:
// Parameter1 - Type11, Type12 - ...
// Parameter2 - Type21, Type22, Type23 - ...
//
// Call options:
// UniversalProcedure(Type11, Type21) - description ...
// UniversalProcedure(Type12, Type22) - description ...
// UniversalProcedure(Type11, Type23) - description ...
//
Procedure UniversalProcedure(Parameter1, Parameter2) Export
```

### 5.6 Indentation

`BSL-453-5.6`

Within every declared section, the comment text must be indented relative to the
section heading, starting from the first line. In a multi-line description that
belongs to one context, an extra indent is needed only for the second line; the
following lines need no indent and align vertically with the second line.

The indentation is needed to separate the parts of the documenting comment
unambiguously, and to let automated tools attribute the text to the right section
when the formatting has errors.

```bsl
// First line of the description of a universal procedure.
// The second line is written without an indent, because the "Description" section is not declared.
// Third and subsequent lines are written without an indent.
//
// Parameters:
// Parameter1 - Type1 - the first line of the parameter description,
//   the second line is shifted relative to the first.
//   The third line is written without an extra shift.
// Parameter2 - Type2 - here a new context begins.
//
Procedure UniversalProcedure(Parameter1, Parameter2)
```

### 5.7 Cross-references

`BSL-453-5.7`

Anywhere in the documenting comment, cross-references to other configuration
objects, procedures and functions may be added, in particular to constructor
functions of structures. In 1C:Enterprise Development Tools the environment renders
such references as hyperlinks.

```bsl
// Description of a universal procedure.
//
// See AccessManagement.FillAccessValueSets
//
// Parameters:
// Parameter1 - Arbitrary - for the parameter description see Catalog.Counterparties.
//
Procedure UniversalProcedure(Parameter1)
```

### 5.8 Deprecated procedures

`BSL-453-5.8`

To mark a procedure or function as deprecated, put the word `Deprecated` in the
first line of its description.

```bsl
// Deprecated. Use see GeneralUse.SeparationEnabled and
// see GeneralUse.SeparatedDataUseAvailable
// ...
Function SessionSeparatorUse() Export
```

### 5.9 Marking the internal API (project rule)

`BSL-453-5.9`

#std453 has no marker for the internal API, so this project adds one. An exported
procedure or function that sits in a module's `Internal` region — named `Protected`
in some modules until [T040](../plan/tasks/style/T040-refactor-protected-region.md) renames
it — is not part of the module's public interface. It exists only for other objects of
the same subsystem, so it carries a single `// @internal` line as the last line of its
documenting comment:

```bsl
// Returns the error currently being handled in the session.
//
// Parameters:
// Clear - Boolean - when True, the current error is removed after it is read.
//
// Returns:
// Error - the error being handled, or Undefined.
//
// @internal
&AtServer
Function GetCurrentError(Clear = False) Export
```

The marker is deliberately terse so it can be found with a plain text search. When a
routine has no other comment, the marker is the whole comment, and it still sits above
the compilation directive:

```bsl
// @internal
Function GetConfig() Export
```

A routine in the public interface (`Public` region) or an overridable connector must
not carry the marker; those are public by design.

## 6. Compilation directives

`BSL-453-6`

When a procedure or function with a compilation directive needs a comment, place
the comment first and the compilation directive after it.

```bsl
// Handles the form's OnCreateAtServer event.
// Processes the form parameters and fills the form attributes with values.
// It also does the following:
// ...
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
```

This placement draws attention first to the function definition and the compilation
directive, and only then to the comment, which may be long.

## 7. Blank lines

`BSL-453-7`

The code of procedures and functions must be separated from one another by blank
lines in the module text.

## 8. Worked examples

`BSL-453-8`

A function with one parameter:

```bsl
// Determines whether the roles from RoleNames are available to the current user,
// and whether administrative rights are available.
//
// Parameters:
// RoleNames - String - role names to check, separated by commas.
//
// Returns:
// Boolean - True when at least one of the passed roles is available to the current user,
// or when the user has administrative rights.
//
// Example:
// If RolesAvailable("UseReportMailouts,SendByMail") Then ...
//
Function RolesAvailable(RoleNames) Export
```

A procedure without parameters:

```bsl
// In the document's BeforeWrite event handler it performs:
// - clearing the services tabular section when a commission agent agreement is set;
// - checking that the Places tabular section's UnitOfMeasure attribute is filled;
// - synchronizing with the "subordinate" invoice;
// - filling the warehouse and the customer order in the Goods and ReturnablePackaging
//   tabular sections;
// - deleting unused rows of the SerialNumbers tabular section;
// - filling the object module variable DeleteMovements.
//
Procedure BeforeWrite()
EndProcedure
```
