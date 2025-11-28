---
name: stylecop-layout-rules
description: Use when StyleCop layout rules are enabled — enforces newline-at-EOF policy, using-group layout, and do/while brace placement.
---

# StyleCop Layout Rules

## Overview
Aplica regras de layout baseadas no StyleCop e na política específica do projeto.
A regra principal local aqui é:

**Não permitir quebra de linha no final do arquivo, a menos que o arquivo já possuísse uma.**

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use
- Quando o repositório ativa `layoutRules` no stylecop.json.
- Quando PRs alteram estrutura de arquivos, usando, layout ou EOF.
- Ao revisar arquivos que mudaram quantidade de linhas no final.

## Core Pattern

### 1. newlineAtEndOfFile (StyleCop)
Valores permitidos pelo StyleCop:
- allow
- require
- omit

### 2. Política do projeto (sobrescreve StyleCop)
Regra obrigatória:
- Arquivos novos → nunca devem terminar com newline.
- Arquivos existentes:
    - Se não tinham newline, continue sem newline.
    - Se tinham, continue com newline.
- Ou seja: preservar o estado original, e nunca introduzir newline final em arquivos que não tinham.

### 3. Outras regras de layout
- allowConsecutiveUsings: permite ou não múltiplos blocos de using.
- allowDoWhileOnClosingBrace: define se '} while(condition);' é permitido na mesma linha.

## Quick Reference

EOF rules:
- Projeto exige: não adicionar newline final.
- Preservar o estado original do arquivo.
- Nunca alterar newline final a menos que já existisse.

Using groups:
- Consolidar ou manter blocos conforme allowConsecutiveUsings.

Do/while:
- Verificar se while pode ou não ficar após a chave conforme configuração.

## Implementation

### EOF
- Detectar se o arquivo original tinha newline no final.
- Se o arquivo modificado incluí-la indevidamente → remover.
- Se o arquivo original tinha newline e o modificado removeu → restaurar.
- Para novos arquivos: sem newline no fim.

### Usings
- Detectar grupos consecutivos e consolidar se exigido.

### Do/while
- Validar posição do while.

## Common Mistakes
- Adicionar '\n' ao salvar arquivos que originalmente não tinham.
- Remover newline final de arquivos que já a possuíam.
- Automatizar formatação sem respeitar a política local.
- Misturar múltiplos blocos de using quando proibido.

## Tests

### Test A — Arquivo novo
Before:
<novo arquivo>

After:
<não deve terminar com newline>

### Test B — Arquivo existente sem newline final
Before:
class A {}
<EOF>

After (não adicionar):
class A {}
<EOF>

### Test C — Arquivo existente com newline final
Before:
class A {}
\n

After (preservar):
class A {}
\n

### Test D — Usings consecutivos
Before:
using System;
using System.Linq;

using MyApp.Core;

After:
using System;
using System.Linq;
using MyApp.Core;
