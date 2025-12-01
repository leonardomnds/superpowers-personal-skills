---
name: stylecop-documentation-rules
description: Always use this when StyleCop documentation rules are enabled in .NET projects — enforces XML documentation, file headers, naming conventions and documentation culture.
---

# StyleCop Documentation Rules

## Overview

Aplica regras de documentação definidas em `documentationRules`: necessidade de XML docs, cabeçalhos padrão, cultura de documentação, convenções de nome de arquivo e exceções de pontuação.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use

* Projeto possui `documentationRules` no stylecop.json
* PRs trazem classes públicas sem documentação
* Novos arquivos devem conter cabeçalho padrão

## Core Pattern

* `documentExposedElements`: exige XML docs para membros públicos
* `documentInternalElements`: internos requerem docs
* `documentPrivateElements`: privados requerem docs (se configurado)
* `xmlHeader`: inserir cabeçalho gerado com `companyName`, `variables` e `copyright`
* `fileNamingConvention`: stylecop ou metadata
* `documentationCulture`: padrão de cultura (ex.: en-US)

## Quick Reference

Headers:

* Empresa → `{companyName}`
* Substituições → `variables:{ key:value }`

Docs:

* Gerar `/// <summary></summary>` com placeholder
* Gerar docs para parâmetros se faltando

## Implementation

* Detectar ausência de XML docs em elementos obrigatórios
* Inserir cabeçalho com template configurado
* Validar nome do arquivo conforme convenção
* Ironia: usar AST para evitar erros em blocos complexos

## Common Mistakes

* Ausência de `<summary>` em membros públicos
* Cabeçalho desalinhado com config
* Nome de arquivo divergente de `fileNamingConvention`

## Tests

* Classe pública sem docs → gerar stub
* Arquivo sem header → adicionar
* Nome de arquivo não seguindo convenção → sugerir renomear
