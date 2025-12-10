---
name: select-service-mocking
description: Use when Angular specs rely on Select services with `mockSelectProviders`, NgRx state, or TestingUtils helpers and engineers start recreating provider stubs manually - enforces deterministic bindings, typed spies, and reset patterns for dropdown/list components
---

# Select Service Mocking

## Overview
Select-driven components (dropdowns, auto-complete, multi-selects) all consume the same provider contracts: `bindValue`, `labelValue`, state streams, and NgRx-backed data. This skill locks every spec to `TestingUtils.mockSelectProviders`, typed `MockProvider`s, and explicit state resets so lists stay predictable.

## When to Use
- Specs importing `TestingUtils.mockSelectProviders` or any `SelectService`.
- Components that call `selectService.getBindings()` or rely on `bindValue/labelValue`.
- Tests needing deterministic NgRx `provideMockStore` state for select filters/facets.
- Situations where devs consider passing raw objects instead of the helper or forging partial mocks.
- Skip for vanilla `<select>` elements managed directly in templates.

## Core Pattern
1. **Catalog all select dependencies.** List every service extending the select abstractions (`UsuarioSelectService`, `ContaRepasseSelectService`, etc.). Include multi-select variants used inside `TestingUtils.mockSelectProviders`.
2. **Mock via the helper, not by hand.** Call `TestingUtils.mockSelectProviders(SelectA, SelectB)` inside the TestBed `providers` array. The helper ensures deterministic `bindValue/labelValue` and returns typed spies with `filter`, `next`, etc.
3. **Augment behavior per test.** After injecting (`const select = TestingUtils.inject(UsuarioSelectService);`), set up spy returns (e.g., `select.list.and.returnValue(of(mockData))`). Never mutate the helper factory itself.
4. **Reset between cases.** Create mocks inside `beforeEach`; call `select.list.calls.reset()` or re-inject depending on scope. Avoid reusing global arrays.
5. **Coordinate with NgRx store.** When selects depend on store state, use `provideMockStore` and `store.setState`. Keep store resets inside `afterEach` or `beforeEach`.
6. **Assert consumer wiring.** After simulating interactions (via `TestingUtils.click`), check that selects were queried with the right params and that the component responded (e.g., patched form control, emitted events).

## Implementation Example
```ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideMockStore, MockStore } from '@ngrx/store/testing';
import { TestingModule, TestingUtils } from '@testing/index';
import { SacadorCartaoSelectService } from '@shared/services/select-services/sacador-cartao-select.service';
import { ContaRepasseSelectService } from '@shared/services/select-services/conta-repasse-select.service';
import { GerenciadorBoletoRemessaFiltrosComponent } from './filtros.component';

describe('GerenciadorBoletoRemessaFiltrosComponent', () => {
  let fixture: ComponentFixture<GerenciadorBoletoRemessaFiltrosComponent>;
  let sacadorSelect: jasmine.SpyObj<SacadorCartaoSelectService>;
  let contaRepasseSelect: jasmine.SpyObj<ContaRepasseSelectService>;
  let store: MockStore;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestingModule, GerenciadorBoletoRemessaFiltrosComponent],
      providers: [
        provideMockStore({ initialState: { filtros: { sacadorId: null } } }),
        ...TestingUtils.mockSelectProviders(SacadorCartaoSelectService, ContaRepasseSelectService),
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(GerenciadorBoletoRemessaFiltrosComponent);
    sacadorSelect = TestingUtils.inject(SacadorCartaoSelectService);
    contaRepasseSelect = TestingUtils.inject(ContaRepasseSelectService);
    store = TestingUtils.inject(MockStore);

    sacadorSelect.list.and.returnValue(of([{ id: 1, nome: 'Foo' }]));
    contaRepasseSelect.list.and.returnValue(of([{ id: 10, descricao: 'Conta' }]));
    fixture.detectChanges();
  });

  it('atualiza filtros ao selecionar sacador', () => {
    const sacadorDropdown = TestingUtils.getElementByCssName(fixture, '[data-test="sacador"]');
    TestingUtils.click(sacadorDropdown);

    expect(sacadorSelect.list).toHaveBeenCalled();
    store.setState({ filtros: { sacadorId: 1 } });
    fixture.detectChanges();
    expect(fixture.componentInstance.form.value.sacadorId).toBe(1);
  });
});
```

## Quick Reference
| Need | Action |
| --- | --- |
| Add select providers | `providers: [...TestingUtils.mockSelectProviders(MySelectService)]` |
| Access mock | `const select = TestingUtils.inject(MySelectService); select.list.and.returnValue(of(data));` |
| Custom bindings | Override `getBindings` result via `select.getBindings.and.returnValue({ bindValue: 'id', labelValue: 'nome' });` |
| Reset state | Call `select.list.calls.reset()` in `afterEach` or recreate provider in `beforeEach`. |
| Combine with NgRx | Add `provideMockStore`, use `store.setState` to drive selectors consumed by selects. |

## Pressure Test (Scenario)
- **Setup:** New filters screen uses three select services. Deadline soon, reviewer says “just stub them as `{ list: () => of([]) }`”. Manual stubs forget `getBindings`, causing runtime errors.
- **Without skill:** Dev writes inline objects, misses `mockSelectProviders`, and can’t reuse helpers; tests fail intermittently.
- **With skill:** Dev follows this skill, drops the helper into providers, injects typed spies, configures returns, and asserts interactions even under time pressure.

## Rationalization Table
| Excuse | Reality |
| --- | --- |
| “Manual stub is faster than importing TestingUtils.” | Helper already lives in `@testing/index`; one line adds all providers with correct bindings. Manual stubs diverge from the contract. |
| “I only need `list`, so I’ll ignore `getBindings`.” | Components rely on `bindValue/labelValue`. Missing bindings break templates silently. |
| “I’ll share one spy across suites.” | Shared spies retain call history/state, causing flakes. Build mocks per suite. |
| “NgRx state isn’t relevant to selects.” | Many selects read store slices; without `provideMockStore` + `setState` your test hits undefined data. |

## Red Flags
- Specs defining `{ list: () => of([]) }` inline for select services.
- `mockSelectProviders` copied into local helper instead of using `TestingUtils`.
- Missing assertions on select parameters or store updates.
- No `provideMockStore` even though component dispatches/selects state.

## Common Mistakes
- **Not importing TestingModule:** Without it, RouterLink/Forms dependencies for select templates fail, tempting devs to use schemas.  
- **Forgetting to reset store:** `MockStore` state bleeds into other specs unless reinitialized.  
- **Ignoring asynchronous emissions:** Some selects emit Observables; ensure `fixture.detectChanges()`/`fixture.whenStable()` run after `store.setState`.

## Deployment Notes
Reference this skill next to `angular-testbed-mocking` inside CLAUDE/AGENTS docs. When new select services are added, mention this skill in their specs to keep mocking strategy aligned.
