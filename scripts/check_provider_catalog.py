#!/usr/bin/env python3
import json
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "package/contents/catalog/providers-v2.json"
EXPECTED_KEYS = {
    "openai", "anthropic", "google", "mistral", "deepseek", "groq", "xai",
    "ollama", "openrouter", "together", "cohere", "googleveo", "azure",
    "bedrock", "loofi",
}


def fail(message):
    print(f"Provider catalog check FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def main():
    if not CATALOG.exists():
        fail(f"missing {CATALOG}")

    try:
        catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON: {exc}")

    if catalog.get("schemaVersion") != 2:
        fail("schemaVersion must be 2")
    if catalog.get("runtimeScraping") is not False:
        fail("runtimeScraping must be false")

    reviewed = catalog.get("lastReviewed", "")
    try:
        reviewed_date = date.fromisoformat(reviewed)
    except ValueError:
        fail("lastReviewed must be ISO date YYYY-MM-DD")

    if (date.today() - reviewed_date).days > 120:
        fail(f"catalog lastReviewed is stale: {reviewed}")

    providers = catalog.get("providers")
    if not isinstance(providers, list):
        fail("providers must be a list")

    seen = set()
    for provider in providers:
        key = provider.get("key")
        if not key:
            fail("provider missing key")
        if key in seen:
            fail(f"duplicate provider key: {key}")
        seen.add(key)

        for field in ("label", "dataQuality", "pricingFreshness"):
            if not provider.get(field):
                fail(f"{key} missing {field}")

        models = provider.get("models")
        if not isinstance(models, list):
            fail(f"{key} models must be a list")
        if key != "loofi" and not models:
            fail(f"{key} must declare at least one model")

        for model in models:
            for field in ("id", "inputPerMillion", "outputPerMillion"):
                if field not in model:
                    fail(f"{key} model missing {field}")
            if model["inputPerMillion"] < 0 or model["outputPerMillion"] < 0:
                fail(f"{key} model prices must be non-negative")

    missing = EXPECTED_KEYS - seen
    extra = seen - EXPECTED_KEYS
    if missing:
        fail(f"missing provider keys: {', '.join(sorted(missing))}")
    if extra:
        fail(f"unexpected provider keys: {', '.join(sorted(extra))}")

    print(f"Provider catalog check OK: {len(providers)} providers, reviewed {reviewed}")


if __name__ == "__main__":
    main()
