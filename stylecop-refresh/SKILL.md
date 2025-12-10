name: stylecop-refresh
description: Use when about to editing or creating .NET source, build, or test files and feel tempted to rely on memory for StyleCop/editorconfig/Directory.Build.props rules instead of rereading them—forces a pre-writing refresher ritual so formatting, ordering, and analyzer settings stay compliant even under time pressure.

# StyleCop Refresh Ritual

## Overview
Before typing anything in a .NET project, reopen every rules source that actually drives formatting and analyzer behavior. Memory fades, overrides vary per directory, and Directory.Build.props toggles analyzers that you assume are on. This skill forces the refresh ritual so you never guess what StyleCop, StyleCopPlus, or EditorConfig expect.

Violating the letter of these steps _is_ violating their spirit. Deleting and rewriting code is cheaper than chasing analyzer noise in CI.

## When to Use
- Writing or editing any `.cs`, `.csproj`, `.targets`, or other files governed by StyleCop/editorconfig.
- Switching folders or branch after lunch, deploys, or long tasks.
- Anytime you think “I already know the line length / using order / analyzer set.”

**Never skip because**: you are tired, it’s a hotfix, a senior told you to hurry, or you “just changed this yesterday.”

## Mandatory Refresh Checklist
1. **Root `.editorconfig` down to file scope**: start at repo root and walk toward the target folder. Note any overrides (e.g., `src/Infra/Migrations/.editorconfig`).
2. **`stylecop.json`**: reread ordering rules and `styleCopPlusRules` (max line/file/method/accessor lengths, etc.). Snapshot the numbers in your notes/brain _now_.
3. **`Directory.Build.props`**: confirm analyzers, `RunAnalyzersDuringBuild`, `AdditionalFiles` links, and any conditional property (tests vs app vs domain). Remember: props decide whether warnings appear locally.
4. **`Directory.Build.targets` or other props/targets**: skim quickly for additional analyzer directives or linked rulesets.
5. **Only after all four are re-opened** may you start editing. Keep them visible or pinned until work is done.

If you already typed code before completing the checklist, delete those edits, do the checklist, then re-implement.

## Quick Reference
| Situation | File to reread |
|-----------|----------------|
| Unsure about indentation/spacing/naming | `.editorconfig` (root + nearest override) |
| Wondering about using order / placement | `stylecop.json` (`orderingRules.usingDirectivesPlacement`) |
| Max line/method/property accessor lengths | `stylecop.json` → `styleCopPlusRules` |
| Analyzer turned off locally? | `Directory.Build.props` (`RunAnalyzersDuringBuild`, `AdditionalFiles`) |
| Test projects needing special props | `Directory.Build.props` (look at `IsTest`/`IsUnitTest` blocks) |

## Example Refresh (Before Editing)
```text
1. open .editorconfig (root) → note indentation 4 spaces, newline rules.
2. open src/Infra/Migrations/.editorconfig → notice overrides for migration snapshots.
3. open stylecop.json → confirm using directives outside namespace + max method length 50.
4. open Directory.Build.props → see RunAnalyzersDuringBuild=false currently; must rely on manual dotnet format or IDE.
5. only now start editing FaturaService.cs.
```

## Common Rationalizations (and Reality)
| Excuse | Reality |
|--------|---------|
| "I remember the rules from last sprint." | Overrides change per folder; memory drifts. Refresh takes <2 min. |
| "Directory.Build.props is build-only." | It controls analyzers and copies stylecop.json. Ignore it and IDE may hide violations. |
| "CI/PR will catch it." | Fixing later burns reviewers’ time and blocks pipelines. Refresh avoids churn. |
| "IDE formatting equals .editorconfig." | Only if config hasn’t changed; overrides + extension updates break assumptions. |

## Red Flags – STOP and Refresh
- You can’t quote the current max method/line length or using placement.
- `RunAnalyzersDuringBuild` is false and you planned to trust build output.
- You switched directories/branches and didn’t reopen configs.
- Someone says “just trust your muscle memory.”

## Common Mistakes
- Reading only the root `.editorconfig` and missing folder overrides.
- Forgetting that stylecop.json enforces StyleCopPlus limits; exceeding them causes warnings later.
- Assuming Directory.Build.props is irrelevant to local editing because analyzers run in CI.

## Verification Ritual
Before claiming code is ready:
- Run the checklist again if you closed the files mid-session.
- Verify IDE/editor is using the refreshed settings (reload solution if needed).
- If analyzers are disabled locally (`RunAnalyzersDuringBuild=false`), run `dotnet format` or equivalent manually.
