---
name: permissao-attribute
description: Use when creating or modifying C# Commands or Queries—enforces presence of PermissaoAttribute or SemPermissaoAttribute and ensures each assigned GUID is unique across the entire project when PermissaoAttribute is used.
---

# Permissao Attribute Enforcement

## Overview

Skill para garantir que **todas as Commands e Queries** possuam **ou** `PermissaoAttribute` **ou** `SemPermissaoAttribute` (quando estes atributos existem no projeto). Quando gerar novo código, **use sempre `PermissaoAttribute`**. Além disso, quando `PermissaoAttribute` for usado, o GUID associado **deve ser único** em toda a solução.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## Regras essenciais (sem negociação)

* Classes que representam Commands ou Queries **devem** ter um dos atributos: `Permissao` **ou** `SemPermissao`, se estes atributos existirem no projeto.
* Ao escrever novo código: **sempre** aplicar `Permissao` (com GUID único).
* **Nunca** altere um GUID já existente de uma `Permissao` atribuída a uma classe que já existe no projeto.
* **Nunca** substitua um `SemPermissao` por `Permissao` em uma classe já existente.
* Se o projeto não contém `PermissaoAttribute` e `SemPermissaoAttribute`, a skill não impõe nada.

## When to Use

**Gatilhos / sintomas**

* Criando novo `Command` ou `Query`
* Revisando PRs que adicionam/alteram classes de requisição
* Encontrando GUIDs duplicados ou classes sem atributo

**Quando NÃO usar**

* Projetos que não possuem nenhum dos atributos (`PermissaoAttribute`/`SemPermissaoAttribute`)
* Classes que não são Commands/Queries (DTOs, models, helpers)

## Core Pattern

**Princípio:**

1. Detectar classes-alvo (herdam de `QueryPaginadaPara<>`, `CommandBase`, implementam `IRequest<>`, ou nome terminando em `Command`/`Query`).
2. Se o projeto define `PermissaoAttribute` ou `SemPermissaoAttribute`, exigir que cada classe-alvo tenha exatamente um desses atributos.
3. Ao criar novas classes, adicionar `Permissao("<GUID>")` — GUID v4 único.
4. Validar unicidade dos GUIDs de todas as `Permissao` no repositório.
5. Proibir alterações de GUID existentes e proibir substituições de `SemPermissao` → `Permissao`.

Exemplo correto (novo arquivo):

```csharp
[Permissao("37A5E959-CDAF-4D0E-B204-11FD0BEEC818")]
public class GetAnexosDaPessoaQuery : QueryPaginadaPara<GetAnexosDaPessoaDto>
{
    public long PessoaId { get; set; }
}
```

Exemplo correto (classe existente sem permissão explicitada):

```csharp
[SemPermissao]
public class SomeQuery : QueryPaginadaPara<...> { }
```

## Quick Reference

* Atributos válidos: `Permissao("<GUID>")` OU `SemPermissao` (nome exato conforme projeto).
* Formato GUID: 36 chars com hífens (preferir MAIÚSCULAS para consistência).
* Unicidade: nenhum outro arquivo pode conter o mesmo GUID usado em um `Permissao`.
* Ao gerar código novo: **usar `Permissao`** sempre.

## Implementation (mínimo necessário)

1. **Detectar existência dos atributos:**

   * Procurar declarações `class PermissaoAttribute` e `class SemPermissaoAttribute` no código-fonte do repositório (ou assembly de referência se disponível).
   * Se nenhum existir → regra inativa.
2. **Identificar classes-alvo:**

   * Herança/implementação conhecida (`QueryPaginadaPara<>`, `CommandBase`, `IRequest<>`) OU nome terminando em `Query`/`Command`.
3. **Verificar atributo presente:**

   * Se ausente → erro/sugestão para adicionar; ao adicionar, **use `Permissao`** com GUID gerado.
4. **Verificar unicidade de GUIDs:**

   * Construir índice de todos os GUIDs usados em `Permissao` no repositório.
   * Se duplicado → erro apontando ambos os arquivos e solicitar correção humana (não auto-substituir).
5. **Proibições automáticas:**

   * Não performar alteração automática de GU
