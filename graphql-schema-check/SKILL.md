---
name: graphql-schema-check
description: Use when adding or editing GraphQL gql`` strings inside .ts files and tempted to trust memory instead of loading the current schema—first probe http://localhost:5000/graphql, falling back to graphql.config.yml, then validate every operation before coding
---

# GraphQL Schema Check

## Overview
Every time you touch a `gql` template literal, ground yourself in the real schema. Probe the local gateway (`http://localhost:5000/graphql`) first; if it’s unavailable, fall back to `BASE_URL` from `src/environments/environment.ts` + `/graphql`. Once you have the freshest schema, validate your operations so DTOs, mappers, and Apollo services stay in sync.

## When to Use
- Modifying any "gql\`` string inside .ts" files (services, fragments, generated queries).
- Updating DTOs/models computed from GraphQL responses.
- Debugging GraphQL errors that might stem from schema drift.
- Skip only for pure REST work or TS files with no `gql` calls.

## Core Pattern
1. **Use the helper script.**
   ```bash
   ./graphql-schema-check/fetch-schema.sh
   ```
   - Tries `http://localhost:5000/graphql` first.
   - Falls back to `BASE_URL` from `src/environments/environment.ts` (if present) + `/graphql`.
   - Saves to `docs/graphql/schema.graphql` (relative to current working directory), overwriting if it exists.
2. **Search before coding.** Use `rg -n "type NomeDoTipo" docs/graphql/schema.graphql` to confirm field names, args, enums, and directives. Never rely on memory.
3. **Validate every operation.**
   - `npx graphql validate --schema docs/graphql/schema.graphql --documents "src/app/**/*.ts"` works because the CLI parses `gql` template literals.
   - Alternatively, use VSCode GraphQL extension pointing to `docs/graphql/schema.graphql`.
4. **Regenerate/update DTOs.** If operations changed shape, run the project’s codegen (if available) or manually sync interfaces in `@data/.../dto`.
5. **Document tricky fields.** Leave a short comment referencing the schema section when a non-obvious argument (`withHistoric`, `includeInactive`) is required.

## Example Session
```bash
cd /home/mendes/projetos/eugestor/frontend
./graphql-schema-check/fetch-schema.sh
rg -n "type ContratoFatura" docs/graphql/schema.graphql
npx graphql validate --schema docs/graphql/schema.graphql --documents "src/app/**/*.ts"
```

## Pressure Scenario (RED→GREEN)
- **Setup:** New mutation needed in `src/app/data/contrato/contratos/contrato.service.ts`. Local backend might be running, but you’re unsure; deadline in 15 minutes, teammate says “just copy an existing gql snippet.”
- **Without skill:** You edit the `gql\`` string directly, guessing fields, and only discover mismatches when Apollo throws runtime errors.
- **With skill:** You ping `http://localhost:5000/graphql`, fall back to the remote endpoint if needed, download the schema, run `graphql validate`, and update DTOs before touching business logic—getting correct coverage despite time pressure.

## Rationalization Table
| Excuse | Reality |
| --- | --- |
| “Local server is probably accurate; I’ll skip the ping.” | If it’s down or outdated, you’ll validate against stale data. The script picks the correct endpoint. |
| “gql strings in TS won’t be picked up by validators.” | The `graphql` CLI parses `gql\`` literals; validation works as long as you point it to `src/app/**/*.ts`. |
| “I’ll fix schema mismatches after manual testing.” | Manual tests may hit mocked responses, hiding schema issues until production. Validate first. |
| “Fetching schema needs auth; too annoying.” | Reuse existing dev tokens or environment variables; still faster than debugging broken queries. |

## Red Flags
- PRs with new `gql` operations but no evidence of validation (no schema fetch, no DTO updates).
- Using fields removed from the latest schema or missing required arguments.
- Hardcoding remote URLs everywhere instead of letting the script choose local vs BASE_URL.

## Common Mistakes
- **Keeping an old schema snapshot.** Always re-fetch when starting new GraphQL work.  
- **Forgetting auth headers on remote endpoints.** Use `curl -H` or environment variables to pass tokens.  
- **Validating only edited files.** Run validation across the entire `src/app` tree; cross-file fragments may break otherwise.

## Deployment Notes
Reference this skill in CLAUDE/AGENTS so any GraphQL-related task loads it automatically. The helper script already handles local vs. BASE_URL fallback.
