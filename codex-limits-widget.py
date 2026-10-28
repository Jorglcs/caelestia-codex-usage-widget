#!/usr/bin/env python3
"""Consulta apenas os limites da conta usando o protocolo local do Codex."""
import json
import subprocess
import sys

try:
    with subprocess.Popen(["codex", "app-server"], stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                          text=True) as process:
        def send(message):
            process.stdin.write(json.dumps(message) + "\n")
            process.stdin.flush()

        send({"id": 1, "method": "initialize", "params": {"clientInfo": {"name": "caelestia_codex_usage", "version": "1.0"}}})
        for line in process.stdout:
            if json.loads(line).get("id") == 1:
                break
        send({"method": "initialized"})
        send({"id": 2, "method": "account/rateLimits/read"})
        for line in process.stdout:
            response = json.loads(line)
            if response.get("id") == 2:
                limits = response.get("result", {}).get("rateLimits", {})
                print(json.dumps({"primary": limits.get("primary"), "secondary": limits.get("secondary")}))
                break
        process.terminate()
except Exception:
    print("{}")
    sys.exit(1)
