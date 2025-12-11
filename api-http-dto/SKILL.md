---
name: api-http-dto
description: Use when building frontend (Angular/TypeScript) features that talk to REST APIs through HttpClient—forces every request body, response, and query param object into named DTO/Query artifacts so payloads stay discoverable, reusable, and auditable even under delivery pressure.
---

# API HttpClient DTOs

## Overview
Every HttpClient call in the frontend must exchange typed DTOs/Queries that live in their own files. Inline interfaces or ad-hoc objects hide payload contracts, making prompt tweaks and backend negotiations impossible to audit later. This skill keeps REST integrations consistent by enforcing naming, file layout, and reuse rules.

## When to Use
- Adding or updating any HttpClient call (services, data-services, interceptors) that talks to the external API.
- Modeling request or response payloads used by AI/API orchestration flows.
- Wiring query parameters for list/search endpoints.

**Do NOT skip because** the endpoint is tiny, experimental, or “UI only.” If the browser sends or receives JSON, it gets a DTO/Query file.

## Core Rules
1. **Request/response bodies** are `interface` (or `type`) with suffix `Dto`.
2. **Files** use `kebab-case` + `.dto.ts`; keep one DTO per file unless sharing primitives.
3. **Http verb prefix** is mandatory when DTO is tied to a data-service method (`Get`, `Post`, `Put`, `Patch`, `Delete`).
4. **Names follow** `VerboRecurso[Qualificador]Dto`, e.g., `PostCriarPromptDto` → `post-criar-prompt.dto.ts`.
5. **POST/PUT endpoints with different input/output shapes** must create both `VerboRecursoDto` (request) and `VerboResponseRecursoDto` (response) files, e.g., `PostContextoDto` + `PostResponseContextoDto`.
6. **Query parameters** use `class` with suffix `Query` stored in `.query.ts`, pattern `VerboRecurso[Qualificador]Query`.
7. **Responses coming through `BaseUrlInterceptor`** must type the HttpClient call as `ApiResponse<TDto>`; paginated endpoints wrap with `ApiResponse<ListaPaginada<TDto>>`.
8. **GraphQL responses** use the `QueryGql<Recurso>Dto` pattern and live in `query-gql-<recurso>.dto.ts`; keep reusing existing DTOs for nested pieces.
9. **No inline payloads** inside components/services; import from the DTO/Query file instead.
10. **Nunca use DTO/Query legado como molde**—sempre derive nome e arquivo a partir do endpoint (verbo + recurso + qualificador) mesmo que haja arquivos fora do padrão no projeto.

## Quick Reference
| Artifact | Purpose | Naming | File |
|----------|---------|--------|------|
| Request/response DTO | Body sent/received via HttpClient | `PostAdicionarServicoCobradoOrdemServicoDto` | `post-adicionar-servico-cobrado-ordem-servico.dto.ts` |
| Response DTO (POST/PUT output) | Return body of same endpoint | `PostResponseAdicionarComentarioOrdemServicoDto` | `post-response-adicionar-comentario-ordem-servico.dto.ts` |
| Interceptor responses | Result of BaseUrlInterceptor calls | `ApiResponse<PostAdicionarServicoCobradoOrdemServicoDto>` | Typed at call site |
| Verb-scoped DTO | Data-service method payload | `PutAlterarEnderecoOrdemServicoDto` | `put-alterar-endereco-ordem-servico.dto.ts` |
| Query params | REST filters, pagination | `GetHistoricoOrdemServicoQuery` | `get-historico-ordem-servico-query.ts` |
| GraphQL result | Shape of `data` | `QueryGqlDadosFechamentoOrdemServicoDto` | `query-gql-dados-fechamento-ordem-servico.dto.ts` |

Place these files next to the feature’s data service (e.g., `src/app/data/operacional/ordem-servico/dto`). Re-export via `index.ts` when a folder has multiple DTOs.

## Implementation Flow
1. **Name first**: derive `Verbo` from HTTP method, `Recurso` from backend noun, append qualifiers (e.g., `Detalhado`, `Resumo`).
2. **Create file**: `ng g` cannot scaffold this—manually add the `.dto.ts`/`.query.ts` file before touching the service.
3. **Define shape**: fields mirror backend contract; when request/response differ, model both (e.g., `PostAdicionarServicoCobradoOrdemServicoDto` vs `PostResponseAdicionarComentarioOrdemServicoDto`) and reuse nested DTOs instead of duplicating.
4. **Use everywhere**: services, facades, and specs import the DTO instead of anonymous objects.
5. **Evolve with backend**: when API changes, edit the DTO file; every usage compiles red, forcing full review.

## Common Rationalizations (and Reality)
| Excuse | Reality |
|--------|---------|
| “It’s just two fields; inline is faster.” | Next tweak forces hunting through services. Creating a file takes <1 min and documents the contract. |
| “Payload is UI-specific.” | If it crosses HttpClient, backend depends on it—name it after the API resource, not the component. |
| “Queries are overkill for two params.” | Query classes document pagination defaults and keep interceptors type-safe. |
| “I’ll refactor after we ship.” | You never do. Reviewers block merges once payloads are inline; do it right now. |
| “Vou copiar o nome/arquivo legado para manter igual.” | Legados podem estar fora do padrão; derive sempre do endpoint e siga esta skill para convergirmos. |

## Red Flags – Stop and Fix
- You can’t point to the DTO file for a request you are editing.
- A service defines `interface Payload` or `const body = { ... }` right above `http.post`.
- Query params are plain objects or `HttpParams` built inline.
- File name lacks verb prefix or `Dto` suffix.
- Você está reutilizando nome/arquivo legado fora do padrão em vez de seguir verbo + recurso + qualificador desta skill.

## Example
`post-adicionar-servico-cobrado-ordem-servico.dto.ts`
```ts
export interface PostAdicionarServicoCobradoOrdemServicoDto {
  ordemServicoId: number;
  servicoId: number;
  quantidade: number;
  valorUnitario: number;
  desconto: OrdemServicoDescontoRequest | null;
  rastreavelId?: number | null;
}
```

`post-response-adicionar-comentario-ordem-servico.dto.ts`
```ts
export interface PostResponseAdicionarComentarioOrdemServicoDto {
  ordemServicoComentarioId: number;
  ordemServicoId: number;
  comentario: string;
  usuarioId: number;
  dataComentario: string;
  tipoComentario: TipoComentarioOrdemServicoEnum;
}
```

`get-historico-ordem-servico-query.ts`
```ts
export class GetHistoricoOrdemServicoQuery {
  ordemServicoId: number;
  termo = '';
  pagina = 1;
  tamanhoPagina = 20;
  ordenarPor = 'registroEventoId';
  decrescente = true;
  incluirLogs = false;

  constructor(ordemServicoId: number) {
    this.ordemServicoId = ordemServicoId;
  }
}
```

Usage inside a service:
```ts
return this.http.post<ApiResponse<PostResponseAdicionarComentarioOrdemServicoDto>>(
  url,
  body as PostAdicionarServicoCobradoOrdemServicoDto
);
```

Paginated variant:
```ts
return this.http.get<ApiResponse<ListaPaginada<GetResponseAtendimentosOrdemServicoDto>>>(
  url,
  { params: query.toParams() }
);
```

`query-gql-dados-fechamento-ordem-servico.dto.ts`
```ts
export interface QueryGqlDadosFechamentoOrdemServicoDto extends TotaisOrdemServicoDto {
  dadosCobranca: GetDadosCobrancaOrdemServicoDto;
  dadosFechamento: GetDadosFechamentoOrdemServicoDto;
  pendencias: PendenciaFechamentoOrdemServicoDto[];
}
```

## Verification
Before marking the feature done:
- Search for `http.` usages you touched; confirm each imports DTO/Query files.
- Check filenames align with verb/resource and live next to their data service.
- Ensure specs leverage the same DTOs to build fixtures (no duplicated literals).
