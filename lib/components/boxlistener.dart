import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class BoxListener<T> extends StatefulWidget {
  final Box<T> box;
  final Widget Function(BuildContext context, Box<T> box) builder;
  final List<dynamic>? keys;

  const BoxListener({
    super.key,
    required this.box,
    required this.builder,
    this.keys,
  });

  @override
  State<BoxListener<T>> createState() => _BoxListenerState<T>();
}

class _BoxListenerState<T> extends State<BoxListener<T>> {
  late ValueListenable<Box<T>> listenable;

  void listen() {
    setState(() {});
  }

  @override
  void initState() {
    listenable = widget.box.listenable(keys: widget.keys)..addListener(listen);
    super.initState();
  }

  @override
  void dispose() {
    listenable.removeListener(listen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.box);
}
