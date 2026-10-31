import 'dart:ffi' show Abi;

import 'package:expense_tracker/data/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewerVersion', () {
    test('compare major, minor et patch numériquement', () {
      expect(isNewerVersion('1.1.0', '1.0.0'), isTrue);
      expect(isNewerVersion('1.0.10', '1.0.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('ne propose ni la même version ni une plus ancienne', () {
      expect(isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0', '1.1.0'), isFalse);
    });

    test('ignore le préfixe v et le numéro de build', () {
      expect(isNewerVersion('v1.2.0', '1.1.0+5'), isTrue);
      expect(isNewerVersion('1.1.0+9', '1.1.0+2'), isFalse);
    });

    test('ne considère jamais une valeur illisible comme plus récente', () {
      expect(isNewerVersion('latest', '1.0.0'), isFalse);
      expect(isNewerVersion('1.2', '1.0.0'), isFalse);
      expect(isNewerVersion('2.0.0', ''), isFalse);
    });
  });

  test('apkDownloadUri choisit l’APK du processeur', () {
    const base = 'https://github.com/dev-Chris06/expense-tracker-flutter/releases/download/v1.2.0';
    expect(
      apkDownloadUri('1.2.0', Abi.androidArm64).toString(),
      '$base/depenses-flutter-1.2.0-arm64.apk',
    );
    expect(
      apkDownloadUri('1.2.0', Abi.androidArm).toString(),
      '$base/depenses-flutter-1.2.0-armv7.apk',
    );
  });
}
