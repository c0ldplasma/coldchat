import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

/// Notifies its listeners when an entry of a box changes, or only one of [keys] when given.
///
/// Repositories hand these out instead of Hive's own `box.listenable()`: one instance is shared by every widget that
/// listens, and a [ChangeNotifier] copes with listeners that are added or removed while it notifies.
class BoxChanges extends ChangeNotifier {
  late final StreamSubscription<BoxEvent> _subscription;

  BoxChanges(Box<dynamic> box, {Iterable<String>? keys}) {
    final watched = keys?.toSet();
    _subscription = box.watch().listen((event) {
      if (watched == null || watched.contains(event.key)) notifyListeners();
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
