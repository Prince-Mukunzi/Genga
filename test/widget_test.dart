import 'package:flutter_test/flutter_test.dart';
import 'package:genga/app/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep link redirect tests', () {
    test('Redirects genga://add?type=income to /add?type=income', () {
      final uri = Uri.parse('genga://add?type=income');
      expect(uri.scheme, 'genga');
      expect(uri.host, 'add');
      expect(uri.queryParameters['type'], 'income');
    });

    test('Redirects genga://add?type=expense to /add?type=expense', () {
      final uri = Uri.parse('genga://add?type=expense');
      expect(uri.scheme, 'genga');
      expect(uri.host, 'add');
      expect(uri.queryParameters['type'], 'expense');
    });

    test('Redirects genga://add?type=transfer to /add?type=transfer', () {
      final uri = Uri.parse('genga://add?type=transfer');
      expect(uri.scheme, 'genga');
      expect(uri.host, 'add');
      expect(uri.queryParameters['type'], 'transfer');
    });

    test('Redirects genga://transactions to /add/transactions', () {
      final uri = Uri.parse('genga://transactions');
      expect(uri.scheme, 'genga');
      expect(uri.host, 'transactions');
    });

    test('MoMo link prefills amount and note', () {
      final screen = addScreenForUri(
        Uri.parse('genga://add?type=income&amount=12,500&note=Rent'),
      );
      expect(screen.initialAmount, 12500);
      expect(screen.initialNote, 'Rent');
    });
  });
}
