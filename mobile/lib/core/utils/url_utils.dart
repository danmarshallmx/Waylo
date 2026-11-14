import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  /// Launches a URL in the default external browser.
  static Future<bool> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Builds an affiliate URL with tracking parameters.
  static String buildAffiliateUrl({
    required String baseUrl,
    required String affiliateId,
    Map<String, String>? extraParams,
  }) {
    final uri = Uri.parse(baseUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['aff_id'] = affiliateId;
    queryParams['utm_source'] = 'waylo';
    queryParams['utm_medium'] = 'app';
    if (extraParams != null) {
      queryParams.addAll(extraParams);
    }
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Formats a URL for display (removes protocol and trailing slash).
  static String formatForDisplay(String url) {
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }
}
