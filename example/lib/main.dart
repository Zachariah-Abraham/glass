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
              image: AssetImage('images/demo.png'),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: Padding(
                    padding: EdgeInsets.all(200.0),
                    child: Text(
                      "Night sky",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ).asGlass(
                  clipBorderRadius: BorderRadius.circular(15.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
