import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/core/utils/url_utils.dart';
import 'package:waylo/features/planning/repositories/planning_repository.dart';

void main() {
  group('Planning & Smart Deep Linking Tests', () {
    test('UrlUtils.buildAffiliateUrl embeds tracking params and affiliate ID correctly', () {
      final generated = UrlUtils.buildAffiliateUrl(
        baseUrl: 'https://www.booking.com/searchresults.html',
        affiliateId: 'waylo_travel_pro',
        extraParams: {
          'ss': 'Liverpool',
          'checkin': '2026-12-01',
          'checkout': '2026-12-07',
          'group_adults': '2',
        },
      );

      final uri = Uri.parse(generated);
      expect(uri.host, 'www.booking.com');
      expect(uri.queryParameters['aff_id'], 'waylo_travel_pro');
      expect(uri.queryParameters['utm_source'], 'waylo');
      expect(uri.queryParameters['utm_medium'], 'app');
      expect(uri.queryParameters['ss'], 'Liverpool');
      expect(uri.queryParameters['checkin'], '2026-12-01');
      expect(uri.queryParameters['group_adults'], '2');
    });

    test('PlanningRepository generates all 3 core providers with complete parameters', () async {
      final repo = PlanningRepository();
      final startDate = DateTime(2026, 12, 1);
      final endDate = DateTime(2026, 12, 7);

      final links = await repo.generateAffiliateLinks(
        destination: 'Liverpool',
        departureCity: 'Madrid',
        startDate: startDate,
        endDate: endDate,
        travelers: 2,
      );

      expect(links.length, 3);

      final providers = links.map((l) => l.provider).toList();
      expect(providers, containsAll(['Skyscanner', 'Booking.com', 'Kayak']));

      // Validate Skyscanner flight parameters
      final skyscanner = links.firstWhere((l) => l.provider == 'Skyscanner');
      expect(skyscanner.category, 'flight');
      expect(skyscanner.url, contains('utm_source=waylo'));

      // Validate Booking hotel parameters
      final booking = links.firstWhere((l) => l.provider == 'Booking.com');
      expect(booking.category, 'hotel');
      expect(booking.destination, 'Liverpool');
      expect(booking.travelers, 2);
    });

    test('UrlUtils.formatForDisplay trims protocol and trailing slash properly', () {
      expect(
        UrlUtils.formatForDisplay('https://www.booking.com/hotel/'),
        'booking.com/hotel',
      );
    });
  });
}
