import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('images/demo.png'),
            ),
          ),
          child: Center(
            child: Container(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Text(
                  "Hello",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ).asGlass(),
          ),
        ),
      ),
    );
  }
}
