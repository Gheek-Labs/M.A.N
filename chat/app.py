import os
import sys
import time
import secrets
import hashlib
import functools
from collections import defaultdict
from flask import Flask, render_template, request, jsonify, session, redirect, url_for

ENABLE_CHAT = os.environ.get("ENABLE_CHAT", "false").lower() in ("true", "1", "yes")
CHAT_PASSWORD = os.environ.get("CHAT_PASSWORD", "")
CHAT_BIND = os.environ.get("CHAT_BIND", "127.0.0.1")
FLASK_DEBUG = os.environ.get("FLASK_DEBUG", "false").lower() in ("true", "1", "yes")
MAX_MESSAGE_LENGTH = 2000
RATE_LIMIT_REQUESTS = 20
RATE_LIMIT_WINDOW = 60

if not ENABLE_CHAT:
    print("")
    print("=" * 50)
    print("  Minima Chat is DISABLED (default)")
    print("=" * 50)
    print("")
    print("To enable, set the environment variable:")
    print("  ENABLE_CHAT=true")
    print("")
    print("You must also set a password:")
    print("  CHAT_PASSWORD=<your-password>")
    print("")
    print("Optional:")
    print("  CHAT_BIND=0.0.0.0    (to allow remote access)")
    print("  FLASK_DEBUG=true     (development only)")
    print("")
    sys.exit(0)

if not CHAT_PASSWORD:
    print("")
    print("ERROR: CHAT_PASSWORD is required when chat is enabled.")
    print("Set a strong password via environment variable or secrets.")
    print("")
    sys.exit(1)

if len(CHAT_PASSWORD) < 8:
    print("")
    print("ERROR: CHAT_PASSWORD must be at least 8 characters.")
    print("")
    sys.exit(1)

app = Flask(__name__)

_secret_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".session_secret")

def _get_session_secret():
    env_secret = os.environ.get("SESSION_SECRET")
    if env_secret:
        return env_secret
    if os.path.exists(_secret_file):
        with open(_secret_file, "r") as f:
            return f.read().strip()
    generated = secrets.token_hex(32)
    with open(_secret_file, "w") as f:
        f.write(generated)
    os.chmod(_secret_file, 0o600)
    return generated

app.secret_key = _get_session_secret()
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

_rate_limits = defaultdict(list)

def _check_rate_limit(client_ip):
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW
    _rate_limits[client_ip] = [t for t in _rate_limits[client_ip] if t > window_start]
    if len(_rate_limits[client_ip]) >= RATE_LIMIT_REQUESTS:
        return False
    _rate_limits[client_ip].append(now)
    return True

def _password_hash(password):
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def require_auth(f):
    @functools.wraps(f)
    def decorated(*args, **kwargs):
        if session.get("authenticated") != _password_hash(CHAT_PASSWORD):
            if request.is_json:
                return jsonify({"error": "Authentication required"}), 401
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated

@app.after_request
def add_header(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data:; "
        "connect-src 'self'; "
        "frame-ancestors 'self' https://*.replit.dev https://*.repl.co"
    )
    return response

agent = None

def get_agent():
    global agent
    if agent is None:
        from providers import get_provider
        from minima_agent import MinimaAgent
        provider = get_provider()
        agent = MinimaAgent(provider)
    return agent

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        password = request.form.get("password", "")
        if password == CHAT_PASSWORD:
            session["authenticated"] = _password_hash(CHAT_PASSWORD)
            return redirect(url_for("index"))
        return render_template("login.html", error="Incorrect password"), 401
    return render_template("login.html", error=None)

@app.route("/logout", methods=["POST"])
def logout():
    session.clear()
    return redirect(url_for("login"))

@app.route("/")
@require_auth
def index():
    return render_template("chat.html")

@app.route("/api/chat", methods=["POST"])
@require_auth
def chat():
    try:
        client_ip = request.remote_addr or "unknown"
        if not _check_rate_limit(client_ip):
            return jsonify({"error": "Rate limit exceeded. Please wait before sending more messages."}), 429

        data = request.get_json()
        user_message = data.get("message", "").strip()

        if not user_message:
            return jsonify({"error": "Message required"}), 400

        if len(user_message) > MAX_MESSAGE_LENGTH:
            return jsonify({"error": f"Message too long. Maximum {MAX_MESSAGE_LENGTH} characters."}), 400

        agent = get_agent()
        response = agent.chat(user_message)

        return jsonify({
            "response": response,
            "provider": agent.provider.get_info()
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/reset", methods=["POST"])
@require_auth
def reset():
    try:
        agent = get_agent()
        agent.reset()
        return jsonify({"status": "ok"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/command", methods=["POST"])
@require_auth
def direct_command():
    try:
        client_ip = request.remote_addr or "unknown"
        if not _check_rate_limit(client_ip):
            return jsonify({"error": "Rate limit exceeded."}), 429

        data = request.get_json()
        command = data.get("command", "").strip()

        if not command:
            return jsonify({"error": "Command required"}), 400

        if len(command) > MAX_MESSAGE_LENGTH:
            return jsonify({"error": "Command too long."}), 400

        from minima_agent import execute_command, is_safe_command

        if not is_safe_command(command):
            return jsonify({
                "error": "Command not allowed via direct API. Use the chat interface for transaction commands.",
                "status": False
            }), 403

        result = execute_command(command)
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/provider", methods=["GET"])
@require_auth
def get_provider_info():
    try:
        agent = get_agent()
        return jsonify(agent.provider.get_info())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/health")
def health():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    print(f"Chat binding to {CHAT_BIND}:5000 (debug={FLASK_DEBUG})")
    app.run(host=CHAT_BIND, port=5000, debug=FLASK_DEBUG)
