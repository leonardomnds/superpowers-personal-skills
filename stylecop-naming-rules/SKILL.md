---
name: stylecop-naming-rules
description: Always use this when StyleCop naming rules are enabled in .NET project — enforces tuple element casing, Hungarian prefix policy, and allowed namespace components.
---

# StyleCop Naming Rules

## Overview

Aplica as regras de nomenclatura definidas em `namingRules` no StyleCop: casing de elementos de tupla, prefixos permitidos e validação de componentes de namespace.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## When to Use

* Projeto possui `namingRules` no stylecop.json
* PRs apresentam nomes inconsistentes de tuplas ou uso de prefixos inadequados
* Namespaces com componentes fora do padrão do time

## Core Pattern

* `tupleElementNameCasing`: camelCase ou PascalCase
* `allowCommonHungarianPrefixes`: true/false
* `allowedHungarianPrefixes`: lista permitida (1–2 letras)
* `allowedNamespaceComponents`: nomes autorizados para compor namespaces

## Quick Reference

* camelCase: `firstName`
* PascalCase: `FirstName`
* Hungarian prefix permitido: ex.: `bkId`

## Implementation

* Analisar elementos de tupla via AST e renomear conforme casing
* Validar prefixos: rejeitar não permitidos
* Validar componentes de namespace contra lista configurada

## Common Mistakes

* Misturar camelCase e PascalCase em elementos da mesma tupla
* Usar prefixos fora da lista permitida
* Criar novos namespaces sem seguir convenções do stylecop.json

## Tests

* Tupla `(string FirstName, int Age)` quando camelCase → sugerir `(string firstName, int age)`
* Variável `strName` quando Hungarian não permitido → ajustar
* Namespace `MyCompany.FeatureX` quando `FeatureX` não está na lista permitida → sinalizar
