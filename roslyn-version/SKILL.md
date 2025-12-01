---
name: roslyn-version
description: Always ignore NU1608 warnings during tests/build and never attempt automated fixes for them, in .cs files.
---

# Roslyn Version

## Overview

Guideline for handling Roslyn-related package restores: NU1608 (dependency downgrade) must be ignored; do not attempt to "fix" it during builds or test runs.

## When to Use

* Executando testes ou build que emitem NU1608 relacionado a pacotes Roslyn/analyzers.
* Revisando PRs que propõem alterar versões de Roslyn para silenciar NU1608.
* Garantindo consistência de versões de compilador/analyzers alinhadas ao SDK.

## Core Pattern

* NU1608 é esperado/aceito nesse contexto — não tratar como falha.
* Não alterar versões de Roslyn/analyzers apenas para remover o warning.
* Evitar ações automáticas de package upgrade/downgrade motivadas pelo NU1608.

## Quick Reference

* Bom: build/test passa com NU1608 registrado no log, sem mudanças de pacote.
* Ruim: subir versão de Roslyn para eliminar NU1608 sem alinhamento ao SDK.
* Ruim: forçar downgrade de dependência para "calar" o warning.

## Implementation

* Documente que NU1608 é conhecido e aceitável no pipeline.
* Garanta que scripts/CI não tratem NU1608 como erro (usar `NoWarn` ou equivalentes quando necessário).
* Em code review, rejeite commits que mexam em versões de Roslyn só por causa desse warning.

## Common Mistakes

* Converter NU1608 em erro e quebrar builds.
* Alterar `Directory.Packages.props` ou `csproj` para suprimir NU1608 via mudança de versão em vez de `NoWarn`.
* Não comunicar que NU1608 é esperado, levando a "correções" indevidas.

## Tests

* Build/test que emite NU1608 deve continuar verde (warning permitido).
* Proposta de upgrade/downgrade de Roslyn motivada apenas por NU1608 deve ser rejeitada.
* Pipeline que falha por NU1608 deve ser ajustado para não tratar como erro.
