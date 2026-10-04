#!/usr/bin/env python3
import html, re, subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
LOGS = BASE / "logs"

def tail(name, n=10):
    p = LOGS / name
    if not p.exists():
        return []
    return p.read_text(errors="ignore").splitlines()[-n:]

def latest_score():
    for line in reversed(tail("health.log", 50)):
        m = re.search(r"cpu=(\d+)% mem=(\d+)% disk=(\d+)% score=(\d+)", line)
        if m:
            return [int(x) for x in m.groups()]
    return None

def banned():
    try:
        out = subprocess.run(["sudo", "-n", "nft", "list", "set", "inet", "healer", "blacklist"],
                             capture_output=True, text=True).stdout
        m = re.search(r"elements = \{([^}]*)\}", out)
        return [x.strip() for x in m.group(1).split(",")] if m else []
    except Exception:
        return []

def page():
    s = latest_score()
    if s:
        cpu, mem, disk, score = s
        color = "#2e7d32" if score >= 80 else "#f9a825" if score >= 60 else "#c62828"
        top = f'<h1 style="color:{color}">Health score: {score}/100</h1><p>CPU {cpu}% | Memory {mem}% | Disk {disk}%</p>'
    else:
        top = "<h1>No data yet</h1>"
    def block(title, lines):
        body = html.escape("\n".join(lines)) or "(nothing yet)"
        return f"<h2>{title}</h2><pre>{body}</pre>"
    ips = banned()
    return f"""<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="refresh" content="5"><title>Self-Healing Server</title>
<style>body{{font-family:sans-serif;max-width:800px;margin:2em auto;padding:0 1em}}
pre{{background:#111;color:#0f0;padding:1em;overflow-x:auto}}</style></head><body>
{top}{block("Recent recoveries", tail("heal.log"))}
{block("Banned IPs", ips)}{block("Recent health checks", tail("health.log", 5))}
</body></html>"""

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        data = page().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def log_message(self, *a):
        pass

HTTPServer(("127.0.0.1", 8080), H).serve_forever()
