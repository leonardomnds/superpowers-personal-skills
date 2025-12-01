---
name: global-usings-rule
description: Always use this when adding new using directives to C# files—checks GlobalUsings.cs first to avoid redundant imports and centralize shared namespaces.
---

# Global Usings Rule

## Overview

**Uso obrigatório ao criar/editar arquivos:** antes de iniciar qualquer alteração, execute `~/.codex/superpowers/.codex/superpowers-codex use-skill global-usings-rule` e mantenha esta skill carregada enquanto edita.

Skill para evitar adicionar `using` redundante quando já existe `global using` no projeto. Mantém arquivos limpos e concentra imports compartilhados.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## When to Use

**Gatilhos / sintomas**

* Arquivos contendo `using System;`, `using System.Linq;` etc. já presentes em `GlobalUsings.cs`
* Repetição dos mesmos `using` em vários arquivos
* PRs com remoção manual de imports redundantes
* Confusão sobre onde colocar usings compartilhados

**Quando NÃO usar**

* Projetos sem suporte a `global using`
* Arquivos com escopo extremamente específico que exigem visibilidade local

## Core Pattern

**Princípio:** antes de adicionar um `using`, verificar se aquele namespace já está em algum arquivo `GlobalUsings.cs` relevante. Se estiver → não adicionar; se não estiver → adicionar localmente ou considerar inserir no GlobalUsings caso seja usado em vários lugares.

Exemplo ruim:

```csharp
using System;  // redundante
using System.Linq;  // redundante
```

Exemplo bom:

```csharp
using Inside.EuGestor.NFSe.Domain.Entities;  // não está nos global usings
```

## Quick Reference

**Localizações comuns de GlobalUsings:**

* `test/Application.IntegrationTests/GlobalUsings.cs`
* `test/Application.UnitTests/GlobalUsings.cs`
* `test/Domain.UnitTests/GlobalUsings.cs`
* `src/Application/GlobalUsings.cs`
* `src/WebAPI/GlobalUsings.cs`

**Regra prática:**

* Import redundante? Remover.
* Import repetido em vários lugares? Mover para GlobalUsings.

## Implementation (mínimo necessário)

1. Determinar qual `GlobalUsings.cs` se aplica ao arquivo atual (src/test).
2. Carregar lista de `global using <namespace>;` desse arquivo.
3. Ao adicionar `using`: verificar se o namespace existe na lista.
4. Se existir → não adicionar (ou sugerir remoção se já presente).
5. Se não existir e for amplamente usado → sugerir mover para GlobalUsings.

**Casos que devem ser testados:**

* Arquivos test e arquivos src usando diferentes GlobalUsings
* Namespaces parcialmente qualificados
* `using static` presentes no global
* Redundância múltipla no mesmo arquivo

## Common Mistakes

* Adicionar localmente usings que já estão nos global
* Criar GlobalUsings duplicados em múltiplos diretórios
* Colocar usings específicos demais no global
* Esquecer `using static` no mapeamento

## Real-World Impact

* Menos duplicação
* Arquivos mais limpos
* Atualizações globais simples
* Diminui PR noise

## Minimal Test Cases (suggested)

* Arquivo com três usings redundantes
* Arquivo que usa namespace não-global (deve adicionar localmente)
* GlobalUsings com `using static`
* Projetos com múltiplos GlobalUsings por camada
