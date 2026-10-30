---
description: Analyze Flutter test coverage and add high-value tests
agent: tdd-guide
subagent: true
---

# Parentify Coverage

Analyze coverage and close the highest-value gaps: $ARGUMENTS

## Steps

1. Run:
   ```bash
   flutter test --coverage
   ```
2. Read `coverage/lcov.info` and compute per-file line coverage.
3. Identify the weakest files, prioritizing:
   - authentication and onboarding flows
   - parenting/child data handling
   - payment or subscription logic (if present)
   - state management (Cubit/Notifier/Provider) before UI widgets
   - utility functions
4. Add tests for the highest-value gaps, following the existing `test/` structure and helpers.
5. Re-run `flutter test --coverage` and report the change.

## Targets

| Code | Target |
|---|---|
| Standard code | 80% |
| Auth / security | 100% |
| Payments | 100% |
| Utilities | 90% |
| Widgets | 70% |

## Report

### Summary
- Overall line coverage: XX% (before -> after)
- Tests added: N

### Weakest files
| File | Coverage | Priority |
|---|---|---|

### Notes
List gaps you intentionally left and why.

Coverage is a signal, not a goal. Prefer meaningful behavior tests over hitting a number.
