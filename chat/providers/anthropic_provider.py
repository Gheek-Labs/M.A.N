import os
from typing import List, Dict, Optional
from .base import LLMProvider


class AnthropicProvider(LLMProvider):
    """Anthropic Claude provider."""
    
    @property
    def default_model(self) -> str:
        return "claude-sonnet-4-20250514"
    
    @property
    def provider_name(self) -> str:
        return "anthropic"
    
    def __init__(self, model: Optional[str] = None):
        super().__init__(model)
        
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY environment variable not set")
        
        try:
            import anthropic
            self.client = anthropic.Anthropic(api_key=api_key)
        except ImportError:
            raise ImportError("anthropic package not installed. Run: pip install anthropic")
    
    def chat(self, messages: List[Dict[str, str]], system_prompt: str) -> str:
        response = self.client.messages.create(
            model=self.model,
            max_tokens=2048,
            system=system_prompt,
            messages=messages,
        )
        
        return response.content[0].text
