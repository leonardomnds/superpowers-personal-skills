---
name: unused-using-directives
description: Use when C# files contain unused using directives that generate noise, warnings, or unnecessary imports - documents how to detect, report and safely remove unused using blocks.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Unused Using Directives

## Overview

Skill para detectar e remover diretivas `using` que não são usadas em arquivos C#. Reduz ruído, evita warnings e mantém o topo dos arquivos limpo.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## When to Use

**Gatilhos / sintomas**

* Warnings de compilador indicando `The using directive is unnecessary`
* PRs com commits contendo remoção manual de vários `using`
* Arquivos acumulando imports após refactors
* Ferramentas de análise estática reclamando de imports não utilizados

**Quando NÃO usar**

* Arquivos com `global using` que podem ser usados implicitamente
* Arquivos gerados automaticamente (não edite)

## Core Pattern

**Princípio:** localizar diretivas `using` reconhecidas como não utilizadas e removê‑las sem alterar comportamento do arquivo.

Antes:

```csharp
using System.Linq;
using MyApp.Internal.Tools;
using System.Collections.Generic;

class A {}
```

Depois (se nenhum for usado):

```csharp
class A {}
```

## Quick Reference

* Padrão: `^using\s+[^;]+;$`
* Escopo: apenas diretivas `using` no topo do arquivo
* Fix: remoção simples (`type: remove`, `scope: using`)
* Linguagem: `csharp`
* Identificação: depende do analisador de uso para confirmar `unused`

## Implementation (mínimo necessário)

1. Escanear as diretivas `using` no topo do arquivo.
2. Para cada diretiva, verificar se o namespace aparece em qualquer símbolo usado no restante do arquivo.
3. Se não houver referências → marcar como `unused`.
4. Remover a linha correspondente mantendo espaçamento consistente.
5. Evitar remover `global using` automaticamente (visibilidade ampla).

**Nota:** Testes devem incluir casos com:

* `using static`
* `using alias = Namespace.Type;`
* Arquivos com apenas 1 `using` não usado
* Arquivos onde um refactor removeu o último uso real

## Common Mistakes

* Remover diretivas ainda usadas por herança implícita
* Remover `using` que ativa extension methods
* Deixar múltiplas linhas em branco após a remoção

## Real-World Impact

* Reduz ruído visual no topo dos arquivos
* Diminui conflitos de merge
* Deixa diffs menores e mais legíveis

## Minimal Test Cases (suggested)

* Arquivo com 1 `using` não usado
* Arquivo com vários `using`, apenas 1 usado
* Arquivo com `using static` usado indiretamente
* Arquivo com alias de namespace
* Arquivo sem nenhum `using` (não deve falhar)
