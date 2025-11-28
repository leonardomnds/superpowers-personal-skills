---
name: stylecopplus-max-line-length
description: Use when repository config sets styleCopPlusRules.maxLineLength - enforces maximum line length (120) and provides wrapping guidance and tests.
---

# StyleCopPlus — Max Line Length

## Overview

Skill que aplica a política `styleCopPlusRules.maxLineLength` (ex.: 120). Detecta linhas > limite e sugere/realiza quebras consistentes preservando semântica e indentação.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to use

* Quando `settings.styleCopPlusRules.maxLineLength` estiver definido (ex: 120)
* PRs com linhas longas (> limite)

## Rule

* Limite configurável (ex.: 120)
* Linhas com comprimento > limite devem ser quebradas em pontos lógicos (`,` `(` operadores)
* Não quebrar dentro de literais string sem avaliar impacto

## Implementation notes

* Detectar linhas > limite usando contagem de caracteres (UTF-8 length)
* Preferir quebra após vírgula ou antes de operador
* Preservar indentação do nível atual
* Test cases: chamadas, expressões booleanas, interpolated strings, comentários finais

## Messages

* `Line exceeds max length (now {length}, max {max})` — com sugestão de wrap

## Minimal tests

* Linha com 121 chars -> wrap
* Linha com string longa -> alert only (manual)
* Already-wrapped -> no change
