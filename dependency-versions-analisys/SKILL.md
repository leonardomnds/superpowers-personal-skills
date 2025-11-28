---
name: dependency-versions-analysis
description: Use when auditing or modifying project dependencies (frontend or backend) — analyzes declared and resolved versions, flags risky upgrades, and consults the project's MCP (Context7) documentation as the authoritative source for compatibility and recommended versions.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Dependency Versions Analysis (libs)

## Overview

Skill para auditar e analisar versões de bibliotecas usadas em um repositório (frontend ou backend). O agente deve identificar versões declaradas e resolvidas, detectar problemas (versões obsoletas, vulnerabilidades conhecidas, quebras de compatibilidade sem migração) e **consultar sempre a documentação oficial via MCP do Context7** como fonte primária de recomendação e compatibilidade.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill. You MUST have access to the project MCP for Context7 (local cache, repository-hosted MCP files, or MCP endpoint) when running analyses.

## When to Use

**Gatilhos / sintomas**

* Revisão de PR que atualiza dependências
* Auditoria de segurança ou manutenção (dependabot, Snyk alerts)
* Planejamento de atualização major (upgrade da stack)
* Migrar entre versões LTS de frameworks
* Analisar divergências entre `package.json` / `yarn.lock` / `pnpm-lock.yaml` e arquivos de backend (`.csproj`, `packages.config`, `pom.xml`, `build.gradle`, `pyproject.toml`, `requirements.txt`)

**Quando NÃO usar**

* Repositórios que não possuem manifesto de dependências
* Análises ad-hoc sem acesso ao MCP do Context7 (o skill depende do MCP para diretrizes oficiais)

## Core Pattern

**Princípio:**

1. Localizar manifestos e lockfiles no repo (frontend e backend).
2. Extrair versões **declaradas** (package.json, .csproj PackageReference Include) e **resolvidas** (lockfiles, obj/project.assets.json, packages.lock.json).
3. Criar inventário de versões (nome, requested, resolved, transitive, file origins).
4. Para cada dependência relevante, consultar MCP (Context7) para: versão recomendada, compatibilidade, breaking-changes conhecidos, notas de migração e políticas de suporte (LTS, EOL).
5. Marcar riscos: versão com CVE conhecido (se disponível), major bump required, depreciação, mismatch entre declared/resolved.
6. Propor ações: pin, atualizar patch/minor, adiar major com plano de migração, abrir PR com changelog e testes necessários.

## Quick Reference

* Arquivos que o agente deve checar (não exaustivo):

  * Frontend: `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `package-lock.json`, `.npmrc`
  * .NET: `*.csproj` (PackageReference), `packages.config`, `global.json`, `Directory.Packages.props`, `obj/project.assets.json`
  * Java: `pom.xml`, `build.gradle`, `gradle.lockfile`
  * Python: `pyproject.toml`, `requirements.txt`, `Pipfile.lock`
  * Ruby: `Gemfile`, `Gemfile.lock`
  * Go: `go.mod`, `go.sum`
  * Rust: `Cargo.toml`, `Cargo.lock`
* Sempre preferir **lockfile/resolved** como verdade para o que está rodando.
* MCP do Context7 é a fonte autoritativa para: compatibilidade entre libs + versões suportadas pela plataforma.
* Para segurança (CVE) combine MCP com DBs de vulnerabilidade quando disponível.

## Implementation (mínimo necessário)

1. **Detectar manifestos e lockfiles** no repositório (recursivo).
2. **Extrair dependências**: nome, requested version range, resolved version, file path, dependency type (direct/transitive/dev).
3. **Indexar duplicatas**: mesma lib com versões diferentes em subprojetos.
4. **Consultar MCP Context7** para cada pacote relevante:

   * Como: usar o index MCP/context7 disponível no ambiente (local/endpoint) — procurar por `<package-name>` ou por guid/identifier da plataforma.
   * Recuperar: versão(s) recomendadas, suportadas, notas de breaking changes, e instruções de migração.
   * Se MCP não fornecer informação para um pacote específico, anotar e buscar substitutos/documentação oficial upstream.
5. **Classificar risco** para cada dependência com etiquetas: `ok`, `update-patch`, `update-minor`, `major-breaking`, `deprecated`, `vulnerable`, `mismatch` (declared vs resolved), `multi-version` (multiples em monorepo).
6. **Sugerir ações** automáticas/opcionais:

   * Propor PRs para atualizações de patch/minor com changelog e teste automático.
   * Para major-breaking, criar checklist de migração (tests to add, API changes to review).
   * Consolidar múltiplas versões em monorepos (align versions) — **não** fazer sem revisão humana.
7. **Gerar relatório** com tabelas: pacote, requested, resolved, recommended (MCP), status, suggested action, references (MCP path + upstream changelog links).

## Messages & Developer Prompts

* Missing MCP access: `MCP (Context7) not available — analysis limited to resolved versions and upstream docs.`
* Duplicate GUID/identifier in MCP: `MCP defines conflicting recommendations for <package> — escalate to platform owner.`
* Security high risk: `Dependency <name>@<version> has known CVE(s): <list>. Recommend immediate patch.`

## Testing (RED → GREEN)

* Repo with consistent versions and matching MCP recommendations → status `ok`.
* Repo with outdated patch versions → suggest `update-patch` and generate PR template.
* Repo with major version mismatch against MCP (platform requires X) → flag `major-breaking` and include migration notes from MCP.
* Monorepo with multiple versions of same lib across packages → flag `multi-version` and recommend alignment.
* Missing lockfile but manifests present → note `no-lockfile`, higher risk warning.

## Common Mistakes & Anti-Patterns

* Tomar `package.json` ranges como o que está rodando (usar lockfile/resolved como fonte da verdade).
* Atualizar major automaticamente sem plano de migração.
* Ignorar MCP do Context7 — esta é a fonte de verdade para compatibilidade com a plataforma.
* Fazer sweeping replacements across the repo without CI/tests.

## Output formats

* Human-readable Markdown report (table + action items)
* Machine JSON (for automation + dashboards)
* Optional: PR template prefilled with suggested version bumps, changelog links, tests to run

## Integration suggestions

* Integrar com CI para rodar essa análise em PRs que contenham mudanças em manifestos ou lockfiles.
* Criar bot que comenta no PR com resumo e links de referência MCP.
* Armazenar histórico de análises para rastrear quando upgrades foram aplicados.

## Real-World Impact

* Evita regressões por updates incompatíveis com a plataforma
* Reduz tempo gasto em investigação de incompatibilidades
* Melhora segurança e manutenção ao aplicar atualizações seguras e documentadas
