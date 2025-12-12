#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load local .env if present (do not commit secrets)
if [[ -f "${script_dir}/.env" ]]; then
  set -o allexport
  # shellcheck disable=SC1090
  source "${script_dir}/.env"
  set +o allexport
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: ${0##*/} \"https://your.gitlab.host/group/project/-/issues/<iid>\" [output-file]" >&2
  exit 1
fi

issue_url="$1"
output_file="${2:-}"

if [[ -z "${GITLAB_HOST:-}" ]]; then
  echo "GITLAB_HOST is required (set it in ${script_dir}/.env). Example: gitlab.example.com" >&2
  exit 1
fi

if [[ "${GITLAB_HOST}" == *"://"* ]]; then
  echo "GITLAB_HOST should not include scheme. Use 'gitlab.example.com' (no https://)." >&2
  exit 1
fi

if [[ "${GITLAB_HOST}" == *"/"* ]]; then
  echo "GITLAB_HOST must be host (and optional port) only, no path. Use 'gitlab.example.com'." >&2
  exit 1
fi

if [[ -z "${GITLAB_TOKEN:-}" ]]; then
  echo "GITLAB_TOKEN is required (set it in ${script_dir}/.env)" >&2
  exit 1
fi

parse_output="$(python3 - "$issue_url" "$GITLAB_HOST" <<'PY'
import sys
from urllib.parse import urlparse, quote

issue_url = sys.argv[1]
expected_host = sys.argv[2]

parsed = urlparse(issue_url)
if not parsed.scheme or not parsed.netloc:
    sys.exit("Invalid issue URL (missing scheme or host)")

# Compare host exactly (including port if present)
if parsed.netloc != expected_host:
    sys.exit(f"Host mismatch: URL host '{parsed.netloc}' != GITLAB_HOST '{expected_host}'")

parts = parsed.path.strip("/").split("/")
try:
    dash_index = parts.index("-")
except ValueError:
    sys.exit("Issue URL missing '/-/' segment")

if dash_index + 2 >= len(parts) or parts[dash_index + 1] != "issues":
    sys.exit("Issue URL must contain '/-/issues/<iid>'")

project_path = "/".join(parts[:dash_index])
if not project_path:
    sys.exit("Project path not found in URL")

iid = parts[dash_index + 2]
if not iid.isdigit():
    sys.exit("Issue IID must be numeric")

scheme = parsed.scheme
encoded_project = quote(project_path, safe="")

# Emit space-separated fields to allow a single read
print(" ".join([scheme, parsed.netloc, project_path, encoded_project, iid]))
PY
)"

read -r scheme host project_path encoded_project iid <<<"${parse_output}"

api_url="${scheme}://${host}/api/v4/projects/${encoded_project}/issues/${iid}"

response="$(curl --silent --show-error --fail -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${api_url}")"
notes_response="$(curl --silent --show-error --fail -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${api_url}/notes?sort=asc&per_page=100")"

markdown="$(python3 - <<'PY' "${response}" "${notes_response}" "${issue_url}"
import sys, json
from datetime import datetime

issue = json.loads(sys.argv[1])
notes = json.loads(sys.argv[2])
issue_url = sys.argv[3]

title = issue.get("title", "").strip()
description = (issue.get("description") or "").rstrip()

lines = []
lines.append(issue_url)
lines.append("")
lines.append(f"# {title}")
lines.append("")
lines.append(description if description else "_No description provided_")

filtered_notes = []
for note in notes:
    # Skip system events and empty bodies
    if note.get("system"):
        continue
    body = (note.get("body") or "").rstrip()
    if not body:
        continue
    filtered_notes.append((note, body))

if filtered_notes:
    lines.append("")
    lines.append("## Comentarios")
    lines.append("")
    lines.append("<table>")
    lines.append("<thead><tr><th>data</th><th>conteudo</th></tr></thead>")
    lines.append("<tbody>")
    for note, body in filtered_notes:
        created_at = note.get("created_at", "")
        try:
            dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            date_str = dt.strftime("%Y-%m-%d")
        except Exception:
            date_str = created_at
        def esc(txt: str) -> str:
            return (
                txt.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
            )
        safe_body = esc(body).replace("\n", "<br/>")
        lines.append(f"<tr><td>{esc(date_str)}</td><td>{safe_body}</td></tr>")
    lines.append("</tbody>")
    lines.append("</table>")

print("\n".join(lines).rstrip() or "_No content_")
PY
)"

ensure_unique_path() {
  local target="$1"
  local dir base ext candidate i
  dir="$(dirname "$target")"
  base="$(basename "$target")"
  ext=""
  # Split extension (handles names without dot)
  if [[ "$base" == *.* ]]; then
    ext=".${base##*.}"
    base="${base%.*}"
  fi
  candidate="${dir}/${base}${ext}"
  i=1
  while [[ -e "$candidate" ]]; do
    candidate="${dir}/${base}_${i}${ext}"
    ((i++))
  done
  printf "%s" "$candidate"
}

if [[ -z "${output_file}" ]]; then
  repo_root="${PWD}"
  docs_dir="${repo_root%/}/docs/issues"
  mkdir -p "${docs_dir}"
  project_name="${project_path##*/}"
  output_file="${docs_dir}/${project_name}-${iid}.md"
fi
output_file="$(ensure_unique_path "${output_file}")"

printf "%s\n" "${markdown}" > "${output_file}"
echo "Markdown written to ${output_file}"
