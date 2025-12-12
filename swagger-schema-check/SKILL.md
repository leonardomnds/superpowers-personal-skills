---
name: swagger-schema-check
description: Use when touching REST endpoints (HttpClient/DataService) to refresh the Swagger/OpenAPI spec—ping http://localhost:5000/swagger first, fall back to the BASE_URL from src/environments/environment.ts, download /swagger/v1/swagger.json, and validate DTOs/routes before coding.
---

# Swagger Schema Check

## Overview
Before editing any REST integration, load the real Swagger/OpenAPI document. Probe the local backend (`http://localhost:5000/swagger`) first; if it’s unavailable, read `src/environments/environment.ts` to discover `BASE_URL` and open `${BASE_URL}/swagger`. With the freshest `/swagger/v1/swagger.json`, you can verify endpoints, payloads, and DTOs so HttpClient calls don’t drift.

## When to Use
- Adding or updating HttpClient methods, interceptors, DTOs, or mocks for REST APIs.
- Investigating 400/500s caused by contract changes.
- Designing new request/response bodies for backend-bound features.

Skip only when working exclusively with GraphQL or pure front-end logic.

## Core Pattern
1. **Use the helper script.**
   ```bash
   ./swagger-schema-check/fetch-swagger.sh
   ```
   - Tries `http://localhost:5000/swagger` first.
   - Falls back to `BASE_URL` from `src/environments/environment.ts` (if present) + `/swagger`.
   - Saves to `docs/swagger/openapi.json` (relative to current working directory), overwriting if it exists.
2. **Inspect the endpoint you’re touching.**
   ```bash
   jq '.paths["/api/ordens-servico"]' docs/swagger/openapi.json
   ```
   Confirm verbs, query params, request bodies, and response schemas.
3. **Cross-check DTOs/mocks/tests.**
   - Update request/response interfaces, mock generators, and specs to match the schema.
   - Optional: run `npx @redocly/openapi-cli lint docs/swagger/openapi.json` for sanity.
4. **Repeat whenever backend changes.** Don’t reuse stale snapshots.

## Quick Reference
- Fetch: `./swagger-schema-check/fetch-swagger.sh`
- Local first: `http://localhost:5000/swagger`
- Fallback: `BASE_URL` from `src/environments/environment.ts` + `/swagger`
- Output: `docs/swagger/openapi.json` (overwrites)
- Inspect: `jq '.paths["/api/..."]' docs/swagger/openapi.json`
- Lint: `npx @redocly/openapi-cli lint docs/swagger/openapi.json`

## Example Session
```bash
cd /home/mendes/projetos/eugestor/frontend
./swagger-schema-check/fetch-swagger.sh
jq '.paths["/api/ordens-servico"]' docs/swagger/openapi.json
npx @redocly/openapi-cli lint docs/swagger/openapi.json
```

## Rationalization Table
| Excuse | Reality |
|--------|---------|
| “Local swagger hasn’t changed.” | If backend isn’t running, you’ll read stale docs. Ping once—it’s seconds. |
| “I know the payload shape.” | Backend evolves often; swagger is the single source of truth. |
| “Downloading JSON is busywork.” | Debugging mismatched DTOs takes longer than `curl` + `jq`. |
| “Only request body changed.” | Responses/query params may change too. Inspect the entire operation. |

## Red Flags
- PR adds HttpClient code without referencing updated swagger paths.
- DTO changes shipped without evidence of schema refresh.
- Tests still expect fields removed from `/swagger/v1/swagger.json`.

## Common Mistakes
- **Using old JSON snapshots.** Always re-fetch; delete `tmp/swagger/openapi.json` after review.
- **Forgetting auth headers** if remote swagger requires them—pass via `curl -H`.
- **Assuming different swagger versions.** Our docs live at `/swagger/v1/swagger.json`; verify before guessing.

## Verification
- Confirm `tmp/swagger/openapi.json` timestamp matches your change session.
- Reference the inspected path/operation in your PR or notes.
- Ensure DTOs/mocks align with the schema before committing.
