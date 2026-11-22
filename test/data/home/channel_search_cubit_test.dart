import 'dart:async';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/data/home/channel_search_cubit.dart';
import 'package:coldchat/tools/channel_ranking.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../api/fake_api.dart';

ChannelCandidate _candidate(String login) =>
    ChannelCandidate(login: login, displayName: login, profileImageUrl: 'https://example.invalid/$login.png');

void main() {
  late HelixApi? helix;
  late Map<String, Completer<List<ChannelCandidate>>> searches;
  late List<String> queries;

  ChannelSearchCubit create() => ChannelSearchCubit(
    helix: () => helix,
    search: (helix, query) {
      queries.add(query);
      return (searches[query] = Completer()).future;
    },
  );

  List<String>? resultLogins(ChannelSearchState state) =>
      state is ChannelSearchLoaded ? [for (final c in state.results) c.login] : null;

  setUp(() {
    helix = HelixApi(offlineApi(), () => null);
    searches = {};
    queries = [];
  });

  test('fast typing sends one search, 250 ms after the last letter', () {
    fakeAsync((async) {
      final cubit = create();
      for (final text in ['f', 'fo', 'for', 'fors', 'forse', 'forsen']) {
        cubit.queryChanged(text);
        async.elapse(const Duration(milliseconds: 100));
      }
      expect(queries, isEmpty);
      expect(cubit.state, isA<ChannelSearchIdle>());

      async.elapse(const Duration(milliseconds: 150));
      expect(queries, ['forsen']);
      expect(cubit.state, isA<ChannelSearchLoading>());

      searches['forsen']!.complete([_candidate('forsen')]);
      async.flushMicrotasks();
      expect(resultLogins(cubit.state), ['forsen']);
      unawaited(cubit.close());
    });
  });

  test('a failed search is shown as failed', () {
    fakeAsync((async) {
      final cubit = create()..queryChanged('forsen');
      async.elapse(const Duration(milliseconds: 250));
      searches['forsen']!.completeError(Exception('offline'));
      async.flushMicrotasks();
      expect(cubit.state, isA<ChannelSearchFailed>());
      unawaited(cubit.close());
    });
  });

  test('emptying the field clears the results right away and cancels the pending search', () {
    fakeAsync((async) {
      final cubit = create()..queryChanged('forsen');
      async.elapse(const Duration(milliseconds: 250));
      searches['forsen']!.complete([_candidate('forsen')]);
      async.flushMicrotasks();
      expect(cubit.state, isA<ChannelSearchLoaded>());

      cubit.queryChanged('nymn');
      cubit.queryChanged(' # ');
      expect(cubit.state, isA<ChannelSearchIdle>());

      async.elapse(const Duration(seconds: 1));
      expect(queries, ['forsen']);
      expect(cubit.state, isA<ChannelSearchIdle>());
      unawaited(cubit.close());
    });
  });

  test('clearing drops a search still in flight', () {
    fakeAsync((async) {
      final cubit = create()..queryChanged('forsen');
      async.elapse(const Duration(milliseconds: 250));
      cubit.clear();
      searches['forsen']!.complete([_candidate('forsen')]);
      async.flushMicrotasks();
      expect(cubit.state, isA<ChannelSearchIdle>());
      unawaited(cubit.close());
    });
  });

  test('the answer to an older query does not replace the newer one', () {
    fakeAsync((async) {
      final cubit = create()..queryChanged('for');
      async.elapse(const Duration(milliseconds: 250));
      cubit.queryChanged('forsen');
      async.elapse(const Duration(milliseconds: 250));
      expect(queries, ['for', 'forsen']);

      searches['forsen']!.complete([_candidate('forsen')]);
      async.flushMicrotasks();
      searches['for']!.complete([_candidate('forthelulz')]);
      async.flushMicrotasks();
      expect(resultLogins(cubit.state), ['forsen']);

      // Also when the older answer is the one that comes first.
      cubit.queryChanged('nymn');
      async.elapse(const Duration(milliseconds: 250));
      cubit.queryChanged('nymn2');
      async.elapse(const Duration(milliseconds: 250));
      searches['nymn']!.complete([_candidate('nymn')]);
      async.flushMicrotasks();
      expect(cubit.state, isA<ChannelSearchLoading>());
      searches['nymn2']!.complete([_candidate('nymn2')]);
      async.flushMicrotasks();
      expect(resultLogins(cubit.state), ['nymn2']);
      unawaited(cubit.close());
    });
  });

  test('without an account nothing is searched: the results are empty right away, so only the typed name shows', () {
    fakeAsync((async) {
      helix = null;
      final cubit = create()..queryChanged('forsen');
      expect(resultLogins(cubit.state), isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(queries, isEmpty);
      expect(resultLogins(cubit.state), isEmpty);

      cubit.queryChanged('');
      expect(cubit.state, isA<ChannelSearchIdle>());
      unawaited(cubit.close());
    });
  });

  test('closing cancels a pending search', () {
    fakeAsync((async) {
      final cubit = create()..queryChanged('forsen');
      unawaited(cubit.close());
      async.elapse(const Duration(seconds: 1));
      expect(queries, isEmpty);
    });
  });
}
