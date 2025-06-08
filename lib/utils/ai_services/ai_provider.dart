enum AIProvider { openAI, google, deepInfra }

extension AIProviderX on AIProvider {
  String get name => switch (this) {
    AIProvider.openAI => 'OpenAI',
    AIProvider.google => 'Google PaLM',
    AIProvider.deepInfra => 'DeepInfra',
  };
}
