---
name: permissao-compliance
description: Use when editing or creating MediatR requests (IBaseRequest) in .NET projects that define PermissaoAttribute/SemPermissaoAttribute—keeps every request decorated (prefer Permissao), ensures GUIDs are valid/uppercase/unique, and mirrors the checks enforced by PermissaoTests without rerunning it.
---

# Permissao Compliance Ritual

## Overview
PermissaoTests guarantees four things: every MediatR `IBaseRequest` has either `PermissaoAttribute` or `SemPermissaoAttribute`; every `PermissaoAttribute.Guid` string is a valid GUID in "D" format; those GUIDs are uppercase; and no duplicates exist. This skill forces you to reenact those assertions manually before committing code so the test stays green even when you cannot or should not run it.

Violating the letter of these steps _is_ violating their spirit. Copy/pasting attributes without verification immediately breaks guarantees.

## When to Use
- Modifying or creating any MediatR request (`IBaseRequest`, `IRequest`, derived `CommandBase`, `QueryPaginadaPara<>`, etc.).
- Editing GUID literals inside `[Permissao]` applied to those requests.
- Reviewing code where someone introduces or changes a MediatR request attribute.

Do **not** skip because the request is "internal", "temporary", or "only used by a handler"—PermissaoTests inspects every `IBaseRequest`.

## Mandatory Checklist
1. **Confirm attributes exist**: locate `PermissaoAttribute` and `SemPermissaoAttribute`. If a project lacks them, note that this skill does not apply and stop. Otherwise continue.
2. **Identify every affected request**: in each touched file, list all types implementing `IBaseRequest` (directly or via base classes). Include partial/nested MediatR requests.
3. **Require decoration (prefer Permissao)**: every request must have exactly one attribute. Default to `[Permissao("<GUID>")]`. Only use `[SemPermissao]` when the request already used it historically or business rules explicitly require it—never switch an existing `SemPermissao` to `Permissao` without stakeholder approval.
4. **Generate compliant GUIDs**: for brand-new requests (or files you just created), use `Guid.NewGuid().ToString("D").ToUpperInvariant()`. Never change a GUID that already existed in the repository unless your human partner explicitly requests it.
5. **Validate format/casing**: verify every GUID string matches regex `^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$`. Lowercase characters are not allowed.
6. **Check uniqueness**: search the repository for the GUID (case-insensitive) before saving. If it already exists, discard it and generate another. Never leave duplicates "for later".
7. **Re-scan undecorated requests**: search for `: IRequest`, `IBaseRequest`, `Command`, `Query` in changed files to ensure no MediatR request slipped through without an attribute.
8. **Document decisions**: when reviewers ask, cite which classes received which attribute and why.

If you typed code before completing the checklist, delete the changes, perform the checklist, then reapply edits.

## Quick Reference
| Need | Action |
|------|--------|
| New MediatR request | Add `[Permissao("NEW GUID")]`, uppercase string, ensure unique |
| Existing request previously marked `SemPermissao` | Keep `[SemPermissao]` unless stakeholders agree to upgrade |
| Unsure if type implements `IBaseRequest` indirectly | Inspect base types/interfaces; if yes, decorate |
| Checking duplicates | `rg -i "<GUID>" -n` at repo root |
| Validating uppercase format | `Guid.TryParseExact(value, "D", out _) && value == value.ToUpperInvariant()` |

## Example Application
```csharp
[Permissao("3B1F4F6E-7CF1-4AE7-8249-3E6A0E3E8115")]
public record GerarLoteFaturasCommand : IBaseRequest<Unit>
{
    public long LoteId { get; init; }
}
```
* Steps followed: generated new GUID, uppercased string, searched repo to confirm uniqueness, cited attribute in PR notes. *

## Rationalizations vs Reality
| Excuse | Reality |
|--------|---------|
| "Lowercase is fine—StyleCop will fix it." | StyleCop does not rewrite attribute arguments; lowercase fails PermissaoTests. |
| "Duplicated GUIDs are temporary; I'll fix post-QA." | Test `NaoDevePossuirRegrasRepetidas` fails immediately; duplicates block merges. |
| "Only public requests need attributes." | `TodosRequestsDevemTerAtributoPermissao` searches every `IBaseRequest`, regardless of visibility. |
| "Regenerating GUIDs might break consumers." | GUIDs are identifiers for permissions, not external contracts; duplicates or lowercase break compliance faster. |
| "SemPermissao is enough; I can skip attribute entirely." | Missing both attributes is forbidden; default to `Permissao` unless that request already used `SemPermissao`. |
| "I'll tweak an existing GUID to keep numbers tidy." | Altering existing GUIDs corrupts permission contracts; never modify unless explicitly told to, or if the file itself is brand-new. |

## Red Flags – STOP and Reapply Checklist
- You copied an existing request and left the original GUID.
- You cannot recite the uppercase GUID requirement.
- You assumed helper/internal commands are exempt from attributes.
- You added a new request and copied an old `SemPermissao` usage without confirming it's still valid.
- You added a request inside a file but did not search for duplicates.
- You edited an existing GUID string without explicit approval (or outside a newly created file).
- Authority/time pressure made you say "fix later".

## Verification
Before declaring work done:
- Re-open changed files and confirm every `IBaseRequest` type shows `[Permissao]` or `[SemPermissao]`.
- Re-run your duplicate search using `rg -i "[A-F0-9]{8}(-[A-F0-9]{4}){3}-[A-F0-9]{12}"` scoped to changed GUIDs.
- Optionally run `dotnet test test/Application.UnitTests/Common/PermissaoTests.cs` if time permits, but the ritual must keep the test green even without execution.
