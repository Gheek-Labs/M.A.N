import os
import secrets
from flask import Flask, render_template, request, jsonify, make_response

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

@app.after_request
def add_header(response):
    """Add security and cache headers."""
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
    """Lazy-load the agent to avoid import errors at startup."""
    global agent
    if agent is None:
        from providers import get_provider
        from minima_agent import MinimaAgent
        provider = get_provider()
        agent = MinimaAgent(provider)
    return agent

@app.route("/")
def index():
    """Serve the chat interface."""
    return render_template("chat.html")

@app.route("/api/chat", methods=["POST"])
def chat():
    """Handle chat messages."""
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()
        
        if not user_message:
            return jsonify({"error": "Message required"}), 400
        
        agent = get_agent()
        response = agent.chat(user_message)
        
        return jsonify({
            "response": response,
            "provider": agent.provider.get_info()
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/reset", methods=["POST"])
def reset():
    """Reset conversation history."""
    try:
        agent = get_agent()
        agent.reset()
        return jsonify({"status": "ok"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/command", methods=["POST"])
def direct_command():
    """Execute a direct Minima command (restricted to safe read-only commands)."""
    try:
        data = request.get_json()
        command = data.get("command", "").strip()
        
        if not command:
            return jsonify({"error": "Command required"}), 400
        
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
def get_provider_info():
    """Get current LLM provider info."""
    try:
        agent = get_agent()
        return jsonify(agent.provider.get_info())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
