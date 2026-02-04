import os
import httpx
from typing import List, Dict, Optional
from .base import LLMProvider


class OllamaProvider(LLMProvider):
    """Ollama provider for local LLM inference."""
    
    @property
    def default_model(self) -> str:
        return "llama3.2"
    
    @property
    def provider_name(self) -> str:
        return "ollama"
    
    def __init__(self, model: Optional[str] = None):
        super().__init__(model)
        self.base_url = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")
    
    def chat(self, messages: List[Dict[str, str]], system_prompt: str) -> str:
        full_messages = [{"role": "system", "content": system_prompt}] + messages
        
        response = httpx.post(
            f"{self.base_url}/api/chat",
            json={
                "model": self.model,
                "messages": full_messages,
                "stream": False,
            },
            timeout=120.0,
        )
        response.raise_for_status()
        
        return response.json()["message"]["content"]
