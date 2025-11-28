---
name: trailing-commas
description: Use when C# multi-line initializers, arrays, or parameter lists are missing trailing commas - enforces consistent comma usage to simplify diffs, reduce merge conflicts, and ease item insertion.
---

# Trailing Commas

## Overview

Skill para garantir que inicializadores, arrays e listas de parâmetros multilinha usem vírgula final. Isso simplifica manutenção, reduz conflitos e deixa diffs mais limpos.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## When to Use

**Gatilhos / sintomas**

* Inicializadores em múltiplas linhas sem vírgula no último item
* Diffs ruidosos porque adicionar novo item modifica linha existente
* Merge conflicts recorrentes em coleções Inicializadas manualmente
* Código inconsistente entre arquivos

**Quando NÃO usar**

* Inicializadores de uma linha (não se aplica)
* Código gerado automaticamente

## Core Pattern

**Princípio:** sempre colocar vírgula após o último item quando o bloco possui múltiplas linhas.

*before:*

```csharp
var items = new[]
{
    1,
    2,
    3
};
```

*after:*

```csharp
var items = new[]
{
    1,
    2,
    3,
};
```

## Quick Reference

* Escopo: inicializadores `{ ... }` e arrays `new[] { ... }` em múltiplas linhas
* Regra: última linha de item deve terminar com `,`
* Benefícios: diffs menores, menos conflitos, consistência

## Implementation (mínimo necessário)

1. Detectar inicializadores ou arrays com `{` e `}` em linhas separadas.
2. Identificar linhas internas contendo itens.
3. Verificar se a última linha de item termina com vírgula.
4. Se não terminar, inserir vírgula.
5. Preservar indentação existente.

**Casos que devem ser testados:**

* Inicializadores de objetos com propriedades
* Arrays
* Dicionários com pares `{ key, value }`
* Blocos com comentários após os valores
* Linhas cujo item já termina com vírgula

## Common Mistakes

* Aplicar trailing comma em blocos de uma única linha
* Inserir vírgula após comentários isolados
* Quebrar formatação original do bloco

## Real-World Impact

* Diffs limpos: apenas nova linha adicionada, nenhuma linha antiga alterada
* Menos conflitos ao adicionar itens em PRs paralelos
* Padrão consistente em toda a base

## Minimal Test Cases (suggested)

* Inicializador com 3 itens, sem vírgula final
* Dicionário com comentários após o item
* Bloco com vírgula já presente (não alterar)
* Bloco de uma linha (não aplicar)
* Arrays aninhados
