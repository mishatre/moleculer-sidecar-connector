# Where these rules come from

The two reference documents in this folder restate parts of the official 1C:Enterprise
development standards (`v8std`) in English. They are working references for this repository:
restatements shaped for the project, not translations, and not authoritative.

| Local document | Standard |
|---|---|
| [module-structure.md](module-structure.md) | #std455 *Module structure* — https://its.1c.ru/db/v8std/content/455/hdoc |
| [procedure-and-function-description.md](procedure-and-function-description.md) | #std453 *Procedure and function description* — https://its.1c.ru/db/v8std/content/453/hdoc |

The authoritative originals live on ITS and require a subscription. Read the English documents
here rather than the captures below.

## Raw captures

`../1c-docs/` holds windows-1251 HTML captures of the two ITS pages, taken as evidence of what
was read. They are kept only as provenance: they are hard to read, they include the surrounding
site chrome, and they can go stale. Do not cite them and do not read them to answer a question —
use the two documents above.

## What was changed for this project

- The rule text is compressed and reordered into short numbered sections, and every section has a
  stable rule ID (`BSL-455-*`, `BSL-453-*`).
- Examples that referenced standard configurations rather than this project were dropped or
  replaced; the examples kept are the ones a change in this repository would look like.
- Provisions that do not apply to this tree are omitted: the mobile application, the ordinary
  (non-managed) application, and the section templates for module kinds that #std455 excludes —
  non-global common modules, object manager modules, record set modules, constant value modules
  and the session module.
- Section 5.9 of the routine-description document is not from the standard. It is the project's
  own marker for the internal API, added because #std453 has no such marker.
- The module header rule in section 4.1 is stricter than #std455, which also allowed stating the
  conditions of use. This project allows only a copyright and license block plus one or two lines
  of description.

Anything else that differs is a mistake in the restatement: report it, and the standard wins.
