---
name: enum-style
description: Always use this standard for creating or modifying enums in .cs files.
---

# Enum Style

## Overview

Padrão para criação e evolução de enums: cada membro deve ter valor explícito iniciando em 0; membros existentes nunca são renumerados ou removidos para evitar breaking changes.

## When to Use

* Criando um novo enum em qualquer linguagem.
* Adicionando novos membros a enums existentes.
* Revisando PRs que mexem em enums.

## Core Pattern

* Sempre atribua valores explícitos a todos os membros.
* O primeiro membro deve iniciar em 0; incremente em +1 para novos itens.
* Nunca altere valores numéricos já publicados; adicione novos membros ao final da sequência.
* Evite reordenar membros existentes; preserve a ordem original.

## Quick Reference

* Bom (novo enum): `Status { Unknown = 0, Active = 1, Inactive = 2 }`
* Bom (adicionando): `Status { Unknown = 0, Active = 1, Inactive = 2, Pending = 3 }`
* Ruim: `Status { Unknown, Active, Inactive }` (valores implícitos)
* Ruim: renumerar `Active` de 1 para 2 para inserir um novo item no meio.

## Implementation

* Verifique se todos os membros têm atribuição explícita (`=`).
* Confirme que o primeiro valor é 0 e que a sequência é incremental sem buracos introduzidos por renumeração.
* Ao adicionar membros, insira no final com o próximo número disponível; não toque nos anteriores.
* Em revisões, recuse alterações que movam, renumerem ou removam membros existentes.

## Common Mistakes

* Esquecer de atribuir valores explícitos, deixando o compilador numerar.
* Renumerar membros existentes ao inserir um novo no meio.
* Começar enum em 1 (quebrando expectativa de valor inicial 0).
* Remover membro e reutilizar o valor numérico para outro significado.

## Tests

* Novo enum sem valores explícitos deve falhar e exigir `= 0, = 1...`.
* Adicionar `Pending = 3` ao final de `Status { Unknown = 0, Active = 1, Inactive = 2 }` deve passar.
* Tentar mudar `Active = 1` para `Active = 2` (para inserir algo no meio) deve ser bloqueado.
* Remover `Inactive = 2` e reutilizar `= 2` para outro membro deve ser bloqueado.
