---
name: stylecopplus-max-method-length
description: Use when repository config sets styleCopPlusRules.maxMethodLength - enforces maximum number of lines per method and suggests refactorings when exceeded.
---

# StyleCopPlus — Max Method Length

## Overview

Skill que aplica `styleCopPlusRules.maxMethodLength` (ex.: 50). Detecta métodos com corpo maior que o limite e sugere decomposição, extração de responsabilidades e testes específicos.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to use

* Quando `settings.styleCopPlusRules.maxMethodLength` estiver definido
* Revisões com métodos longos e complexos

## Rule

* Contar linhas do corpo do método (entre `{` e `}`)
* Se > limite → sinalizar e recomendar extrair submétodos, simplificar branches, ou transformar em objeto de estratégia

## Implementation notes

* Excluir comentários de documentação XML do topo da contagem
* Considerar expression-bodied como 1 linha
* Identificar pontos de extração sugerida (grandes blocos de if/foreach)

## Messages

* `Method length ({lines} > {max}) — consider extracting smaller methods and adding unit tests.`

## Minimal tests

* Método com 51 linhas -> flag
* Método expression-bodied longo -> flag if expression too complex? Prefer manual review
* Método que delega para vários pequenos métodos -> ok
