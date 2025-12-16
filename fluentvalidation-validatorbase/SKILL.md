---
name: fluentvalidation-validatorbase
description: Use when criando ou alterando validators FluentValidation em projetos com ValidatorBase<T> que expõe IUnitOfWork—orienta herdar ValidatorBase, evitar AbstractValidator direto, usar MustExists/validators async e proteger consultas com sessão/tenant.
---

# FluentValidation + ValidatorBase

## Visão Geral
No EuGestor, validators de comandos/queries devem herdar `ValidatorBase<T>` para ter `IUnitOfWork` injetado, usar helpers (`MustExists`, validators async) e manter consistência multitenant. Evite `AbstractValidator` direto. Regras devem ser mínimas, seguras a concorrência e cobrir existência/pertencimento.

## Quando Usar
- Criando/alterando qualquer validator FluentValidation para comandos/queries.
- Ao adicionar regras que consultam o banco (precisa de `IUnitOfWork`).
- Revisando PRs que trazem `AbstractValidator<T>` diretamente.

## Padrão Essencial
1) Herdar `ValidatorBase<T>` e receber `IUnitOfWork` no ctor; chame `base(unitOfWork)`.  
2) Injete `ISessaoService` quando precisar limitar por Empresa/Usuário.  
3) Use helpers existentes: `MustExists`/`MustExists<TCommand, TEntity>` com repositório, `SetAsyncValidator` para validadores específicos.  
4) Nunca faça `.MustAsync` com consultas fora do `IUnitOfWork` compartilhado.  
5) Regras assíncronas devem aceitar `CancellationToken` (helpers já fazem).  
6) Uma responsabilidade por regra; mantenha mensagens claras.  
7) Para listas/coleções, valide itens com `RuleForEach` em vez de loops manuais.

## Exemplos do Projeto
**Validator simples com MustExists**  
`src/Application/AcoesVenda/Commands/Cancelar/CancelarAcaoVendaCommandValidator.cs`
```csharp
public class CancelarAcaoVendaCommandValidator : ValidatorBase<CancelarAcaoVendaCommand>
{
    public CancelarAcaoVendaCommandValidator(IUnitOfWork unitOfWork) : base(unitOfWork)
    {
        RuleFor(c => c.AcaoVendaId)
            .MustExists<CancelarAcaoVendaCommand, AcaoVenda>(unitOfWork);
    }
}
```

**Validator com sessão e validator async específico**  
`src/Application/Leads/Commands/RemoverAnexo/RemoverAnexoLeadCommandValidator.cs`
```csharp
public class RemoverAnexoLeadCommandValidator : ValidatorBase<RemoverAnexoLeadCommand>
{
    public RemoverAnexoLeadCommandValidator(
        IUnitOfWork unitOfWork,
        ISessaoService sessaoService) : base(unitOfWork)
    {
        RuleFor(c => c.PessoaId)
            .SetAsyncValidator(
                new ExistenciaLeadValidator<RemoverAnexoLeadCommand>(
                    unitOfWork.GetRepository<PessoaEmpresa>(),
                    sessaoService.EmpresaId));

        RuleFor(c => c.PessoaArquivoId)
            .MustExists(unitOfWork.GetRepository<PessoaArquivo>());
    }
}
```

## Referência Rápida
- Sempre herde `ValidatorBase<T>` para comandos/queries do Application.  
- Use `MustExists` para checar existência; passe repositório ou `unitOfWork` conforme overload.  
- Precisa filtrar por empresa? Injete `ISessaoService` e use nos validators/helpers.  
- Valide coleções com `RuleForEach(x => x.Itens)...`.  
- Mensagem padrão dos helpers já cobre “não encontrado”; personalize só se necessário.  
- Evite lógica de negócio complexa no validator; apenas pré-condições/consistência de dados.

## Erros Comuns
- Herdar `AbstractValidator` e reabrir conexões: perde `IUnitOfWork` e cria queries inconsistentes.  
- Não injetar `ISessaoService` onde há dado multitenant.  
- Duplicar consultas em várias regras em vez de um helper compartilhado.  
- Esquecer `base(unitOfWork)` no ctor.  
- Criar validações sincrônicas que tocam o banco (use helpers async/prontos).  
- Validar “pertence à empresa” na aplicação mas esquecer de usar o `EmpresaId` da sessão.

## Bandeiras Vermelhas
- Validator novo sem `: ValidatorBase<T>`.  
- `.MustAsync` abrindo `new DbContext` ou usando context estático.  
- Regras repetidas checando a mesma tabela em várias lambdas.  
- Falta de filtro de tenant em validação que depende de empresa/usuário.  
- Regras que fazem side effects (alteram dados, enviam eventos).

## Checklist de Aplicação
- Herdou `ValidatorBase<T>` e chamou `base(unitOfWork)`?  
- Usou helpers (`MustExists`, validators específicos) em vez de consultas custom?  
- Injetou `ISessaoService` quando necessário para filtrar por empresa/usuário?  
- Nenhuma regra abre contexto externo ao `IUnitOfWork`?  
- Validações de coleção usam `RuleForEach`?  
- Mensagens estão claras e sem duplicar consultas?
