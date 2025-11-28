---
name: stylecopplus-max-file-length
description: Use when repository config sets styleCopPlusRules.maxFileLength - enforces maximum file length (number of lines) and provides splitting/refactor guidance.
---

# StyleCopPlus — Max File Length

## Overview

Skill que aplica `styleCopPlusRules.maxFileLength` (ex.: 400). Detecta arquivos com número de linhas acima do limite e sugere refatorações: extrair classes, dividir arquivos, mover utilitários.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to use

* Quando `settings.styleCopPlusRules.maxFileLength` estiver definido
* PRs adicionando muitos métodos ou longos arquivos

## Rule

* Arquivos com mais linhas que o limite devem ser sinalizados
* Sugerir estratégias: extrair classes, separar responsibilities, mover helper methods

## Implementation notes

* Contar linhas efetivas (ignorar linhas em branco contínuas no topo/rodapé opcionalmente)
* Fornecer hotspots (métodos/props maiores) que mais contribuem para excesso
* Test cases: arquivo com 401 linhas -> flag; arquivo com 350 lines -> ok

## Messages

* `File exceeds max length ({lines} > {max}) — consider splitting or extracting types`

## Minimal tests

* Arquivo exatamente no limite
* Arquivo 1 linha acima do limite
* Arquivo com muitos comentários (decidir se contam)
