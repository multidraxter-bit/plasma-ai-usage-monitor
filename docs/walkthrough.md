# Sprint 1 — Documentation & UX Walkthrough

## What Changed

### Documentation (3 files)

| File | Change |
|------|--------|
| [CHANGELOG.md](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/CHANGELOG.md) | **[NEW]** Full version history v1.0.0→v2.8.1and comparison links |
| [SECURITY.md](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/SECURITY.md) | **[NEW]** Security policy, reporting, design decisions |
| [README.md](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/README.md) | Added Documentation section with doc links; trimmed inline changelog to latest release only |

### UX Improvements (4 files)

| File | Change |
|------|--------|
| [FullRepresentation.qml](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/package/contents/ui/FullRepresentation.qml) | Enhanced first-run welcome message (warmer text, better icon) |
| [configProviders.qml](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/package/contents/ui/configProviders.qml) | Added `isInvalidUrl()` validator + inline warnings for malformed URLs; tooltips on model filter and base URL fields |
| [configGeneral.qml](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/package/contents/ui/configGeneral.qml) | Tooltips on refresh interval slider and panel display mode |
| [configBudget.qml](file:///home/loofi/plasma-ai-usage-monitor/plasma-ai-usage-monitor/package/contents/ui/configBudget.qml) | Tooltip on budget warning threshold slider |

## Validation

- **Build**: Clean compile, 100% targets built ✅
- **Tests**: 5/5 CTest targets pass ✅
  - `appstreamtest`, `usagedatabase_series`, `history_mapping_regression`, `version_consistency`, `no_hardcoded_versions`

## Remaining Sprint 1 Items

- [ ] Improve browser sync error messages
- [ ] Provider unit tests (mocked HTTP)
- [ ] Subscription tool unit tests
- [ ] `clang-tidy` CI gate
