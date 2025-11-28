---

name: max-line-length
description: Use when code lines exceed safe readability limits—enforces 120-character maximum and provides guidance for wrapping long statements consistently.
---------------------------------------------------------------------------------------------------------------------------------------------------------------

# Maximum Line Length

## Overview

Skill para garantir que nenhuma linha ultrapasse 120 caracteres. Mantém legibilidade, facilita revisão e evita diffs ruidosos.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## When to Use

**Gatilhos / sintomas**

* Linhas maiores que 120 chars
* Scroll horizontal recorrente
* Dificuldade em revisar PRs
* Diffs enormes quando só uma parte da linha mudou

**Quando NÃO usar**

* Arquivos gerados automaticamente
* Linhas onde quebra prejudicaria literais longos (strings de rota, regex complexa) — avaliar caso a caso

## Core Pattern

**Princípio:** linhas com mais de 120 chars devem ser quebradas preservando clareza e indentação.

*before:*

```csharp
var result = ProcessarPrestadora(nome, cidade, estado, codigoMunicipal, responsavel, inscricaoEstadual, inscricaoMunicipal, regimeTributario, codigoServicoPadrao);
```

*after:*

```csharp
var result = ProcessarPrestadora(
    nome,
    cidade,
    estado,
    codigoMunicipal,
    responsavel,
    inscricaoEstadual,
    inscricaoMunicipal,
    regimeTributario,
    codigoServicoPadrao
);
```

## Quick Reference

* Limite: **120 caracteres**
* Detecção: `^.{121,}$`
* Ação: wrap automático (`type: wrap`)
* Preservar indentação relativa
* Preferir quebrar em delimitadores: `,`, `(`, `{`, `=`, operadores binários

## Implementation (mínimo necessário)

1. Verificar tamanho da linha; se >120 → marcar.
2. Tentar quebrar em ponto lógico:

   * após vírgulas,
   * antes de operadores,
   * ao abrir parênteses de chamada.
3. Inserir nova linha com indentação + 4 espaços (ou padrão do projeto).
4. Continuar quebrando até todas as linhas ≤120 chars.

**Casos que devem ser testados:**

* Chamadas de método com muitos parâmetros
* Expressões booleanas longas
* Interpolated strings (`$"..."`)
* Objetos anonimos extensos
* Linhas com comentários ao final

## Common Mistakes

* Quebrar dentro de literais de string
* Perder indentação original
* Criar múltiplas quebras desnecessárias
* Não preservar trailing comma ao quebrar inicializadores

## Real-World Impact

* Leitura mais rápida
* PRs menores e mais claros
* Menos retrabalho em conflitos
* Código consistente em toda a base

## Minimal Test Cases (suggested)

* Linha com 121+ chars simples
* Chamada de método com vírgulas
* Expressão complexa com operadores
* Linha com comentário longo
* Bloco já bem formatado (não alterar)
