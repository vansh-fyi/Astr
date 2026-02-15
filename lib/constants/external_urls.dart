/// External URLs for the Astr app
class ExternalUrls {
  ExternalUrls._();

  /// Ko-fi support page
  static const String kofiSupport = 'https://ko-fi.com/vanshgrover';

  /// Privacy policy (required by App Store & Play Store)
  static const String privacyPolicy = 'https://astr.app/privacy';

  /// Terms of service
  static const String termsOfService = 'https://astr.app/terms';

  @Deprecated('Use kofiSupport instead')
  static const String buyMeACoffee = kofiSupport;
}
