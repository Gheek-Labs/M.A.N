import os
from typing import List, Dict, Optional
from openai import OpenAI
from .base import LLMProvider


class OpenAIProvider(LLMProvider):
    """OpenAI provider using Replit AI Integrations or direct API."""
    
    @property
    def default_model(self) -> str:
        return "gpt-4o-mini"
    
    @property
    def provider_name(self) -> str:
        return "openai"
    
    def __init__(self, model: Optional[str] = None):
        super().__init__(model)
        
        base_url = os.environ.get("AI_INTEGRATIONS_OPENAI_BASE_URL") or os.environ.get("OPENAI_BASE_URL")
        api_key = os.environ.get("AI_INTEGRATIONS_OPENAI_API_KEY") or os.environ.get("OPENAI_API_KEY")
        
        if not api_key:
            raise ValueError("OpenAI API key not found. Set OPENAI_API_KEY or use Replit AI Integrations.")
        
        self.client = OpenAI(
            api_key=api_key,
            base_url=base_url,
        )
    
    def chat(self, messages: List[Dict[str, str]], system_prompt: str) -> str:
        full_messages = [{"role": "system", "content": system_prompt}] + messages
        
        response = self.client.chat.completions.create(
            model=self.model,
            messages=full_messages,
            temperature=0.7,
            max_tokens=2048,
        )
        
        return response.choices[0].message.content
