---
name: stylecop-readability-rules
description: Always use this when StyleCop readability rules are enabled — enforces readability settings such as built-in type aliases and clarity preferences.
---

# StyleCop Readability Rules

## Overview

Aplica regras de legibilidade definidas pelo StyleCop, incluindo uso (ou não) de aliases de tipos embutidos como `int`, `string`, `bool`.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use

* Projeto possui `readabilityRules` no stylecop.json
* PRs exibem inconsistências entre `int` vs `System.Int32`

## Core Pattern

* Se `allowBuiltInTypeAliases = true` → preferir `int`, `string`, `bool`
* Se `allowBuiltInTypeAliases = false` → usar nomes CLR completos como `System.Int32`

## Quick Reference

* built-in aliases: `int`, `string`, `bool`, `decimal`, `double`, `float`
* CLR names: `System.Int32`, `System.String`, etc.

## Implementation

* Detectar tipos usados em declarações de variáveis, parâmetros e retornos
* Sugerir substituição conforme configuração
* Para fix seguro, usar análise semântica (Roslyn)

## Common Mistakes

* Misturar aliases e CLR names no mesmo arquivo
* Alterar nomes de tipos dentro de literais XML docs sem verificar links

## Tests

* `System.Int32 x;` → `int x;` se aliases permitidos
* `int x;` → `System.Int32 x;` se aliases desabilitados
