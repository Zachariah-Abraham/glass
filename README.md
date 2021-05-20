[![Pub Version](https://img.shields.io/pub/v/glass.svg?style=flat-square)](https://pub.dev/packages/glass)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

# Glass
Easily convert any Widget into a glass / frosted glass version of itself, following the glassmorphism / glassmorphic  design trend.

![Sample screenshot](https://raw.githubusercontent.com/Zachariah-Abraham/glass/main/example/screenshots/2.PNG)
![Sample screenshot 2](https://raw.githubusercontent.com/Zachariah-Abraham/glass/main/example/screenshots/3.PNG)

## Installation

### 1. Depend on it

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
    glass:
```


### 2. Install it

You can install packages from the command line:

```bash
$ pub get
..
```

Alternatively, your editor might support pub. Check the docs for your editor to learn more.

### 3. Import it

Now in your Flutter code, you can use:

```Dart
import 'package:glass/glass.dart';
```

## Usage

Simply call .asGlass() <with parameters if needed> on the widget you want to convert to glass.

For example: 

```Dart
Container(
    child: someChild,
).asGlass()
```

A full example can be found in the example directory

## About me

Visit my LinkedIn at https://www.linkedin.com/in/zaca
