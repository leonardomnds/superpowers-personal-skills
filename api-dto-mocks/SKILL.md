---
name: api-dto-mocks
description: Use when adding or updating HttpClient DTOs in the frontend and need deterministic test data—enforces generate* mock factories beside the DTOs (faker-powered, reusable, exported via mocks index) so specs stop duplicating literal objects.
---

# API DTO Mocks

## Overview
Every DTO that crosses HttpClient should have a matching mock generator so specs, stories, and manual fixtures stay consistent with the contract. This skill defines how to author those helpers with faker, reuse nested generators, and place them under `src/app/data/**/mocks` next to the DTOs.

## When to Use
- You created/edited a DTO (request or response) for OrdemServicoService or any other data service.
- A spec/story/song needs mock data for that DTO.
- A regression requires tweaking existing mock helpers.

**Never skip because** “it’s just one test,” “I can copy a literal,” or “faker isn’t worth it.” No generator → future edits miss the contract drift.

## Core Rules
1. **One generator per DTO** with name `generate<DtoName>` returning the typed object.
2. **Location mirrors DTO folder** (`src/app/data/operacional/ordem-servico/mocks/post-adicionar-servico-cobrado-ordem-servico.mock.ts`).
3. **File naming**: identical to the DTO filename but `.mock.ts` suffix; DTO `post-adicionar-servico-cobrado-ordem-servico.dto.ts` → mock `post-adicionar-servico-cobrado-ordem-servico.mock.ts` exporting `generatePostAdicionarServicoCobradoOrdemServicoDto`.
4. **Always export from the mocks `index.ts`** so imports stay short (`@data/operacional/ordem-servico/mocks`).
5. **Use `faker` helpers** (numbers, strings, enums, dates) to avoid stale literals.
6. **Reuse nested generators** (e.g., `generateOrdemServicoDescontoRequest`) instead of rebuilding structures.
7. **Keep optional fields optional**: omit when not mandatory or randomize presence using ternaries.
8. **Provide arrays/lists** by mapping the generator (e.g., `Array.from({length: 3}, generate...)`).
9. **For API responses** wrap with `generateApiResponse(generator())` helper if available, otherwise build the `ApiResponse<T>` shape manually.

## Quick Reference
| Task | Rule | Example |
|------|------|---------|
| Request DTO mock | `generate<DtoName>` returns DTO literal | `generatePostAdicionarServicoCobradoOrdemServicoDto()` |
| Response DTO mock | Same naming w/ response DTO | `generatePostResponseAdicionarComentarioOrdemServicoDto()` |
| File path | Mirror DTO path | `post-adicionar-servico-cobrado-ordem-servico.mock.ts` |
| Nested data | Call existing generator | `desconto: generateOrdemServicoDescontoRequest()` |
| Enum field | Use `faker.helpers.enumValue(Enum)` | `tipoComentario` field |
| Pagination payload | Compose `ListaPaginada` helper | `generateListaPaginada(generateGetResponseAtendimentos...)` |

## Implementation Flow
1. **Check DTO exports**: ensure `/dto/index.ts` exposes the type you’ll mock.
2. **Create mock file** under `/mocks` mirroring the DTO filename.
3. **Import dependencies**: DTO type, nested generators, `faker`.
4. **Write generator**:
   ```ts
   export const generatePostAdicionarServicoCobradoOrdemServicoDto = (
     overrides: Partial<PostAdicionarServicoCobradoOrdemServicoDto> = {}
   ): PostAdicionarServicoCobradoOrdemServicoDto => ({
     ordemServicoId: faker.number.int(),
     servicoId: faker.number.int(),
     quantidade: faker.number.int({ min: 1, max: 5 }),
     valorUnitario: faker.number.float({ min: 10, max: 500, fractionDigits: 2 }),
     desconto: generateOrdemServicoDescontoRequest(),
     rastreavelId: faker.helpers.maybe(() => faker.number.int(), { probability: 0.5 }) ?? null,
     ...overrides,
   });
   ```
   - Always support an optional `overrides` bag for specs that need determinism.
5. **Add list helpers** when endpoint returns collections:
   ```ts
   export const generateManyResponseAtendimentos = (total = 3) =>
     Array.from({ length: total }, () => generateGetResponseAtendimentosOrdemServicoDto());
   ```
6. **Update `/mocks/index.ts`** to export the new generator(s).
7. **Replace literals** in nearby specs with the generator to verify it compiles.

## Example Files
`post-adicionar-servico-cobrado-ordem-servico.mock.ts`
```ts
import { PostAdicionarServicoCobradoOrdemServicoDto } from "@data/operacional/ordem-servico/dto";
import { faker } from "@faker-js/faker";
import { generateOrdemServicoDescontoRequest } from "@data/operacional/ordem-servico/mocks";

export const generatePostAdicionarServicoCobradoOrdemServicoDto = (
  overrides: Partial<PostAdicionarServicoCobradoOrdemServicoDto> = {}
): PostAdicionarServicoCobradoOrdemServicoDto => ({
  ordemServicoId: faker.number.int(),
  servicoId: faker.number.int(),
  quantidade: faker.number.int({ min: 1, max: 10 }),
  valorUnitario: faker.number.float({ min: 50, max: 900, fractionDigits: 2 }),
  desconto: generateOrdemServicoDescontoRequest(),
  rastreavelId: faker.helpers.maybe(() => faker.number.int(), { probability: 0.4 }) ?? null,
  ...overrides,
});
```

`post-response-adicionar-comentario-ordem-servico.mock.ts`
```ts
import {
  PostResponseAdicionarComentarioOrdemServicoDto,
  TipoComentarioOrdemServicoEnum,
} from "@data/operacional/ordem-servico/dto";
import { faker } from "@faker-js/faker";

export const generatePostResponseAdicionarComentarioOrdemServicoDto = (
  overrides: Partial<PostResponseAdicionarComentarioOrdemServicoDto> = {}
): PostResponseAdicionarComentarioOrdemServicoDto => ({
  ordemServicoComentarioId: faker.number.int(),
  ordemServicoId: faker.number.int(),
  comentario: faker.lorem.sentence(),
  usuarioId: faker.number.int(),
  dataComentario: faker.date.recent().toISOString(),
  tipoComentario: faker.helpers.enumValue(TipoComentarioOrdemServicoEnum),
  ...overrides,
});
```

`get-historico-ordem-servico.mock.ts`
```ts
import { faker } from "@faker-js/faker";
import { GetResponseHistoricoOrdemServicoDto } from "@data/operacional/ordem-servico/dto";

export const generateGetResponseHistoricoOrdemServicoDto = (
  overrides: Partial<GetResponseHistoricoOrdemServicoDto> = {}
): GetResponseHistoricoOrdemServicoDto => ({
  registroEventoId: faker.number.int(),
  ordemServicoId: faker.number.int(),
  titulo: faker.lorem.words(),
  descricao: faker.lorem.sentence(),
  dataRegistro: faker.date.recent().toISOString(),
  usuario: faker.person.fullName(),
  ...overrides,
});
```

## Common Mistakes
- **Copying literals into specs** instead of creating/using a generator → future schema change silently breaks tests.
- **Forgetting overrides** so tests can assert stable IDs/dates.
- **Rebuilding nested objects**: call `generateOrdemServicoDescontoRequest()` instead of duplicating its shape.
- **Not exporting from `index.ts`**, forcing long relative imports.
- **Using faker incorrectly** (e.g., `faker.random.number` deprecated). Prefer `faker.number.*` / `faker.helpers`.

## Verification
Before finishing:
- Specs compile using only the generators (no inline DTO literals).
- `npm run lint` succeeds after updating `index.ts`.
- Search `generate<DtoName>` returns exactly one implementation in the mocks folder.
- Running the relevant spec(s) proves the generator is consumed.
