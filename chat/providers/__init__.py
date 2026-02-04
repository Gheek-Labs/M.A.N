from .base import LLMProvider
from .openai_provider import OpenAIProvider
from .anthropic_provider import AnthropicProvider
from .ollama_provider import OllamaProvider
from .custom_provider import CustomProvider

def get_provider(provider_name: str = None) -> LLMProvider:
    """Get LLM provider based on environment configuration."""
    import os
    
    provider = provider_name or os.environ.get("LLM_PROVIDER", "openai")
    model = os.environ.get("LLM_MODEL")
    
    if provider == "openai":
        return OpenAIProvider(model=model)
    elif provider == "anthropic":
        return AnthropicProvider(model=model)
    elif provider == "ollama":
        return OllamaProvider(model=model)
    elif provider == "custom":
        return CustomProvider(model=model)
    else:
        raise ValueError(f"Unknown LLM provider: {provider}")

__all__ = [
    "LLMProvider",
    "OpenAIProvider", 
    "AnthropicProvider",
    "OllamaProvider",
    "CustomProvider",
    "get_provider",
]
