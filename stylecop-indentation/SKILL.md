---
name: stylecop-indentation
description: Use when repository defines indentation settings in StyleCop schema - enforces indentationSize, tabSize and useTabs across C# source files.
---

# Indentation

## Overview

Enforce consistent indentation according to project StyleCop settings (`indentationSize`, `tabSize`, `useTabs`).

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use

* StyleCop `settings.indentation` exists
* PRs mostram tabs e spaces misturados
* Linhas com níveis de indentação inconsistentes

## Core Pattern

* Usar exatamente `indentationSize` espaços OU tabs se `useTabs = true`
* Normalizar indentação em todos os arquivos .cs

## Quick Reference

* `indentationSize`: número de espaços por nível
* `tabSize`: tamanho lógico do tab
* `useTabs`: true/false para tabs vs spaces

## Implementation

* Detectar whitespace no início de cada linha
* Verificar se corresponde ao padrão configurado
* Para fix: converter toda indentação para o modo correto usando o valor configurado

## Common Mistakes

* Misturar tabs e espaços
* Níveis de indentação com quantidades incorretas

## Tests

* Arquivo com tabs quando `useTabs=false` → normalizar
* Arquivo com espaços errados (não múltiplos de indentationSize)
