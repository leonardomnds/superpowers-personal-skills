---
name: query-params-sync
description: Use when creating or updating Query classes consumed by QueryParamsSyncComponent—ensures every query has a PrimitiveTypes override class and is registered in query-params-sync.utils.ts so sync can infer types for undefined fields.
---

# QueryParamsSync Queries

## Overview
`QueryParamsSyncComponent` needs concrete values to infer parameter types. Any Query class with fields initialized to `undefined` must expose a companion `PrimitiveTypes` class that overrides those properties with sample primitives. This skill documents the pattern and the mandatory registration in `query-params-sync.utils.ts`.

## When to Use
- You add a new Query class used with `QueryParamsSyncComponent`.
- An existing Query gains new properties without defaults.
- Sync utils throw because a key returns `undefined`.

**Do NOT skip because** the query is “module-specific” or “only has 1 field.” Missing primitive overrides silently break URL sync and filtering.

## Core Rules
1. **Query class** lives wherever the DTO resides (usually `src/app/data/**/dto`), exported via folder index.
2. **PrimitiveTypes class** shares the same file, extends the query, and overrides every property that starts undefined/empty.
3. **Override values** must match the real type (string, number, enum, boolean, array). Use representative defaults.
4. **Arrays/objects** get a minimal representative (e.g., `[Enum.Value]` or `[]` when arrays default empty).
5. **Optional numbers/IDs** override with `1` (or other positive int) to satisfy type inference.
6. **Remember enums**: set overrides using actual enum members, not raw numbers for readability.
7. **Register both classes** in `query-params-sync.utils.ts`:
   - Import `Query` + `PrimitiveTypes`.
   - Add a `case params instanceof YourQuery` returning `new YourQueryPrimitiveTypes()`.
8. **Tests/specs** referencing the query should import from the DTO path (ensuring tree remains consistent).

## Quick Reference
| Step | Action | Example |
|------|--------|---------|
| Define Query | Class with defaults | `export class OrcamentosQuery { pagina = 1; ... }` |
| PrimitiveTypes | Extend + override undefined fields | `export class OrcamentosQueryPrimitiveTypes extends OrcamentosQuery { override dataInicio = new Date() as any; }` |
| Register | `query-params-sync.utils.ts` switch | `case params instanceof OrcamentosQuery: return new OrcamentosQueryPrimitiveTypes();` |
| Imports | DTO entrypoint | `import { OrcamentosQuery, OrcamentosQueryPrimitiveTypes } from '@data/comercial/orcamento/dto';` |

## Implementation Flow
1. **Audit fields**: any property without a value literal needs an override (e.g., `dataInicio?: string`).
2. **Add PrimitiveTypes class** immediately under the query definition:
   ```ts
   export class LeadsDashboardQueryPrimitiveTypes extends LeadsDashboardQuery {
     override periodo = '7d';
     override vendedorId = 1;
   }
   ```
3. **Export via index** so other modules pull from `@data/.../dto`.
4. **Register in utils**:
   ```ts
   import { LeadsDashboardQuery, LeadsDashboardQueryPrimitiveTypes } from '@data/...';
   // switch
   case params instanceof LeadsDashboardQuery:
     return new LeadsDashboardQueryPrimitiveTypes();
   ```
5. **Verify QueryParamsSyncComponent** receives the new query and the router syncs correctly (watch row filters update).

## Example (Orçamentos)
`orcamento-query.dto.ts`
```ts
export class OrcamentosQuery {
  pagina = 1;
  tamanhoPagina = 20;
  ordenarPor = '';
  decrescente = true;
  termo = '';
  exibirCancelados = true;
  filtrarPorData = OrcamentoTipoFiltroDataEnum.Abertura;
  dataInicio?: string;
  dataFim?: string;
  filtrarPor: OrcamentoTipoFiltroTermoEnum[] = [
    ...Object.values(OrcamentoTipoFiltroTermoEnum).filter((x) => typeof x === 'number') as OrcamentoTipoFiltroTermoEnum[],
  ];
  modalidadeOrcamento?: OrcamentoModalidadeEnum;
  statusOrcamento?: OrcamentoSituacaoEnum;
  tipoCliente?: OrcamentoTipoClienteEnum;
  motivoRecusaOrcamentoId?: number;
  vendedorId?: number;
  contratoId?: number;
  pessoaId?: number;
}

export class OrcamentosQueryPrimitiveTypes extends OrcamentosQuery {
  override dataInicio = new Date() as any;
  override dataFim = new Date() as any;
  override modalidadeOrcamento = OrcamentoModalidadeEnum.Venda;
  override statusOrcamento = OrcamentoSituacaoEnum.Aberto;
  override tipoCliente = OrcamentoTipoClienteEnum.Cliente;
  override motivoRecusaOrcamentoId = 1;
  override vendedorId = 1;
  override contratoId = 1;
}
```

`query-params-sync.utils.ts` (excerpt)
```ts
import { OrcamentosQuery, OrcamentosQueryPrimitiveTypes } from '@data/comercial/orcamento/dto/orcamento-query.dto';

export const getOriginalClass = (params: any) => {
  switch (true) {
    case params instanceof OrcamentosQuery:
      return new OrcamentosQueryPrimitiveTypes();
    // ...
  }
};
```

## Common Mistakes
- **Skipping PrimitiveTypes** because every property “already has default” → query sync fails the moment a new optional field is added.
- **Forgetting utils registration** → QueryParamsSyncComponent can’t infer types and treats everything as string.
- **Using `any` overrides** everywhere → loses type safety; only use `as any` when unavoidable (dates).
- **Not exporting via index** → other modules import via relative paths, causing duplication.

## Verification
- Search `class <YourQuery>` and confirm a corresponding `PrimitiveTypes` exists.
- Ensure `query-params-sync.utils.ts` switch includes your query and returns the primitive class.
- Run the feature with QueryParamsSyncComponent open; change filters and reload—URL/state should restore correctly.
