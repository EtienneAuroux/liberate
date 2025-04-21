import 'package:flow/space.dart';
import 'package:flutter/material.dart';
import 'package:c_layer/c_layer.dart' as c_layer;

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
  int _counter = 0;

  int stuff(int input) {
    int result = c_layer.sum(_counter, input);
    _counter = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return const SpaceWidget();
  }
}
