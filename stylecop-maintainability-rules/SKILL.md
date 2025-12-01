---
name: stylecop-maintainability-rules
description: Always use this when StyleCop maintainability rules are enabled — enforces allowed top-level type kinds according to project configuration.
---

# StyleCop Maintainability Rules

## Overview

**Uso obrigatório ao criar/editar arquivos:** antes de iniciar qualquer alteração, execute `~/.codex/superpowers/.codex/superpowers-codex use-skill stylecop-maintainability-rules` e mantenha esta skill carregada enquanto edita.

Aplica as regras de manutenibilidade definidas em `maintainabilityRules`, especialmente o conjunto permitido de tipos top-level (class, struct, interface, enum, delegate).

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use

* Projeto possui `maintainabilityRules.topLevelTypes`
* PRs criam tipos top-level potencialmente não permitidos

## Core Pattern

* Somente tipos permitidos podem existir no nível superior do arquivo
* Múltiplos tipos permitidos no mesmo arquivo dependem da política do time

## Quick Reference

Tipos permitidos conforme config:

* `class`
* `interface`
* `struct`
* `enum`
* `delegate`

## Implementation

* Analisar a declaração top-level
* Verificar se o tipo pertence ao conjunto definido
* Sinalizar violações e sugerir mover tipo para arquivo apropriado

## Common Mistakes

* Incluir tipos auxiliares complexos ao lado de classes principais
* Criar delegates em arquivos de classe quando delegates não são permitidos

## Tests

* Arquivo contendo `delegate` quando não permitido → flag
* Arquivo contendo `enum` permitido → ok
