import 'package:fashion_store/constants.dart';
import 'package:fashion_store/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    Konstan.customHost = null;
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android emulator uses the host machine API address', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(Konstan.baseUrl, 'http://10.0.2.2:8000/api');
  });

  test('custom host is used for physical devices and other hosts', () {
    Konstan.customHost = 'http://192.168.1.10:8000';

    expect(Konstan.baseUrl, 'http://192.168.1.10:8000/api');
  });

  test('custom host without scheme is normalized before use', () {
    Konstan.customHost = '192.168.1.10:8000';

    expect(Konstan.baseUrl, 'http://192.168.1.10:8000/api');
  });

  test('network errors map to the no-connection screen state', () {
    expect(tentukanJenisGalat('NO_CONNECTION'), JenisGalat.tidakAdaSambungan);
    expect(tentukanJenisGalat('NETWORK'), JenisGalat.tidakAdaSambungan);
    expect(tentukanJenisGalat('network'), JenisGalat.tidakAdaSambungan);
  });
}
