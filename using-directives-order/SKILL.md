---
name: using-directives-order
description: Use when C# files contain unordered `using` directives at the top of the file - enforces and documents how to detect, report and automatically sort contiguous using blocks (treating global using / using static separately).
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Using directives order

## Overview

Skill para detectar e corrigir diretivas `using` fora de ordem em arquivos C#. Fornece a regra mínima, exemplos e contra-argumentos para evitar racionalizações durante a aplicação automática.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## When to Use

**Sintomas / gatilhos**

* Arquivos `.cs` com `using` no topo que geram warnings no styleguide
* Revisões de PR com mudanças triviais apenas por ordem dos `using`
* Procura por uma regra automática que possa ser aplicada como fix

**Quando NÃO usar**

* Arquivos com `// keep-order` imediatamente acima do bloco de `using`
* Arquivos que usam convenções de ordem organizacional intencional (comentários seccionais)

## Core Pattern

**Princípio:** localizar blocos contíguos de `using` e ordenar alfabeticamente por namespace, preservando blocos separados para `global using` e para `using static`.

*before:*

```csharp
using Zebra.Utilities;
using System.Linq;
using Microsoft.Extensions.Logging;
```

*after:*

```csharp
using Microsoft.Extensions.Logging;
using System.Linq;
using Zebra.Utilities;
```

## Quick Reference

* Detector: expressão regular `using\s+[^;]+;` para localizar diretivas.
* Escopo: blocos contíguos no topo do arquivo (fora de `namespace {}` locais).
* Exceções: preserve blocos `global using` e linhas comentadas `// keep-order`.
* Fix: extrair bloco, remover linhas vazias internas, ordenar por comparação de string, re-inserir preservando 1 linha em branco após o bloco se havia originalmente.

## Implementation (prática mínima)

1. Localizar primeiro bloco contínuo de linhas que casem `using\s+[^;]+;` a partir do topo.
2. Se houver comentário `// keep-order` imediatamente acima, abortar para esse bloco.
3. Separar `global using` em seu próprio bloco; separar `using static` em seu próprio bloco (opcionalmente junto com outros `using` se preferido, mas documentado).
4. Ordenar strings do namespace com ordenação cultural-invariante (string compare padrão).
5. Substituir o bloco mantendo comentários não relacionados e uma linha em branco depois do bloco, se presente.

**Nota prática:** ao escrever testes (RED phase), inclua casos com comentários entre `using`, `global using`, `using static`, e blocos com `// keep-order` para garantir comportamento esperado.

## Common Mistakes

* Ordenar sem respeitar `// keep-order` → quebra intenções humanas.
* Misturar `global using` com usings normais e perder contexto de visibilidade.
* Remover comentários adjacentes acidentalmente.

## Real-World Impact

* Reduz ruído em PRs, evitando mudanças não-essenciais.
* Uniformiza estilo em grandes codebases C#.

## Minimal Test Cases (suggested)

* Arquivo com `using` fora de ordem simples.
* Arquivo com `global using` e usings normais misturados.
* Arquivo com `using static` e comentários intercalados.
* Arquivo com `// keep-order` acima do bloco (deve permanecer inalterado).
