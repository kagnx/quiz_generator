import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ai_provider.dart';
import '../services/ai_provider_manager.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _providerManager = AIProviderManager();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _ollamaUrlController = TextEditingController();

  AIProvider _selectedProvider = AIProvider.gemini;
  bool _obscureApiKey = true;
  bool _isConfigured = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProvider(AIProvider.gemini, loadSelected: true);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _ollamaUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProvider(AIProvider provider, {bool loadSelected = false}) async {
    setState(() => _isLoading = true);

    final actualProvider =
        loadSelected ? await _providerManager.getSelectedProvider() : provider;

    final apiKey = await _providerManager.getApiKey(actualProvider);
    final customModel = await _providerManager.getCustomModel(actualProvider);
    final ollamaUrl = await _providerManager.getOllamaBaseUrl();
    final configured = await _providerManager.isProviderConfigured(actualProvider);

    if (!mounted) return;
    setState(() {
      _selectedProvider = actualProvider;
      _apiKeyController.text = apiKey;
      _modelController.text = customModel;
      _ollamaUrlController.text = ollamaUrl;
      _isConfigured = configured;
      _isLoading = false;
    });
  }

  Future<void> _selectProvider(AIProvider provider) async {
    await _saveCurrentProvider(silent: true);
    await _loadProvider(provider);
  }

  Future<void> _saveCurrentProvider({bool silent = false}) async {
    final info = aiProviderInfos[_selectedProvider]!;

    if (info.requiresApiKey) {
      final key = _apiKeyController.text.trim();
      if (key.isNotEmpty) {
        await _providerManager.saveApiKey(_selectedProvider, key);
      }
    } else {
      final url = _ollamaUrlController.text.trim();
      if (url.isNotEmpty) {
        await _providerManager.saveOllamaBaseUrl(url);
      }
    }

    await _providerManager.saveCustomModel(
        _selectedProvider, _modelController.text.trim());
    await _providerManager.setSelectedProvider(_selectedProvider);

    final configured = await _providerManager.isProviderConfigured(_selectedProvider);
    if (!mounted) return;
    setState(() => _isConfigured = configured);

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${info.displayName} kaydedildi')),
      );
    }
  }

  Future<void> _clearApiKey() async {
    await _providerManager.clearApiKey(_selectedProvider);
    setState(() {
      _apiKeyController.clear();
      _isConfigured = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key silindi')),
    );
  }

  Future<void> _openApiKeyUrl() async {
    final url = Uri.parse(aiProviderInfos[_selectedProvider]!.apiKeyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = aiProviderInfos[_selectedProvider]!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveCurrentProvider(silent: true);
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Ayarları'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveCurrentProvider(silent: true);
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Sağlayıcı Seç',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AIProvider.values.map((provider) {
                              final pInfo = aiProviderInfos[provider]!;
                              return ChoiceChip(
                                label: Text(pInfo.displayName),
                                selected: _selectedProvider == provider,
                                onSelected: (_) => _selectProvider(provider),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isConfigured
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: _isConfigured ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(info.displayName,
                                        style: Theme.of(context).textTheme.titleMedium),
                                    Text('Varsayılan model: ${info.defaultModel}',
                                        style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              if (info.isFree)
                                Chip(
                                  label: const Text('ÜCRETSİZ'),
                                  backgroundColor:
                                      Colors.green.withValues(alpha: 0.15),
                                  labelStyle: const TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isConfigured ? 'Yapılandırıldı ✓' : 'API key eksik',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          if (info.requiresApiKey) ...[
                            TextField(
                              controller: _apiKeyController,
                              obscureText: _obscureApiKey,
                              style: const TextStyle(fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                labelText: 'API Key',
                                hintText: info.apiKeyHint,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureApiKey
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () =>
                                      setState(() => _obscureApiKey = !_obscureApiKey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _clearApiKey,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Sil'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _openApiKeyUrl,
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('API Key Al'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            TextField(
                              controller: _ollamaUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Ollama Sunucu URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ollama\'yı bilgisayarınıza kurup telefon ile aynı Wi-Fi\'a '
                              'bağlı olduğunuzda ücretsiz kullanabilirsiniz. '
                              'Bilgisayarınızın yerel IP adresiyle değiştirin '
                              '(örn. http://192.168.1.5:11434).',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _modelController,
                            decoration: InputDecoration(
                              labelText: 'Model (opsiyonel)',
                              hintText: 'Boş bırakırsan: ${info.defaultModel}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _saveCurrentProvider(),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
