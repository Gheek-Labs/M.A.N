import os
from typing import List, Dict, Optional
from openai import OpenAI
from .base import LLMProvider


class CustomProvider(LLMProvider):
    """Custom OpenAI-compatible provider (LocalAI, vLLM, LM Studio, etc.)."""
    
    @property
    def default_model(self) -> str:
        return os.environ.get("LLM_MODEL", "default")
    
    @property
    def provider_name(self) -> str:
        return "custom"
    
    def __init__(self, model: Optional[str] = None):
        super().__init__(model)
        
        base_url = os.environ.get("LLM_BASE_URL")
        api_key = os.environ.get("LLM_API_KEY", "not-needed")
        
        if not base_url:
            raise ValueError("LLM_BASE_URL environment variable required for custom provider")
        
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
