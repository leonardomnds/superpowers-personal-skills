name: automapper-dto-mapping
description: Use when criando ou revisando AutoMapper Profiles para mapear DTOs e entidades em .NET - reforça mapear apenas diferenças de convenção (nome/tipo), evitar ForMember redundante e validar configuração para manter mapeamentos curtos, legíveis e seguros a renomes.

# AutoMapper DTO Mapping

## Visão Geral
Mantenha mapeamentos focados apenas em diferenças. O AutoMapper já resolve propriedades com mesmo nome e tipo; cada ForMember redundante aumenta ruído e risco em renomes. Configure somente exceções, valide o profile e cubra cenários especiais com testes.

## Quando Usar
- Criando novos profiles DTO ↔ entidade ou ajustando mapeamentos existentes cheios de ForMember.
- Quando há propriedades renomeadas, conversões de tipo, valores padrão ou regras de ignorar campos.
- Ao revisar PRs com mapeamentos verbosos para reforçar o padrão de “só mapear o que difere”.

## Padrão Essencial
1) Comece pelo CreateMap<Origem, Destino>() (use ReverseMap() se for bidirecional).  
2) Não escreva ForMember para campos com mesmo nome e tipo. Confie nas convenções.  
3) Use ForMember/ForPath apenas para diferenças: renomeados, tipos diferentes, defaults, combinações, ignores.  
4) Prefira mapear aninhados via ForPath ou maps específicos (ex.: CreateMap<EnderecoDto, Endereco>), evitando lambdas gigantes.  
5) Ignore IDs/controle que não devem ser sobrescritos (ex.: .ForMember(d => d.Id, opt => opt.Ignore())).  
6) Valide o profile: new MapperConfiguration(cfg => cfg.AddProfile<...>()).AssertConfigurationIsValid().  
7) Cubra regras especiais com teste de configuração + teste de comportamento quando houver lógica em MapFrom.

## Exemplos Enxutos (do projeto)
**IMapFrom** – `src/Application/OrdensServico/Queries/GetContato/GetContatoDaOrdemServicoDto.cs`  
Só há uma diferença real (Id → ContatoId); o resto fica na convenção:
```csharp
public class GetContatoDaOrdemServicoDto : IMapFrom<Contato>
{
    public long ContatoId { get; set; }
    public string Nome { get; set; }
    public string Email { get; set; }
    public string Telefone { get; set; }
    public bool IsPrincipal { get; set; }

    public void Mapping(Profile profile)
    {
        profile.CreateMap<Contato, GetContatoDaOrdemServicoDto>()
            .ForMember(d => d.ContatoId, opt => opt.MapFrom(s => s.Id)); // diferença real
            // Nome, Email, Telefone, IsPrincipal: mesma convenção -> não mapear
    }
}
```

**IMapTo** – `src/Application/OrdensServico/AgendamentoDto.cs`  
Ignora o campo de controle e usa convenção para o resto:
```csharp
public class AgendamentoDto : IMapTo<NovoAgendamentoModel>
{
    public DateTime DataInicio { get; set; }
    public int DuracaoPrevistaEmMinutos { get; set; }

    public void Mapping(Profile profile)
    {
        profile.CreateMap<AgendamentoDto, NovoAgendamentoModel>()
            .ForMember(d => d.DataRealizacaoAgendamento, opt => opt.Ignore()); // controle
            // DataInicio e DuracaoPrevistaEmMinutos: mesma convenção -> não mapear
    }
}
```

## Referência Rápida
- Igual nome/tipo? → Não use ForMember; deixe a convenção.  
- Campo renomeado? → ForMember/ForPath com MapFrom.  
- Conversão de tipo (enum/string, decimal/double)? → MapFrom com cast/conversão explícita + teste.  
- Campo somente leitura/controle? → Ignore().  
- Map bidirecional? → ReverseMap() se não há divergência ou regras opostas; caso contrário, dois CreateMap separados.  
- Muitos ForMember? → Reavalie: separar mapas aninhados ou mover lógica para serviços/DTOs.

## Erros Comuns
- Mapear tudo “por segurança”: cria ruído e quebra em renomes; confie na convenção + AssertConfigurationIsValid().  
- Fazer lógica de negócio no MapFrom: mantenha apenas composição/transformação simples; regras ficam em serviços.  
- Esquecer validação do profile: inclua teste de configuração no projeto (ex.: MapperConfiguration.AssertConfigurationIsValid()).  
- Ignorar campos de controle (Id, audit) e sobrescrever acidentalmente: sempre Ignore quando vindo do cliente.

## Bandeiras Vermelhas (pare e revise)
- ForMember repetindo nome/tipo idênticos.  
- Perfil com dezenas de ForMember sem renome/transformação clara.  
- MapFrom contendo regra de negócio ou acesso a infraestrutura.  
- Falta de teste de configuração do AutoMapper no projeto.

## Tabela de Racionalizações vs. Correções
| Racionalização                         | Correção                                                                                |
|----------------------------------------|-----------------------------------------------------------------------------------------|
| “Explícito é mais seguro”              | Segurança vem da validação do profile e testes; redundância só esconde diferenças reais.|
| “QA precisa ver cada campo mapeado”    | QA verifica comportamento; liste apenas exceções. Convenção cobre o resto.              |
| “AutoMapper já falhou antes, mapo tudo”| Use AssertConfigurationIsValid e testes de mapa; mapear tudo mascara problemas.         |
| “Renomear pode quebrar, mapeio manual” | Validação + testes acusam renomes; ForMember redundante quebra silenciosamente também.  |

## Teste Sugerido (config)
```csharp
[Fact]
public void AutomapperConfiguration_IsValid()
{
    var config = new MapperConfiguration(cfg =>
    {
        cfg.AddProfile<ClienteProfile>();
        // adicionar demais profiles aqui ou usar assembly scan conforme o projeto
    });

    config.AssertConfigurationIsValid();
}
```

## Checklist de Aplicação
- Comece com CreateMap limpo; só adicione ForMember/ForPath para diferenças.  
- Revise cada ForMember: é diferença real? Se não, remova.  
- Ignore campos de controle.  
- Valide com AssertConfigurationIsValid em teste automatizado.  
- Adicione testes de comportamento quando houver transformação/cálculo em MapFrom.
