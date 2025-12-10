---
name: modal-mocking-patterns
description: Use when Angular specs interact with NgbModal/NgbOffcanvas and engineers are tempted to spy manually, skip TestingUtils helpers, or forget to assert close/dismiss semantics - codifies deterministic TestBed wiring with typed modal refs, componentInstance hooks, and watcher expectations
---

# Modal Mocking Patterns

## Overview
Every modal/offcanvas spec must keep DI, lifecycle, and dismissal behavior deterministic. Replace ad-hoc spies with the shared `TestingUtils` factories, ensure modal services live in the provider graph, and assert `close`/`dismiss` outcomes explicitly so UI flows never silently regress.

## When to Use
- Component/service tests calling `NgbModal` or `NgbOffcanvas`.
- Specs that currently do `spyOn(modalService, 'open').and.returnValue({ ... })`.
- When a modal component exposes `componentInstance` properties/events that drive assertions.
- Anytime a spec triggers confirm/cancel flows and needs to assert overlay watchers/metrics.
- Skip for non-Angular environments (e.g., Cypress E2E) where bootstrap modals are covered elsewhere.

## Core Pattern
1. **Register modal services via providers.** Keep `NgbModal`/`NgbOffcanvas` in the DI graph (from `TestingModule` or explicit providers) so constructor injections/harnesses resolve correctly.
2. **Use `TestingUtils.mockNgbModalRef` / `mockNgbOffcanvasRef`.** These factories already expose typed spies with `close`/`dismiss`, `result`, `closed`, `dismissed`, and optional `componentInstance`. Never craft manual objects.
3. **Expose component instance upfront.** When the modal component needs stubbed inputs/outputs, pass a typed `componentInstance` (also a `jasmine.SpyObj`) to the mock factory so the SUT can interact with it normally.
4. **Return deterministic results.** Preconfigure `result`/`closed` Observables/Promises to mimic confirm vs cancel flows. Use helpers like `TestingUtils.mockNgbModalRef({ closed: new Subject() })` when tests must emit later.
5. **Assert interactions after trigger.** Always check `modalService.open` parameters (component, config), verify `close`/`dismiss` calls, and inject downstream services via `TestingUtils.inject` to confirm side effects fired.
6. **Reset between specs.** Recreate modal refs in each `beforeEach` so spies start from zero and `componentInstance` state does not leak.

## Implementation Example
```ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { TestingModule, TestingUtils } from '@testing/index';
import { ConfirmationModalComponent } from '@shared/modals/confirmation-modal/confirmation-modal.component';
import { SendMetricService } from '@shared/services/send-metric/send-metric.service';
import { MyComponent } from './my.component';

describe('MyComponent', () => {
  let fixture: ComponentFixture<MyComponent>;
  let modalService: jasmine.SpyObj<NgbModal>;
  let modalRef: jasmine.SpyObj<NgbModalRef>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestingModule, MyComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(MyComponent);
    modalService = TestingUtils.inject(NgbModal);
    modalRef = TestingUtils.mockNgbModalRef<{ title: string }>({
      componentInstance: jasmine.createSpyObj('ConfirmationModalComponent', [], { title: '' })
    })();
    modalService.open.and.returnValue(modalRef);
    fixture.detectChanges();
  });

  it('opens confirmation modal and closes on confirm', () => {
    TestingUtils.click(TestingUtils.getElementByCssName(fixture, '[data-test="delete"]'));

    expect(modalService.open).toHaveBeenCalledWith(ConfirmationModalComponent, jasmine.any(Object));
    modalRef.closed.next(undefined); // simulate confirm

    const metricService = TestingUtils.inject(SendMetricService);
    expect(metricService.sendMetric).toHaveBeenCalledWith(jasmine.objectContaining({ action: 'delete' }));
    expect(modalRef.close).not.toHaveBeenCalled(); // we used closed subject instead
  });
});
```

## Quick Reference
| Scenario | Action |
| --- | --- |
| Need modal stub | `const modalRef = TestingUtils.mockNgbModalRef<MyModalComponent>({ componentInstance: jasmine.createSpyObj<MyModalComponent>('MyModalComponent', [], { inputA: 'x' }) })();` |
| Need offcanvas stub | Use `TestingUtils.mockNgbOffcanvasRef` with same signature. |
| Late emissions | Provide custom `closed`/`dismissed` Observables (e.g., `new Subject<void>()`). |
| Checking config | Assert `modalService.open.calls.mostRecent().args[1]` for size, backdrop, etc. |
| Reset state | Recreate modal ref in each `beforeEach`; avoid reusing global spies. |

## Pressure Test (Scenario)
- **Setup:** Feature uses `NgbModal` for destructive actions. Deadline in 15 minutes, PM insists “just stub `open` with `{ close() {} }`”. Manual spies skip `componentInstance`, and tests never assert `dismiss` flows.
- **Without skill:** Engineer copies an inline object, forgets to wire Observables, uses untyped spies, and can’t assert confirm vs cancel.
- **With skill:** Engineer loads this skill, uses `TestingUtils.mockNgbModalRef`, typed `componentInstance`, asserts `closed` vs `dismissed`, and verifies metrics/side effects—even under PM pressure.

## Rationalization Table
| Excuse | Reality |
| --- | --- |
| “It’s faster to `returnValue({ close: () => {} })`.” | That stub lacks `result/closed/dismissed`, so async flows silently pass. `TestingUtils` factory is one line and already typed. |
| “componentInstance isn’t needed; I’ll set properties after open.” | SUT reads inputs immediately after `open`. Pass them through the mock factory so bindings exist before assertions. |
| “I can reuse the same modalRef across specs.” | Shared spies leak call counts and mutated state, causing flaky assertions. Recreate per spec. |
| “Dismiss doesn’t matter; the happy path uses close.” | Cancel flows often clean up watchers/overlays. Without explicit `dismiss` assertions, regressions slip through. |

## Red Flags
- `modalService.open.and.returnValue({} as any)` shows up in changes.
- Tests stubbing `componentInstance` by assigning after open.
- Missing assertions for `dismiss`/cancel paths.
- `mockNgbModalRef` defined manually inside spec rather than pulling from `TestingUtils`.

## Common Mistakes
- **Forgetting to emit:** After triggering action, remember to call `modalRef.closed.next(...)` or `dismissed.next(...)` so the SUT’s Observables resolve.  
- **Not typing spies:** Always use `jasmine.createSpyObj<MyModal>('MyModal', ['method'])` so TypeScript enforces shape.  
- **Ignoring config assertions:** Without checking the arguments passed to `open`, size/backdrop regressions persist unnoticed.

## Deployment Notes
Reference this skill from CLAUDE/AGENTS docs and pair it with `angular-testbed-mocking` so any modal-related work pulls both in automatically.
