import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ai_provider.dart';

/// Provider seçimi ve model tercihleri normal SharedPreferences'ta,
/// API key'ler ise flutter_secure_storage ile şifreli saklanır.
/// (Android: EncryptedSharedPreferences/Keystore, iOS: Keychain)
class AIProviderManager {
  static const _keySelectedProvider = 'selected_provider';
  static const _keyCustomModelPrefix = 'custom_model_';
  static const _keyOllamaUrl = 'ollama_base_url';
  static const _keyApiKeyPrefix = 'api_key_';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<AIProvider> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keySelectedProvider);
    return AIProvider.values.firstWhere(
      (p) => p.name == name,
      orElse: () => AIProvider.gemini,
    );
  }

  Future<void> setSelectedProvider(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedProvider, provider.name);
  }

  Future<String> getApiKey(AIProvider provider) async {
    return await _secureStorage.read(key: '$_keyApiKeyPrefix${provider.name}') ?? '';
  }

  Future<void> saveApiKey(AIProvider provider, String apiKey) async {
    await _secureStorage.write(
      key: '$_keyApiKeyPrefix${provider.name}',
      value: apiKey,
    );
  }

  Future<void> clearApiKey(AIProvider provider) async {
    await _secureStorage.delete(key: '$_keyApiKeyPrefix${provider.name}');
  }

  Future<String> getCustomModel(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyCustomModelPrefix${provider.name}') ?? '';
  }

  Future<void> saveCustomModel(AIProvider provider, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyCustomModelPrefix${provider.name}', model);
  }

  Future<String> getOllamaBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOllamaUrl) ?? 'http://localhost:11434';
  }

  Future<void> saveOllamaBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOllamaUrl, url);
  }

  Future<AIProviderConfig> getCurrentConfig() async {
    final provider = await getSelectedProvider();
    return AIProviderConfig(
      provider: provider,
      apiKey: await getApiKey(provider),
      customModel: await getCustomModel(provider),
      ollamaBaseUrl: await getOllamaBaseUrl(),
    );
  }

  Future<bool> isProviderConfigured(AIProvider provider) async {
    final info = aiProviderInfos[provider]!;
    if (!info.requiresApiKey) return true;
    final key = await getApiKey(provider);
    return key.trim().isNotEmpty;
  }

  Future<List<AIProvider>> getConfiguredProviders() async {
    final result = <AIProvider>[];
    for (final provider in AIProvider.values) {
      if (await isProviderConfigured(provider)) {
        result.add(provider);
      }
    }
    return result;
  }
}
