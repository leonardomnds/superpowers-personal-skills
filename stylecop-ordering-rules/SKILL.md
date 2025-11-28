---
name: stylecop-ordering-rules
description: Use when the repository sets usingDirectivesPlacement to outsideNamespace - enforces that all using directives appear before the namespace, groups System.* first, and normalizes grouping and alphabetical order.
---

# StyleCop Ordering Rules (project-configured)

## Overview
Applies ordering rules based on the StyleCop schema, customized for this project where:

`usingDirectivesPlacement = "outsideNamespace"`

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to use
- When PRs add or change `using` directives.
- When files contain `using` inside a `namespace`.
- When cleaning or standardizing imports across the codebase.

## Core pattern
1. **Placement (mandatory):** All `using` directives must be **before** any `namespace` declaration. Any `using` found inside a namespace must be moved to the top of the file.
2. **Grouping (recommended):**
    - Group 1: `System.*`
    - Group 2: external libraries
    - Group 3: internal/project namespaces
    - Separate groups with a single blank line.
3. **Ordering (recommended):** Alphabetical order inside each group. `System.*` group appears first.

## Quick reference
- `using` inside namespace → **violation**
- `using` before namespace → **required**
- `System.*` first → **recommended**
- Blank line between groups → **recommended**
- Alphabetical inside group → **recommended**

## Implementation notes
- Detect all `using` blocks and any that appear after the first `namespace`.
- Move `using` blocks found after the namespace to the top, then normalize grouping and order.
- Preserve comments immediately adjacent to `using` lines.
- Prefer AST-based fixer (Roslyn) for safe moves; regex-only detection OK for reporting.

## Common mistakes
- Leaving `using` inside file-scope `namespace` declarations by habit.
- Mixing system and project usings in the same group.
- Forgetting to preserve comments tied to specific usings.

## Tests

### Test A — Using after namespace
Before:
```csharp
namespace MyApp;

using System;
using MyApp.Services;
```

After:
```csharp
using System;
using MyApp.Services;

namespace MyApp;
```

### Test B — Order and grouping
Before:
```csharp
using Project.Core;
using System.Text;
using System;
```

After:
```csharp
using System;
using System.Text;

using Project.Core;
```

### Test C — Usings scattered
Before:
```csharp
using System;

namespace Abc;

class A {}

using Project.Utils;
```

After:
```csharp
using System;
using Project.Utils;

namespace Abc;

class A {}
```
