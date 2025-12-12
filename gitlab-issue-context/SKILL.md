---
name: gitlab-issue-context
description: Use when you need GitLab issue context from a URL on a self-hosted instance - loads host/token from a local .env, validates the URL matches that host, hits the issues API, and emits Markdown with title and description
---

# GitLab Issue Context

## Overview
Fetch a GitLab issue’s title, description, and comments using the issue URL from a self-hosted GitLab. Host and token come from a `.env` beside the skill. The helper script validates the URL host matches your configured GitLab, URL-encodes the project path (including subgroups), and outputs Markdown with the issue URL on the first line and comments in an HTML table.

## When to Use
- You have a full issue URL (e.g., `https://gitlab.example.com/group/subgroup/project/-/issues/123`)
- You need Markdown with issue URL on the first line, title + description, and comments in an HTML table for context
- Instance is self-hosted; host and token should not be hardcoded in the script

Avoid when:
- You need comments, labels, or other fields (extend the script first)
- You don’t have an access token with API scope

## Setup
- Copy `gitlab-issue-context/.env.example` to `.env` in the same folder (never commit secrets).
- Fill `GITLAB_HOST` (host or host:port, no scheme) and `GITLAB_TOKEN` (PAT with API scope).
- Make the script executable: `chmod +x gitlab-issue-context/fetch-issue.sh`.

## Usage
Always narrate steps to your human partner:
- Announce you are using the `gitlab-issue-context` skill.
- Say you will fetch the issue from the provided URL.
- After fetch, say you succeeded (or failed) and where the Markdown will be saved.
- When saving, state the target path (including any `_1`, `_2` suffix).
- If `.env` is missing/invalid or the URL is invalid, announce the error and stop.
- After the Markdown is created, run `superpowers:brainstorming` to plan the implementation using the fetched context, and create the planning document in `docs/plans/` (e.g., `docs/plans/YYYY-MM-DD-<topic>-design.md`).

Default (writes to `docs/issues/<project>-<iid>.md` **relative to your current working directory**, creating `docs/issues/` if missing):
```
./gitlab-issue-context/fetch-issue.sh "https://gitlab.example.com/group/subgroup/project/-/issues/123"
```
If a file already exists with that name, `_1`, `_2`, … are appended automatically.

Custom output path (optional second arg):
```
./gitlab-issue-context/fetch-issue.sh "https://gitlab.example.com/group/subgroup/project/-/issues/123" /custom/path/issue.md
```
Custom paths also dedupe with `_1`, `_2`, … if the file exists.

Both variants output Markdown with:
- First line: the issue URL
- Then: title, description
- Then (if any): a `## Comentarios` section with an HTML table: columns `data` (yyyy-MM-dd) and `conteudo`

## Quick Reference
- `.env`: `GITLAB_HOST`, `GITLAB_TOKEN`
- Input: full issue URL (`/-/issues/<iid>`)
- Output: Markdown with issue URL on the first line, title + description, and comments in an HTML table (date yyyy-MM-dd, content)
- Validations: host must match `GITLAB_HOST`; project path URL-encoded; errors fail fast

## Common Mistakes
- Hardcoding `gitlab.com`: always set `GITLAB_HOST` to your self-hosted host.
- Forgetting `.env`: script will fail if `GITLAB_HOST` or `GITLAB_TOKEN` is missing.
- Adding scheme/path to `GITLAB_HOST`: must be host (and optional port) only, e.g., `gitlab.example.com`.
- Using project ID instead of path: the script expects a full issue URL with `/-/issues/<iid>`.
- Committing secrets: keep `.env` untracked; only `.env.example` lives in git.
- Expecting system events: the output includes only user comments (non-system, non-empty bodies); assignment/edit events are filtered out.

## Rationalizations Countered
| Excuse | Counter |
| --- | --- |
| "Faster to hardcode host/token" | `.env` keeps secrets out of git; script refuses host mismatches. |
| "This URL probably works on gitlab.com too" | Host check blocks accidental calls to the wrong GitLab. |
| "Subgroups rarely happen" | URL-encoding of the full path prevents 404s from subgroup paths. |
| "Empty output is fine" | Script fails fast with clear errors instead of silently returning nothing. |

## Red Flags - Stop
- You are tempted to paste the token into the script or command line.
- The issue URL host differs from `GITLAB_HOST` but you plan to run it anyway.
- You plan to skip creating `.env` and rely on defaults or gitlab.com.

## Rationale (guards against baseline failures)
- Forces host/token from `.env`, avoiding hardcoded hosts/tokens in the script.
- Validates issue URL host matches `GITLAB_HOST` to prevent accidental `gitlab.com` calls.
- Properly URL-encodes project paths with subgroups so requests don’t 404.
- Fails fast with clear errors instead of silent empty outputs.
