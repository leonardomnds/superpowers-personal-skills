---
name: angular-testbed-mocking
description: Use when Angular specs silence template errors with NO_ERRORS_SCHEMA/CUSTOM_ELEMENTS_SCHEMA, patch services directly, or skip TestingModule/ng-mocks - enforces disciplined TestBed imports, MockProvider usage, typed jasmine fallbacks, and TestingUtils-driven wiring so DI stays deterministic
---

# Angular TestBed Mocking

## Overview
Lock every Angular spec to the TestBed so dependencies, modules, and DOM collaborators are declared once, mocked deterministically, and injected the same way production code sees them. No ad-hoc property patching, no implicit schemas, no leaky singletons.

## When to Use
- Component/service/directive specs that import Angular modules, Material/CDK elements, or inject framework services.
- Any time `NullInjectorError`, `NG0303`, `NG0304`, or template warnings about unknown elements pop up—check whether importing `TestingModule` (or the real feature module) fixes it instead of adding schemas.
- Teams tempted to `component.fooService = fake`, use untyped `jasmine.createSpyObj`, or drop `NO_ERRORS_SCHEMA`/`CUSTOM_ELEMENTS_SCHEMA`.
- Skip for plain TypeScript utilities that can be tested without Angular.

## Core Pattern
1. **Map collaborators and warnings.** List modules, declarations, providers, and DOM elements the SUT touches, plus any template warnings. Include Angular Material/CDK modules, RouterTestingModule, HttpClientTestingModule, TranslateModule, etc.
2. **Import real modules before mocking.** Try `TestingModule`, `ListagemTestingModule`, or the actual feature module and confirm warnings disappear. Only reach for `MockComponent`/`MockDirective` if importing the module is impossible or wasteful—never fix warnings with schemas.
3. **Centralize TestBed config.** Wrap defaults in `createTestingModule(overrides?: Partial<TestModuleMetadata>)` and expose helpers via `TestingUtils` so specs share the same imports/providers and overrides stay explicit.
4. **Mock declarations com ng-mocks nos imports.** Use `MockComponent`/`MockDirective`/`MockPipe`/`MockComponents` diretamente no array `imports` (incluindo standalones) para satisfazer dependências de template de forma determinística; prefira isso a `overrideComponent`.
5. **Mock services via providers, não propriedades.** Registre serviços com `MockProvider`/`MockProviders` para que DI e lifecycle vejam o stub; recupere-os com `TestingUtils.inject<Service>()` após `compileComponents`. Evite montar objetos manuais (ex.: signals artificiais) fora do TestBed.
6. **Type every jasmine spy and inject via helpers.** Sempre use `jasmine.createSpyObj<Type>` (quando necessário) e injete com `TestingUtils.inject<Service>() as jasmine.SpyObj<Service>` para manter tipos e DI explícitos.
7. **Use TestingUtils para interação/injeção e modais.** Acesse serviços por `TestingUtils.inject`, dispare eventos com `TestingUtils.click`, substitua imports via `TestingUtils.replaceImport`, use `TestingUtils.mockNgbModalRef()`/`mockNgbOffcanvasRef()` para retornos de `NgbModal`/`NgbOffcanvas`.
8. **Inputs e dados por teste, não helpers globais.** Configure inputs diretamente no Arrange de cada `it` com `fixture.componentRef.setInput(...)`, usando factories (`generateX`), helpers do projeto (`createApiResponseListaMock`/`createApiResponseMock`) e `faker` para respostas realistas. Evite helpers como `setInputs` em `beforeEach` que escondem estado; cada teste deve declarar o que precisa.
9. **Controle o timing do `detectChanges`.** Se o `OnInit` dispara chamadas externas, deixe `fixture.detectChanges()` dentro do próprio teste para preparar stubs/inputs antes; só mova para o `beforeEach` quando o estado inicial for igual em todos os casos.
10. **Compile once per describe.** Use `beforeEach(async () => { await configure(); fixture = TestBed.createComponent(...); /* detectChanges opcional aqui */ })`. Let Angular's automatic teardown run, calling `TestBed.resetTestingModule()` only when you mutate global providers.

## Implementation Example
```ts
// billing-summary.component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { MockComponent, MockProvider } from 'ng-mocks';
import { provideMockStore, MockStore } from '@ngrx/store/testing';
import { TestingModule, TestingUtils } from '@testing/index';
import { BillingSummaryComponent } from './billing-summary.component';
import { BillingSummaryCardComponent } from '../ui/billing-summary-card.component';
import { BillingService } from '../data/billing.service';
import { generateBillingInput } from '../data/billing.mocks';
import { createApiResponseMock } from '@data/common/api-response.mock';

const initialState = { invoices: { summary: null } };

describe('BillingSummaryComponent', () => {
  let fixture: ComponentFixture<BillingSummaryComponent>;
  let billingService: jasmine.SpyObj<BillingService>;
  let httpMock: HttpTestingController;
  let store: MockStore;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        TestingModule, // brings shared pipes/components
        HttpClientTestingModule,
        RouterTestingModule
      ],
      declarations: [
        BillingSummaryComponent,
        MockComponent(BillingSummaryCardComponent)
      ],
      providers: [
        provideMockStore({ initialState }),
        // MockProvider cria um spy para cada método público
        MockProvider(BillingService)
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(BillingSummaryComponent);
    billingService = TestingUtils.inject(BillingService) as jasmine.SpyObj<BillingService>;
    httpMock = TestBed.inject(HttpTestingController);
    store = TestBed.inject(MockStore);
    billingService.loadSummary.and.returnValue(of({ total: 0 } as any));
    fixture.detectChanges();
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('loads summary once OnInit and reacts to retry click', () => {
    // Arrange
    const input = generateBillingInput();
    fixture.componentRef.setInput('input', input);
    billingService.loadSummary.and.returnValue(of(createApiResponseMock(() => ({ total: 0 }))));
    fixture.detectChanges();

    // Act
    expect(billingService.loadSummary).toHaveBeenCalledTimes(1);
    const retryBtn = TestingUtils.getElementByCssName(fixture, '[data-test="retry"]');
    TestingUtils.click(retryBtn);

    // Assert
    expect(billingService.loadSummary).toHaveBeenCalledTimes(2);
  });
});

// Signal-based service fallback
const metricsSpy = jasmine.createSpyObj<SignalBasedService>('SignalBasedService', ['update']);
TestBed.overrideProvider(SignalBasedService, { useValue: metricsSpy });
```

## Quick Reference
| Need | Action |
| --- | --- |
| Unknown element/attribute warnings | Import the real module (Material/CDK, feature modules, or shared `TestingModule`) before considering mocks—never silence with schemas. |
| Template-only collaborators | Declare `MockComponent/MockDirective/MockPipe` from `ng-mocks` so the DOM stays deterministic without pulling the full module. |
| Services | Prefer `MockProvider`/`MockProviders` e injete com `TestingUtils.inject<Service>() as jasmine.SpyObj<Service>`; configure `and.returnValue`/`and.callFake` nos métodos. Se ng-mocks falhar (signals), registre `jasmine.createSpyObj<Service>` via `providers`. |
| Standalone children | Use `MockComponents(...)` direto no `imports` para mockar filhos standalones sem `overrideComponent`. |
| HTTP collaborators | Import `HttpClientTestingModule`, grab `HttpTestingController`, `verify()` in `afterEach`. |
| Router links/Navigation | Use `RouterTestingModule.withRoutes([])` or `RouterTestingHarness`, or replace directives via `TestingUtils.replaceImport`. |
| Inputs | Sempre defina inputs no próprio teste via `fixture.componentRef.setInput(...)`, usando factories de dados; não esconda setup em helpers globais. |
| TestingUtils helpers | Rely on `TestingUtils.inject`, `TestingUtils.click`, `TestingUtils.mockSelectProviders`, etc., instead of ad-hoc helpers. |

## Pressure Test (Scenario Verification)
- Scenario: 200-line Angular component using MatDialog + HttpClient + custom directives. Release train leaves in 20 minutes; PM wants "just spy on the service", "drop schemas to ignore Material warnings", and "skip TestingUtils to save time".
- Without skill: `NO_ERRORS_SCHEMA` hides template failures, service is patched directly on the component, ng-mocks is skipped, and untyped spies miss methods—tests become flaky when DI order changes.
- With this skill: collaborator map surfaces MatDialogModule/HttpClientTestingModule + shared `TestingModule`, declarations rely on `MockComponent`, services come from `MockProvider` (typed), TestingUtils drives clicks/injections, and the MatDialog harness verifies behavior deterministically. PM pressure is answered with imports + provider overrides instead of ad-hoc patches.

## Rationalization Table
| Excuse | Reality |
| --- | --- |
| "It's faster to set `component.billingService = fake` after `createComponent`." | That bypasses DI, so lifecycle hooks still use the real instance. Register fakes in `providers` or `overrideProvider`. |
| "`NO_ERRORS_SCHEMA`/`CUSTOM_ELEMENTS_SCHEMA` cleans up template noise." | They hide missing imports entirely. Import the module (or `TestingModule`) or use `MockComponent` so warnings surface during regressions. |
| "MockProvider can't handle this signal service, so I'll keep the real one." | Register a typed `jasmine.createSpyObj<SignalService>` via `providers`. The fallback stays deterministic and documents the one-off limitation. |
| "Untyped `jasmine.createSpyObj` is fine; TypeScript will catch it later." | Untyped spies silently drop methods and return types. Always use the generic signature so the compiler enforces contract drift. |
| "TestingUtils is optional; direct DOM querying is faster." | TestingUtils centralizes common patterns (clicks, modal refs, inject). Skipping it recreates brittle helpers and diverges from shared utilities. |

## Red Flags — Stop and Re-align
- Assigning spies directly onto component/service properties.
- Adding `schemas: [NO_ERRORS_SCHEMA|CUSTOM_ELEMENTS_SCHEMA]` just to silence errors.
- Instantiating Angular services with `new` inside tests.
- Calling `TestBed.inject` after `fixture.detectChanges()` revealed a failure you are trying to mask.
- Using shared mutable singletons (e.g., `const fakeService = ...; providers: [{provide, useValue: fakeService}]` reused across tests) without resetting spies.
- Reaching for manual mocks before checking whether importing `TestingModule` (or the real feature module) removes the warning.
- Montar objetos de serviço manualmente (incluindo signals fake) em vez de `MockProviders` + `TestingUtils.inject` após `compileComponents`.
- Creating `jasmine.createSpyObj` without `<Type>` generics or method lists.

## Common Mistakes
- Forgetting to reinitialize spy return values between tests → wrap stub creation in factories inside `beforeEach`.
- Importing entire `AppModule` to satisfy dependencies → start with `TestingModule` or feature modules plus targeted `MockComponent` declarations.
- Overriding provider after `compileComponents` without `TestBed.resetTestingModule()` → order-sensitive leakage. Configure before compilation.
- Mixing manual zone flushing with harness utilities → prefer `fixture.whenStable()` or harness `forceStabilize`.
- Ignoring `TestingUtils` helpers → duplicate modal/select stubs drift from the canonical implementations and miss future fixes.
- Criar helpers globais como `setInputs` em `beforeEach` que escondem o setup por teste → configure inputs explicitamente no Arrange de cada `it`.

## Deployment Notes
Add this skill to your personal git repo (dotfiles or knowledge base) and share via PR if others face the same TestBed anti-patterns. Reference it in project CLAUDE.md so future agents load it before touching Angular specs.
