import 'dart:math';

import 'package:flow/app_state.dart';
import 'package:flow/bindings.dart';
import 'package:flow/space.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:developer' as dev;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Random random = Random();

  @override
  void initState() {
    super.initState();

    AppState.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // onTap: () {
      //   dev.log('tap');
      //   cLayerBindings.test();
      // },
      onPointerDown: (event) {
        if (event.buttons == kPrimaryMouseButton) {
          int seed = random.nextInt(5);
          dev.log('seed: $seed');
          cLayerBindings.randomScreen(seed);
        } else {}
      },
      behavior: HitTestBehavior.opaque,
      child: const SpaceWidget(),
    );
  }
}
