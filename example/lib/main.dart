import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool effectEnabled = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/demo.png'),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  child: TextButton(
                    onPressed: () => setState(() => effectEnabled = !effectEnabled),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(200),
                    ),
                    child: Text(
                      "Night sky",
                      style: TextStyle(color: Colors.white),
                    ),
                  ).asGlass(
                    enabled: effectEnabled,
                    tintColor: Colors.transparent,
                    clipBorderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
