[![Pub Version](https://img.shields.io/pub/v/glass.svg?style=flat-square)](https://pub.dev/packages/glass)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

# Glass
Easily convert any Widget into a glass / frosted glass version of itself, following the glassmorphism / glassmorphic  design trend.

![Sample screenshot](https://raw.githubusercontent.com/Zachariah-Abraham/glass/main/example/screenshots/2.PNG)
![Sample screenshot 2](https://raw.githubusercontent.com/Zachariah-Abraham/glass/main/example/screenshots/3.png)

## Installation

### 1. Add it

```bash
flutter pub add glass
```

Requires Flutter 3.27 or newer (Dart 3.6+). Older Flutter versions automatically resolve to glass 2.0.0.

### 2. Import it

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

Glass blurs what is *behind* the widget, so it only shows up when there is content underneath
(for example inside a `Stack` or over a background image).

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `enabled` | `true` | Enable or disable all effects. |
| `blurX` / `blurY` | `10.0` | Blur amount along each axis. |
| `tintColor` | `Colors.white` | Tint of the glass. Use `Colors.transparent` for no tint. |
| `frosted` | `true` | Adds a noise texture for a frosted look. |
| `clipBorderRadius` | `BorderRadius.zero` | Rounded corners. Ignored if `clipper` is set. |
| `clipBehavior` | `Clip.antiAlias` | How the glass is clipped. |
| `clipBehaviour` | `null` | **Deprecated** misspelling of `clipBehavior`, removed in 3.0.0. |
| `tileMode` | `TileMode.clamp` | How the blur samples at the edges. |
| `clipper` | `null` | Custom `CustomClipper<RRect>`. |

A full example can be found in the example directory.

## About me

Visit my LinkedIn at https://www.linkedin.com/in/zaca
