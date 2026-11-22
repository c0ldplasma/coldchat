import 'dart:async';

import 'package:coldchat/data/emote_cache_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load reads the size', () async {
    final cubit = EmoteCacheCubit(readSize: () async => 1234, clear: () async {});

    expect(cubit.state.bytes, isNull);
    await cubit.load();

    expect(cubit.state.bytes, 1234);
    expect(cubit.state.clearing, isFalse);
  });

  test('a size that cannot be read is left out', () async {
    final cubit = EmoteCacheCubit(readSize: () async => throw Exception('no database'), clear: () async {});

    await cubit.load();

    expect(cubit.state.bytes, isNull);
  });

  test('clear empties the cache, shows that it is clearing, then reads the new size', () async {
    var size = 5000;
    final clearing = Completer<void>();
    final cubit = EmoteCacheCubit(
      readSize: () async => size,
      clear: () async {
        await clearing.future;
        size = 0;
      },
    );
    await cubit.load();

    final cleared = cubit.clear();
    expect(cubit.state.clearing, isTrue);
    expect(cubit.state.bytes, 5000);

    clearing.complete();
    await cleared;
    expect(cubit.state.clearing, isFalse);
    expect(cubit.state.bytes, 0);
  });

  test('a second clear while clearing does nothing', () async {
    var clears = 0;
    final clearing = Completer<void>();
    final cubit = EmoteCacheCubit(
      readSize: () async => 0,
      clear: () async {
        clears++;
        await clearing.future;
      },
    );

    final first = cubit.clear();
    await cubit.clear();
    clearing.complete();
    await first;

    expect(clears, 1);
  });

  test('a failed clear still reads the size again and stops clearing', () async {
    final cubit = EmoteCacheCubit(readSize: () async => 42, clear: () async => throw Exception('disk error'));

    await cubit.clear();

    expect(cubit.state.clearing, isFalse);
    expect(cubit.state.bytes, 42);
  });
}
