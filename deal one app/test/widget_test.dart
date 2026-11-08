import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/config/app_config.dart';
import 'package:market_space/core/config/config_validator.dart';

void main() {
  test('App smoke test: development config is valid', () {
    final config = AppConfig.development();
    expect(() => ConfigValidator.validate(config), returnsNormally);
    expect(config.apiBaseUrl, isNotEmpty);
  });
}
