#!/usr/bin/env python3
"""Mock AI usage endpoints for screenshot-safe Plasma demo sessions."""

from __future__ import annotations

import argparse
import json
import re
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PRESET = SCRIPT_DIR / "showcase_preset.json"


def _json_bytes(payload: dict[str, Any]) -> bytes:
    return json.dumps(payload, separators=(",", ":")).encode("utf-8")


class DemoData:
    def __init__(self, payload: dict[str, Any]) -> None:
        self.payload = payload

    @classmethod
    def from_path(cls, path: Path) -> "DemoData":
        return cls(json.loads(path.read_text(encoding="utf-8")))

    def provider(self, name: str) -> dict[str, Any]:
        return self.payload[name]


class DemoRequestHandler(BaseHTTPRequestHandler):
    demo_data: DemoData

    def _send_json(
        self,
        payload: dict[str, Any],
        *,
        status: HTTPStatus = HTTPStatus.OK,
        headers: dict[str, str] | None = None,
    ) -> None:
        body = _json_bytes(payload)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        if headers:
            for key, value in headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)

    def _send_not_found(self) -> None:
        self._send_json({"error": "not found", "path": self.path}, status=HTTPStatus.NOT_FOUND)

    def _openai_headers(self, provider_name: str) -> dict[str, str]:
        provider = self.demo_data.provider(provider_name)
        headers = provider.get("headers", {})
        return {
            "x-ratelimit-limit-requests": str(headers.get("requests_limit", 100)),
            "x-ratelimit-remaining-requests": str(headers.get("requests_remaining", 80)),
            "x-ratelimit-limit-tokens": str(headers.get("tokens_limit", 250000)),
            "x-ratelimit-remaining-tokens": str(headers.get("tokens_remaining", 240000)),
        }

    def do_GET(self) -> None:  # noqa: N802 - stdlib hook name
        if self.path == "/healthz":
            self._send_json({"status": "ok"})
            return

        if self.path == "/mock/openai/v1/organization/usage/completions":
            usage = self.demo_data.provider("openai")["usage"]
            self._send_json(
                {"data": [{"result": [usage]}]},
                headers={
                    "x-ratelimit-limit-requests": "120",
                    "x-ratelimit-remaining-requests": "94",
                    "x-ratelimit-limit-tokens": "500000",
                    "x-ratelimit-remaining-tokens": "475400",
                    "x-ratelimit-reset-requests": "30s",
                },
            )
            return

        if self.path == "/mock/openai/v1/organization/costs":
            amount = self.demo_data.provider("openai")["cost"]["amount"]
            self._send_json({"data": [{"result": [{"amount": amount}]}]})
            return

        if self.path == "/mock/deepseek/user/balance":
            balance = self.demo_data.provider("deepseek")["balance"]
            self._send_json({"is_available": True, "balance_infos": [{"total_balance": str(balance)}]})
            return

        if self.path == "/mock/openrouter/auth/key":
            credits = self.demo_data.provider("openrouter")["credits"]
            self._send_json({"data": {"label": "demo-key", "usage": credits["usage"], "limit": credits["limit"]}})
            return

        if self.path == "/mock/loofi/api/v2/metrics-summary":
            self._send_json(self.demo_data.provider("loofi"))
            return

        google_model = re.fullmatch(r"/mock/google/v1beta/models/(?P<model>[^:]+):countTokens", self.path)
        if google_model:
            total_tokens = self.demo_data.provider("google")["total_tokens"]
            self._send_json({"model": google_model.group("model"), "totalTokens": total_tokens})
            return

        google_veo_model = re.fullmatch(r"/mock/googleveo/v1beta/models/(?P<model>[^/]+)", self.path)
        if google_veo_model:
            payload = self.demo_data.provider("googleveo")
            headers = {
                "x-ratelimit-limit-requests": str(payload["headers"]["requests_limit"]),
                "x-ratelimit-remaining-requests": str(payload["headers"]["requests_remaining"]),
            }
            self._send_json(
                {
                    "name": google_veo_model.group("model"),
                    "displayName": "Veo demo model",
                    "usage": payload["usage"],
                },
                headers=headers,
            )
            return

        self._send_not_found()

    def do_POST(self) -> None:  # noqa: N802 - stdlib hook name
        path_map = {
            "/mock/anthropic/v1/messages/count_tokens": "anthropic",
            "/mock/mistral/chat/completions": "mistral",
            "/mock/deepseek/chat/completions": "deepseek",
            "/mock/groq/chat/completions": "groq",
            "/mock/xai/chat/completions": "xai",
            "/mock/openrouter/chat/completions": "openrouter",
            "/mock/together/chat/completions": "together",
            "/mock/cohere/chat/completions": "cohere",
        }

        if self.path in path_map:
            provider_name = path_map[self.path]
            provider = self.demo_data.provider(provider_name)
            if provider_name == "anthropic":
                headers = provider["headers"]
                self._send_json(
                    {},
                    headers={
                        "anthropic-ratelimit-requests-limit": str(headers["requests_limit"]),
                        "anthropic-ratelimit-requests-remaining": str(headers["requests_remaining"]),
                        "anthropic-ratelimit-input-tokens-limit": str(headers["input_tokens_limit"]),
                        "anthropic-ratelimit-input-tokens-remaining": str(headers["input_tokens_remaining"]),
                        "anthropic-ratelimit-output-tokens-limit": str(headers["output_tokens_limit"]),
                        "anthropic-ratelimit-output-tokens-remaining": str(headers["output_tokens_remaining"]),
                        "anthropic-ratelimit-requests-reset": str(headers["reset"]),
                    },
                )
                return

            self._send_json({"usage": provider["usage"]}, headers=self._openai_headers(provider_name))
            return

        azure_match = re.fullmatch(
            r"/mock/azure/openai/deployments/(?P<deployment>[^/]+)/chat/completions", self.path
        )
        if azure_match:
            provider = self.demo_data.provider("azure")
            self._send_json(
                {
                    "id": f"chatcmpl-{azure_match.group('deployment')}",
                    "object": "chat.completion",
                    "usage": provider["usage"],
                    "cost": provider["cost"],
                },
                headers={
                    "x-ratelimit-limit-requests": str(provider["headers"]["requests_limit"]),
                    "x-ratelimit-remaining-requests": str(provider["headers"]["requests_remaining"]),
                    "x-ratelimit-limit-tokens": str(provider["headers"]["tokens_limit"]),
                    "x-ratelimit-remaining-tokens": str(provider["headers"]["tokens_remaining"]),
                    "x-ratelimit-reset-requests": "25s",
                },
            )
            return

        self._send_not_found()

    def log_message(self, fmt: str, *args: Any) -> None:
        return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="Host interface to bind")
    parser.add_argument("--port", type=int, default=8787, help="Port to bind")
    parser.add_argument("--preset", type=Path, default=DEFAULT_PRESET, help="Path to the JSON preset file")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    demo_data = DemoData.from_path(args.preset)
    handler = type("ConfiguredDemoRequestHandler", (DemoRequestHandler,), {"demo_data": demo_data})
    server = ThreadingHTTPServer((args.host, args.port), handler)
    base_url = f"http://{server.server_address[0]}:{server.server_address[1]}"

    print(f"Mock AI usage server running on {base_url}")
    print(f"OpenAI base URL:     {base_url}/mock/openai/v1")
    print(f"Anthropic base URL:  {base_url}/mock/anthropic/v1")
    print(f"Google base URL:     {base_url}/mock/google/v1beta")
    print(f"Google Veo base URL: {base_url}/mock/googleveo/v1beta")
    print(f"Azure base URL:      {base_url}/mock/azure")
    print("OpenAI-compatible providers can point to /mock/<provider>")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
