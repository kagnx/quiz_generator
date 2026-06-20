enum AIProvider { claude, openai, gemini, deepseek, ollama }

class AIProviderInfo {
  final AIProvider provider;
  final String displayName;
  final String baseUrl;
  final String defaultModel;
  final bool requiresApiKey;
  final bool isFree;
  final String apiKeyHint;
  final String apiKeyUrl;

  const AIProviderInfo({
    required this.provider,
    required this.displayName,
    required this.baseUrl,
    required this.defaultModel,
    required this.requiresApiKey,
    required this.isFree,
    required this.apiKeyHint,
    required this.apiKeyUrl,
  });
}

const Map<AIProvider, AIProviderInfo> aiProviderInfos = {
  AIProvider.claude: AIProviderInfo(
    provider: AIProvider.claude,
    displayName: 'Claude (Anthropic)',
    baseUrl: 'https://api.anthropic.com/v1/messages',
    defaultModel: 'claude-haiku-3-5-20241022',
    requiresApiKey: true,
    isFree: false,
    apiKeyHint: 'sk-ant-...',
    apiKeyUrl: 'https://console.anthropic.com/api-keys',
  ),
  AIProvider.openai: AIProviderInfo(
    provider: AIProvider.openai,
    displayName: 'ChatGPT (OpenAI)',
    baseUrl: 'https://api.openai.com/v1/chat/completions',
    defaultModel: 'gpt-4o-mini',
    requiresApiKey: true,
    isFree: false,
    apiKeyHint: 'sk-...',
    apiKeyUrl: 'https://platform.openai.com/api-keys',
  ),
  AIProvider.gemini: AIProviderInfo(
    provider: AIProvider.gemini,
    displayName: 'Gemini (Google)',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models',
    defaultModel: 'gemini-1.5-flash',
    requiresApiKey: true,
    isFree: false,
    apiKeyHint: 'AIza...',
    apiKeyUrl: 'https://aistudio.google.com/app/apikey',
  ),
  AIProvider.deepseek: AIProviderInfo(
    provider: AIProvider.deepseek,
    displayName: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1/chat/completions',
    defaultModel: 'deepseek-chat',
    requiresApiKey: true,
    isFree: false,
    apiKeyHint: 'sk-...',
    apiKeyUrl: 'https://platform.deepseek.com/api_keys',
  ),
  AIProvider.ollama: AIProviderInfo(
    provider: AIProvider.ollama,
    displayName: 'Ollama (Ücretsiz/Yerel)',
    baseUrl: 'http://localhost:11434/api/chat',
    defaultModel: 'llama3.2',
    requiresApiKey: false,
    isFree: true,
    apiKeyHint: 'API key gerekmez',
    apiKeyUrl: 'https://ollama.com/download',
  ),
};

class AIProviderConfig {
  final AIProvider provider;
  final String apiKey;
  final String customModel;
  final String ollamaBaseUrl;

  AIProviderConfig({
    required this.provider,
    this.apiKey = '',
    this.customModel = '',
    this.ollamaBaseUrl = 'http://localhost:11434',
  });

  AIProviderInfo get info => aiProviderInfos[provider]!;

  String get effectiveModel =>
      customModel.trim().isNotEmpty ? customModel.trim() : info.defaultModel;

  String get effectiveBaseUrl =>
      provider == AIProvider.ollama ? '$ollamaBaseUrl/api/chat' : info.baseUrl;

  bool get isConfigured => !info.requiresApiKey || apiKey.trim().isNotEmpty;
}
