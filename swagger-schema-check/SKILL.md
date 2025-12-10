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
1. **Ping local swagger first.**
   ```bash
   LOCAL_SWAGGER=http://localhost:5000/swagger
   if curl -fsS "$LOCAL_SWAGGER/index.html" >/dev/null; then
     SWAGGER_BASE=$LOCAL_SWAGGER
   fi
   ```
2. **Fallback to environment BASE_URL when local fails.**
   ```bash
   if [ -z "$SWAGGER_BASE" ]; then
     BASE_URL=$(rg "const BASE_URL" -n src/environments/environment.ts | sed -E "s/.*'(.+)'/\\1/")
     SWAGGER_BASE="$BASE_URL/swagger"
   fi
   ```
3. **Download the document.**
   ```bash
   mkdir -p tmp/swagger
   curl -fsS "$SWAGGER_BASE/v1/swagger.json" -o tmp/swagger/openapi.json
   ```
4. **Inspect the endpoint you’re touching.**
   ```bash
   jq '.paths["/api/ordens-servico"]' tmp/swagger/openapi.json
   ```
   Confirm verbs, query params, request bodies, and response schemas.
5. **Cross-check DTOs/mocks/tests.**
   - Update request/response interfaces, mock generators, and specs to match the schema.
   - Optional: run `npx @redocly/openapi-cli lint tmp/swagger/openapi.json` for sanity.
6. **Repeat whenever backend changes.** Don’t reuse stale snapshots.

## Quick Reference
| Step | Command / Action |
|------|------------------|
| Probe local | `curl -fsS http://localhost:5000/swagger/index.html` |
| Fallback | Parse `BASE_URL` in `src/environments/environment.ts`, append `/swagger` |
| Download | `curl -fsS "$SWAGGER_BASE/v1/swagger.json" -o tmp/swagger/openapi.json` |
| Inspect path | `jq '.paths["/api/ordens-servico"]' tmp/swagger/openapi.json` |
| Lint | `npx @redocly/openapi-cli lint tmp/swagger/openapi.json` |

## Example Session
```bash
cd /home/mendes/projetos/eugestor/frontend
LOCAL_SWAGGER=http://localhost:5000/swagger
if curl -fsS "$LOCAL_SWAGGER/index.html" >/dev/null; then
  SWAGGER_BASE=$LOCAL_SWAGGER
else
  BASE_URL=$(rg "const BASE_URL" -n src/environments/environment.ts | sed -E "s/.*'(.+)'/\\1/")
  SWAGGER_BASE="$BASE_URL/swagger"
fi

curl -fsS "$SWAGGER_BASE/v1/swagger.json" -o tmp/swagger/openapi.json
jq '.paths["/api/ordens-servico"]' tmp/swagger/openapi.json
npx @redocly/openapi-cli lint tmp/swagger/openapi.json
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
