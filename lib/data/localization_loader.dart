part of carp_study_app;

/// A [LocalizationLoader] that knows how to load localizations from a
/// [LocalizationManager].
class ResourceLocalizationLoader implements LocalizationLoader {
  final LocalizationManager localizationManager;
  ResourceLocalizationLoader(this.localizationManager);

  @override
  Future<Map<String, String>> load(Locale locale) async {
    Map<String, String> translations = {};
    // if using the CARP resource mananger, the initial call to load will
    // fail since the user is not authenticated - but will be available on re-load
    try {
      translations = await localizationManager.getLocalizations(locale) ?? {};
      print("$runtimeType - translations for ´$locale' loaded.");
    } catch (error) {
      print(
          "$runtimeType - could not load translations for '$locale' - $error");
    }

    return translations;
  }
}
