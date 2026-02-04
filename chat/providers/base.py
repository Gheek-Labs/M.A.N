from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional


class LLMProvider(ABC):
    """Abstract base class for LLM providers."""
    
    def __init__(self, model: Optional[str] = None):
        self.model = model or self.default_model
    
    @property
    @abstractmethod
    def default_model(self) -> str:
        """Default model to use if none specified."""
        pass
    
    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Name of the provider."""
        pass
    
    @abstractmethod
    def chat(self, messages: List[Dict[str, str]], system_prompt: str) -> str:
        """
        Send chat messages to the LLM and get a response.
        
        Args:
            messages: List of message dicts with 'role' and 'content' keys
            system_prompt: System prompt to set context
            
        Returns:
            The assistant's response text
        """
        pass
    
    def get_info(self) -> Dict[str, Any]:
        """Get provider information."""
        return {
            "provider": self.provider_name,
            "model": self.model,
        }
