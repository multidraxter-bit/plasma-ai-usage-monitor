---
goal: Expand C++ Unit Test Coverage Across Plugin Classes
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: Loofi
status: 'Planned'
tags: [feature, testing, quality, chore]
---

# Introduction

> Historical note (2026-04-09): this plan predates the current test expansion. The repository no longer has only two test files, and GitHub Actions build workflows are currently disabled. Use local `just test` / `ctest --test-dir build --output-on-failure` as the maintained gate.

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

The plasma-ai-usage-monitor plugin originally contained 16 registered C++ QML types but only 2 test files — both covering `UsageDatabase` (series metrics and history mapping regression). This plan documents the original gap analysis that drove the broader unit-test expansion across provider backends, subscription tools, update checking, and cost-estimation behavior.

## 1. Requirements & Constraints

- **REQ-001**: All new tests must use the Qt Test framework (`QTest`) consistent with existing test infrastructure.
- **REQ-002**: Tests must be buildable with the existing CMake/CTest pipeline (`cmake --build build && ctest --test-dir build`).
- **REQ-003**: Tests must not require network access, KWallet, or a running Plasma session — pure unit tests only.
- **REQ-004**: Tests must run in the maintained local CMake/CTest workflow without additional dependencies.
- **SEC-001**: No API keys, credentials, or real user data in test fixtures.
- **CON-001**: Cannot test `refresh()` or network-dependent provider methods without mocking `QNetworkAccessManager` (out of scope for Phase 1).
- **CON-002**: Cannot instantiate abstract classes directly — use minimal concrete subclasses in test files.
- **GUD-001**: Follow existing test patterns: `QTemporaryDir` for isolation, `qputenv("XDG_DATA_HOME", ...)` for DB paths.
- **GUD-002**: Each test file targets one class; test file naming: `test_<classname>.cpp`.
- **PAT-001**: Use `QTEST_MAIN` macro and `.moc` include pattern from existing tests.

## 2. Implementation Steps

### Implementation Phase 1 — ProviderBackend Unit Tests

- GOAL-001: Test all non-virtual, non-network logic in `ProviderBackend` (budget checking, cost estimation, rate limit parsing, generation counter, state transitions).

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Create `plugin/tests/test_providerbackend.cpp` with a minimal concrete `TestProvider` subclass implementing pure virtuals (`name()`, `iconName()`, `refresh()`). | | |
| TASK-002 | Test `setDailyBudget()` / `setMonthlyBudget()` + `checkBudgetLimits()`: verify `budgetWarning` signal at 80% and `budgetExceeded` signal at 100%. Verify dedup flags prevent re-emission. | | |
| TASK-003 | Test `registerModelPricing()` + `updateEstimatedCost()`: register a model, set input/output tokens, call `updateEstimatedCost()`, verify `cost()` and `isEstimatedCost()` return correct values. | | |
| TASK-004 | Test `beginRefresh()` + `isCurrentGeneration()`: verify generation counter increments and stale generations are detected. | | |
| TASK-005 | Test `setConnected()` state transitions: verify `providerDisconnected` emitted on true→false, `providerReconnected` on false→true, no signal on same-state. | | |
| TASK-006 | Test `setError()` / `clearError()`: verify `errorCount` increments, `consecutiveErrors` resets on `clearError()`, signal emission. | | |
| TASK-007 | Test `isRetryableStatus()` static method: verify 429, 500, 502, 503 return true; 200, 400, 401, 404 return false. | | |
| TASK-008 | Test `effectiveBaseUrl()`: verify custom URL takes precedence over default, empty custom URL falls back to default. | | |
| TASK-009 | Register test in `plugin/tests/CMakeLists.txt` with proper link libraries (`Qt6::Core Qt6::Test Qt6::Network`). | | |

### Implementation Phase 2 — SubscriptionToolBackend Unit Tests

- GOAL-002: Test subscription limit calculations, period reset logic, usage counting, and warning/limit signals.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-010 | Create `plugin/tests/test_subscriptiontoolbackend.cpp` with a minimal concrete `TestToolBackend` subclass implementing pure virtuals (`toolName()`, `iconName()`, `toolColor()`, `periodLabel()`, `primaryPeriodType()`, `checkToolInstalled()`, `detectActivity()`, `availablePlans()`, `defaultLimitForPlan()`). | | |
| TASK-011 | Test `incrementUsage()`: verify `usageCount` increments, `percentUsed` calculation, `usageUpdated` signal emission. | | |
| TASK-012 | Test `resetUsage()`: verify `usageCount` resets to 0, `periodStart` updates to current time. | | |
| TASK-013 | Test `limitReached` / `isLimitReached()`: set `usageLimit`, increment to limit, verify `limitReached` signal and `isLimitReached()` returns true. | | |
| TASK-014 | Test `limitWarning` signal: set limit to 100, increment to 80, verify `limitWarning` signal emitted at 80%. | | |
| TASK-015 | Test `calculatePeriodEnd()` for FiveHour, Daily, Weekly, Monthly period types: verify correct end times relative to start. | | |
| TASK-016 | Test secondary usage tracking: set secondary limit, increment secondary count, verify `secondaryPercentUsed` and `isSecondaryLimitReached()`. | | |
| TASK-017 | Test `checkAndResetPeriod()`: set period start in the past beyond period duration, trigger check, verify usage resets and period start updates. | | |
| TASK-018 | Register test in `plugin/tests/CMakeLists.txt`. | | |

### Implementation Phase 3 — UpdateChecker Unit Tests

- GOAL-003: Test version comparison logic and property setters/signals without network calls.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-019 | Create `plugin/tests/test_updatechecker.cpp`. | | |
| TASK-020 | Test `setCurrentVersion()`: verify property getter, signal emission, version string normalization (strip "v" prefix). | | |
| TASK-021 | Test `setCheckIntervalHours()`: verify property getter, signal emission, timer interval update. | | |
| TASK-022 | Register test in `plugin/tests/CMakeLists.txt`. | | |

### Implementation Phase 4 — UsageDatabase Extended Tests

- GOAL-004: Expand existing `UsageDatabase` tests to cover edge cases and untested methods.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-023 | Test `pruneOldData()`: insert records with old timestamps, set retention to 1 day, prune, verify old data removed and recent data retained. | | |
| TASK-024 | Test `setRetentionDays()` clamping: verify values < 1 are clamped to 1 and values > 365 are clamped to 365. | | |
| TASK-025 | Test `exportCsv()`: insert known data, export, verify CSV format with correct headers and values. | | |
| TASK-026 | Test `exportJson()`: insert known data, export, parse JSON, verify structure and values. | | |
| TASK-027 | Test `getProviders()` / `getToolNames()`: insert data for multiple providers/tools, verify returned lists. | | |
| TASK-028 | Test `getSummary()`: insert known snapshots, verify totalCost, avgDailyCost, maxDailyCost, totalRequests, peakTokenUsage, snapshotCount. | | |
| TASK-029 | Test `getDailyCosts()`: insert snapshots across multiple days, verify aggregation per day. | | |
| TASK-030 | Test write throttling: call `recordSnapshot()` twice within 60 seconds with same cost, verify second write is skipped. | | |
| TASK-031 | Add new test entries to `plugin/tests/CMakeLists.txt`. | | |

### Implementation Phase 5 — CI Validation

- GOAL-005: Verify all new tests pass in CI and document test running instructions.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-032 | Run full test suite locally: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build --parallel && ctest --test-dir build --output-on-failure`. | | |
| TASK-033 | Verify the maintained local CTest workflow runs `ctest` and new tests are picked up automatically. | | |
| TASK-034 | Update `README.md` "Run Tests" section if any new instructions are needed. | | |

## 3. Alternatives

- **ALT-001**: Use Google Test (GTest) instead of Qt Test — rejected because the project already uses Qt Test and adding a second test framework would increase build complexity.
- **ALT-002**: Mock `QNetworkAccessManager` for full integration tests of provider `refresh()` — rejected for Phase 1 due to complexity; could be a follow-up plan.
- **ALT-003**: Use QML testing (`qmltest`) for frontend tests — out of scope for this plan which focuses on C++ plugin logic.

## 4. Dependencies

- **DEP-001**: `Qt6::Test` — already listed as a build dependency when `BUILD_TESTING` is ON.
- **DEP-002**: `Qt6::Network` — needed for `ProviderBackend` tests (linking, not actual network calls).
- **DEP-003**: Existing `plugin/tests/CMakeLists.txt` — tests must be registered here for CTest discovery.

## 5. Files

- **FILE-001**: `plugin/tests/test_providerbackend.cpp` — New test file for ProviderBackend unit tests.
- **FILE-002**: `plugin/tests/test_subscriptiontoolbackend.cpp` — New test file for SubscriptionToolBackend unit tests.
- **FILE-003**: `plugin/tests/test_updatechecker.cpp` — New test file for UpdateChecker unit tests.
- **FILE-004**: `plugin/tests/test_usagedatabase_extended.cpp` — New test file for extended UsageDatabase tests.
- **FILE-005**: `plugin/tests/CMakeLists.txt` — Modified to register all new test executables and CTest entries.

## 6. Testing

- **TEST-001**: `test_providerbackend` — Validates budget signals, cost estimation, generation counter, state transitions, error tracking, and URL override logic.
- **TEST-002**: `test_subscriptiontoolbackend` — Validates usage counting, limit checking, period resets, warning signals, and secondary limit tracking.
- **TEST-003**: `test_updatechecker` — Validates version property setters, normalization, and signal emission.
- **TEST-004**: `test_usagedatabase_extended` — Validates pruning, export, summary aggregation, daily costs, throttling, and retention clamping.
- **TEST-005**: Local gate — All tests pass in `ctest --test-dir build --output-on-failure`.

## 7. Risks & Assumptions

- **RISK-001**: `ProviderBackend` and `SubscriptionToolBackend` are abstract classes with protected members. Tests require concrete subclasses to access protected setters, which adds boilerplate. Mitigated by keeping test subclasses minimal.
- **RISK-002**: Budget dedup flags (`m_dailyWarningEmitted`, etc.) are private with no public reset API. Tests may need to rely on constructing fresh instances per test case.
- **RISK-003**: `checkAndResetPeriod()` is protected in `SubscriptionToolBackend`. Test subclass must expose it via a public wrapper.
- **ASSUMPTION-001**: The maintained local workflow runs `cmake --build` with `BUILD_TESTING=ON` and `ctest`, so new tests will be automatically discovered.
- **ASSUMPTION-002**: All target classes can be instantiated without a running Plasma session or KWallet daemon when only testing non-network/non-wallet code paths.

## 8. Related Specifications / Further Reading

- [Qt Test Framework Documentation](https://doc.qt.io/qt-6/qttest-index.html)
- [CMake CTest Documentation](https://cmake.org/cmake/help/latest/manual/ctest.1.html)
- Existing tests: `plugin/tests/test_usagedatabase_series.cpp`, `plugin/tests/test_history_mapping_regression.cpp`
- Maintained verification path: local `just test` / `ctest --test-dir build --output-on-failure`
