---
name: api-dto-enums
description: Use when defining or updating enums consumed by DTOs in frontend data services—keeps enum files colocated with DTOs, numeric values synced with backend, plus description/option maps for UI reuse (as modeled by BloqueioPorInadimplenciaStatusEnum).
---

# API DTO Enums

## Overview
DTO enums are shared contracts: they must live next to the DTOs, expose numeric values matching the backend, and provide helper maps so components never duplicate labels or options. This skill documents the exact pattern (enum + description map + options array) already used by `BloqueioPorInadimplenciaStatusEnum`.

## When to Use
- Backend exposes numeric codes that appear in DTO fields.
- You add a new status/type enum under `src/app/data/**/dto`.
- You need label/options for selects, badges, or chips based on that enum.

**Never skip because** “it’s only used once,” “string unions are faster,” or “UI can hardcode labels.” Strings drift and break serialization the moment backend changes.

## Core Rules
1. **File location**: same folder as the DTOs (e.g., `src/app/data/contrato/bloqueio-por-inadimplencia/dto`).
2. **File naming**: `<recurso>-<contexto>-<enum>.enum.ts` (kebab-case). Example: `bloqueio-por-inadimplencia-status.enum.ts`.
3. **Enum declaration**: `export enum <NomePascalEnum> { Item = numericValue }`, values mirror backend integers; never rely on implicit numbering.
4. **Description map**: export `descricao<NomeEnum> : Record<Enum, string>` with every member mapped to a human-friendly label.
5. **Options array**: export `<camelCaseEnum>Options` built from the description map via `Object.entries` returning `{ label, value }` with `value` typed as the enum.
6. **Re-export**: add the enum file to `dto/index.ts` so consumers import from `@data/.../dto`.
7. **Usage**: DTO interfaces reference the enum type; UI imports description/options helpers instead of retyping strings.
8. **Updates**: when backend adds a new value, add it to enum + description + options in the same commit; failing to update any part is a blocking error.

## Quick Reference
| Concern | Rule | Example |
|---------|------|---------|
| Enum name | PascalCase + `Enum` suffix | `BloqueioPorInadimplenciaStatusEnum` |
| Numeric value | Explicit number matching backend | `Ativo = 0` |
| Description map | `descricao<NomeEnum>` constant | `descricaoBloqueioPorInadimplenciaStatus` |
| Options array | `<camelCaseEnum>Options` | `bloqueioPorInadimplenciaStatusOptions` |
| Imports | DTOs/features import from `@data/.../dto` | `import { BloqueioPorInadimplenciaStatusEnum } from ...` |

## Implementation Flow
1. **Create enum file** mirroring DTO directory.
2. **Declare enum** with explicit numeric values from backend contract/spec.
3. **Add description map** with Portuguese labels vetted by UX/PO when needed.
4. **Build options array** from the map:
   ```ts
   export const bloqueioPorInadimplenciaStatusOptions = Object
     .entries(descricaoBloqueioPorInadimplenciaStatus)
     .map(([key, label]) => ({
       label,
       value: Number(key) as BloqueioPorInadimplenciaStatusEnum,
     }));
   ```
5. **Export via index**: in `dto/index.ts`, export everything from the new enum file.
6. **Replace string literals** in components/services with the enum + helpers.
7. **Add tests** (if present) verifying dropdowns render labels from the helper (not hardcoded).

## Example (from Bloqueio por Inadimplência)
`bloqueio-por-inadimplencia-status.enum.ts`
```ts
export enum BloqueioPorInadimplenciaStatusEnum {
  Ativo = 0,
  Regularizado = 1,
  Desbloqueado = 2,
  Pendente = 3,
}

export const descricaoBloqueioPorInadimplenciaStatus: Record<BloqueioPorInadimplenciaStatusEnum, string> = {
  [BloqueioPorInadimplenciaStatusEnum.Ativo]: 'Bloqueio Ativo',
  [BloqueioPorInadimplenciaStatusEnum.Desbloqueado]: 'Desbloqueado',
  [BloqueioPorInadimplenciaStatusEnum.Regularizado]: 'Regularizado',
  [BloqueioPorInadimplenciaStatusEnum.Pendente]: 'Pendente',
};

export const bloqueioPorInadimplenciaStatusOptions = Object
  .entries(descricaoBloqueioPorInadimplenciaStatus)
  .map(([key, label]) => ({
    label,
    value: Number(key) as BloqueioPorInadimplenciaStatusEnum,
  }));
```

## Common Mistakes (and Fixes)
| Mistake | Fix |
|---------|-----|
| String unions declared inside components | Move to `/dto` enum file, explicit numeric values. |
| Missing description map | Add `descricaoEnum` so UI labels stay centralized. |
| Dropdown hardcodes `{ label: 'Ativo', value: 0 }` | Import `<enum>Options` constant instead. |
| Enum not exported from `index.ts` | Update `dto/index.ts` to re-export; otherwise consumers use long relative paths. |
| Added enum member but forgot options | PR should fail—update enum, description, options together. |

## Verification
- Search for string literals referencing the enum values in the feature; replace with the enum/description/options exports.
- Ensure `dto/index.ts` exports the enum file.
- Specs using the enum compile after imports switch to `@data/.../dto`.
- If the backend doc changes numeric codes, update and run affected tests before merging.
