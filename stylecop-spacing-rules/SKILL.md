---
name: stylecop-spacing-rules
description: Use when StyleCop spacing rules are enabled — enforces spacing around operators, commas, and parentheses according to project policy.
---

# StyleCop Spacing Rules

## Overview

Aplica regras de espaçamento (série SA1000+) conforme definido no StyleCop. Garante consistência em operadores, vírgulas, parênteses e separadores.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use

* Projeto define `spacingRules` no stylecop.json
* PRs mostram espaçamento inconsistente em operadores ou parâmetros

## Core Pattern

* Espaço antes/depois de operadores binários
* Espaço após vírgulas
* Nenhum espaço dentro de parênteses
* Espaçamento consistente em parâmetros e chamadas

## Quick Reference

* `a+b` → `a + b`
* `foo( a,b )` → `foo(a, b)`
* `bar (x)` → `bar(x)`

## Implementation

* Detectar padrões comuns via regex ou AST
* Aplicar correções automáticas apenas quando seguro
* Preferível usar Roslyn para fix preciso

## Common Mistakes

* Espaço antes de vírgula
* Falta de espaço após vírgula
* Espaço dentro de parênteses

## Tests

* `a+ b` → corrigir para `a + b`
* `method( 1 ,2 )` → `method(1, 2)`
