#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Using swagger-schema-check skill."
echo "Probing local swagger at http://localhost:5000/swagger..."

SWAGGER_BASE=""
if curl -fsS "http://localhost:5000/swagger/index.html" >/dev/null 2>&1; then
  SWAGGER_BASE="http://localhost:5000/swagger"
  echo "Local swagger detected at ${SWAGGER_BASE}"
else
  echo "Local swagger not available. Trying BASE_URL from src/environments/environment.ts..."
  if [[ -f "src/environments/environment.ts" ]]; then
    BASE_URL="$(rg "const BASE_URL" -n src/environments/environment.ts | sed -E "s/.*'(.+)'/\\1/" | head -n1 || true)"
  else
    BASE_URL=""
  fi
  if [[ -n "${BASE_URL}" ]]; then
    SWAGGER_BASE="${BASE_URL%/}/swagger"
    echo "Using fallback swagger base ${SWAGGER_BASE}"
  else
    echo "Could not determine SWAGGER_BASE (no local swagger and no BASE_URL in src/environments/environment.ts)" >&2
    exit 1
  fi
fi

swagger_url="${SWAGGER_BASE}/v1/swagger.json"

docs_dir="${PWD%/}/docs/swagger"
mkdir -p "${docs_dir}"
target="${docs_dir}/openapi.json"

echo "Fetching ${swagger_url} ..."
curl -fsS "${swagger_url}" -o "${target}"
echo "Swagger saved to ${target}"
