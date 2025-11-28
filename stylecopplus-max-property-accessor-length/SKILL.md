---
name: stylecopplus-max-property-accessor-length
description: Use when repository config sets styleCopPlusRules.maxPropertyAccessorLength - limits length of property accessors (get/set bodies) to keep properties concise.
---

# StyleCopPlus — Max Property Accessor Length

## Overview

Skill que aplica `styleCopPlusRules.maxPropertyAccessorLength` (ex.: 40). Garante que os blocos `get`/`set` permaneçam curtos; quando maiores, sugere extrair lógica para métodos auxiliares.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to use

* Quando `settings.styleCopPlusRules.maxPropertyAccessorLength` definido
* Revisões de PRs com accessors longos

## Rule

* Conte número de linhas no corpo do accessor (entre `{` e `}`)
* Se > limite → sinalizar e sugerir extrair para método `private` ou `Validate...`/`Compute...`

## Implementation notes

* Ignorar linhas em branco/atributos acima do accessor
* Caso accessors sejam expression-bodied (`=>`), contar como 1 linha
* Test cases: accessor com 41 linhas -> flag; expression-bodied -> ok if short

## Messages

* `Property accessor exceeds max length ({lines} > {max}) — consider extracting logic to method.`

## Minimal tests

* Auto-property (no body) -> ok
* Expression-bodied -> ok
* Block-bodied with 41 lines -> flag
