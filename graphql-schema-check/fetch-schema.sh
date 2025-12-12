#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Using graphql-schema-check skill."

explicit_base="${1:-}"

if [[ -n "${explicit_base}" ]]; then
  explicit_base="${explicit_base%/}"
  ENDPOINT="${explicit_base%/}/graphql"
  echo "Using explicit GraphQL endpoint: ${ENDPOINT}"
else
  echo "Probing local GraphQL at http://localhost:5000/graphql..."
  ENDPOINT=""
  if curl -fsS "http://localhost:5000/graphql" >/dev/null 2>&1; then
    ENDPOINT="http://localhost:5000/graphql"
    echo "Local GraphQL detected at ${ENDPOINT}"
  else
    echo "Local GraphQL not available. Trying BASE_URL from src/environments/environment.ts..."
    if [[ -f "src/environments/environment.ts" ]]; then
      BASE_URL="$(rg "const BASE_URL" -n src/environments/environment.ts | sed -E "s/.*'(.+)'/\\1/" | head -n1 || true)"
    else
      BASE_URL=""
    fi
    if [[ -n "${BASE_URL}" ]]; then
      ENDPOINT="${BASE_URL%/}/graphql"
      echo "Using fallback GraphQL endpoint ${ENDPOINT}"
    else
      echo "Could not determine GraphQL endpoint (no local and no BASE_URL in src/environments/environment.ts). Provide a base URL as an argument if needed." >&2
      exit 1
    fi
  fi
fi

docs_dir="${PWD%/}/docs/graphql"
mkdir -p "${docs_dir}"
target="${docs_dir}/schema.graphql"

echo "Fetching schema from ${ENDPOINT} ..."

python3 - "$ENDPOINT" "$target" <<'PY'
import sys, json, urllib.request

endpoint = sys.argv[1]
target = sys.argv[2]

introspection_query = """
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}
fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}
fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}
fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
        }
      }
    }
  }
}
"""

payload = json.dumps({"query": introspection_query}).encode("utf-8")
req = urllib.request.Request(
    endpoint,
    data=payload,
    headers={"Content-Type": "application/json"},
    method="POST",
)

with urllib.request.urlopen(req) as resp:
    if resp.status != 200:
        raise SystemExit(f"GraphQL endpoint returned HTTP {resp.status}")
    data = json.loads(resp.read())

if "errors" in data:
    raise SystemExit(f"GraphQL errors: {data['errors']}")

with open(target, "w", encoding="utf-8") as f:
    f.write(json.dumps(data, indent=2))

print(f"Schema saved to {target}")
PY

echo "Done."
