// Realistic app screens built with glass, used for the pub.dev screenshots.
// Pick a screen with --dart-define=SCREEN=<travel|photos|music|weather>:
//
//   flutter run -t lib/screens.dart -d <iPhone simulator> --dart-define=SCREEN=travel
//
// Liquid glass needs Impeller (iOS, Android, macOS); elsewhere it falls back to
// plain blur. The photos load from picsum.photos and are from Unsplash
// (Unsplash License); `photoCredits` lists the authors.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glass/glass.dart';

void main() => runApp(const ScreensApp());

/// Shows the screen named by the `SCREEN` environment declaration.
class ScreensApp extends StatelessWidget {
  /// Creates the app.
  const ScreensApp({super.key});

  static const _screen = String.fromEnvironment(
    'SCREEN',
    defaultValue: 'travel',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glass screens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A84FF),
        brightness: _screen == 'music' ? Brightness.dark : Brightness.light,
      ),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: switch (_screen) {
          'photos' => const PhotosScreen(),
          'music' => const MusicScreen(),
          'weather' => const WeatherScreen(),
          _ => const TravelScreen(),
        },
      ),
    );
  }
}

const _blue = Color(0xFF0A84FF);

/// Liquid glass for dark interfaces: the regular preset with a dark tint.
const _darkRegular = LiquidGlass(
  blur: 7.0,
  tintColor: Color(0xFF1C1C1F),
  tintStrength: 0.62,
  saturation: 1.6,
  shadow: BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 8),
    blurRadius: 30,
  ),
);

/// Authors of the photos used here, by picsum id (all from unsplash.com).
const photoCredits = {
  1015: 'Alexey Topolyanskiy',
  1011: 'Roberto Nickson',
  1043: 'Christian Joudrey',
  1039: 'Andrew Coelho',
  1016: 'Philippe Wuyts',
  1036: 'Wolfgang Lutz',
  1050: 'Joseph Barrientos',
  1069: 'Marat Gilyadzinov',
  1080: 'veeterzy',
  152: 'Steven Spassov',
  164: 'Linh Nguyen',
  177: 'Danka & Peter',
  184: 'Tim de Groot',
  211: 'Martin Wessely',
  28: 'Jerry Adney',
  29: 'Go Wild',
  299: 'Matthew Wiebe',
  306: 'Schicka',
  401: 'Austin Ban',
  429: 'Glen Carrie',
  431: 'Carli Jean',
  436: 'Lucas Theis',
  452: 'Desi Mendoza',
  488: 'Monstruo Estudio',
  541: 'Talia Cohen',
  110: 'Kenneth Thewissen',
};

/// An Unsplash photo served by picsum.photos, cropped to [width] x [height].
class _Photo extends StatelessWidget {
  const _Photo(this.id, {this.width = 600, this.height = 600});

  final int id;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://picsum.photos/id/$id/$width/$height',
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder:
          (context, child, frame, _) => ColoredBox(
            color: const Color(0xFF2C2C2E),
            child: frame == null ? const SizedBox.expand() : child,
          ),
    );
  }
}

/// A round glass button with an icon.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton(
    this.icon, {
    this.liquid = LiquidGlass.clear,
    this.color = Colors.white,
    this.size = 48,
  });

  final IconData icon;
  final LiquidGlass liquid;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Icon(icon, color: color, size: size * 0.46),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(size / 2),
      liquid: liquid,
    );
  }
}

// ---------------------------------------------------------------------------
// Travel: a full-bleed photo with glass controls and a booking card.

/// A trip detail page over a full-screen photo.
class TravelScreen extends StatelessWidget {
  /// Creates the screen.
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Photo(1015, width: 1400, height: 2800),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const _GlassIconButton(CupertinoIcons.chevron_back),
                      const Spacer(),
                      const SizedBox(
                        height: 48,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.heart,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 22),
                              Icon(
                                CupertinoIcons.share,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ).asGlass(
                        clipBorderRadius: BorderRadius.circular(24),
                        liquid: LiquidGlass.clear,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const _TripCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard();

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF1C1C1E);
    const muted = Color(0xFF6E6E73);
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Fjord Viewpoint Hike',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: dark,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Guided day trip · Small group',
            style: TextStyle(fontSize: 15, color: muted),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _TripFact(CupertinoIcons.star_fill, '4.9', 'rating'),
              _TripFact(CupertinoIcons.clock, '6 h', 'duration'),
              _TripFact(CupertinoIcons.arrow_up_right, '604 m', 'climb'),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '\$89',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    TextSpan(
                      text: ' / person',
                      style: TextStyle(fontSize: 15, color: muted),
                    ),
                  ],
                ),
              ),
              Spacer(),
              _BookButton(),
            ],
          ),
        ],
      ),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(34),
      liquid: LiquidGlass.regular,
    );
  }
}

class _TripFact extends StatelessWidget {
  const _TripFact(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1C1C1E)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6E6E73)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Text(
        'Book now',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photos: an edge-to-edge grid under glass buttons and a glass tab bar.

/// A photo library grid.
class PhotosScreen extends StatelessWidget {
  /// Creates the screen.
  const PhotosScreen({super.key});

  static const _ids = [
    1043, 1039, 1011, 431, 1016, 152, 1080, 436, 1050, 164, 177, 1036, //
    29, 306, 429, 1015, 488, 401, 211, 28, 299, 110, 184, 1069,
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final id in _ids) _Photo(id, width: 400, height: 400),
            ],
          ),
          // Keeps the status bar and title readable over bright photos.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: top + 130,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 16, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Library',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '2,418 Photos, 96 Videos',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xDDFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 44,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: Center(
                            child: Text(
                              'Select',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ).asGlass(
                        clipBorderRadius: BorderRadius.circular(22),
                        liquid: LiquidGlass.clear,
                      ),
                      const SizedBox(width: 10),
                      const _GlassIconButton(CupertinoIcons.ellipsis, size: 44),
                    ],
                  ),
                  const Spacer(),
                  const _Segments(),
                  const SizedBox(height: 14),
                  const _PhotosTabBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments();

  static const _labels = ['Years', 'Months', 'All'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in _labels)
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: label == 'All' ? const Color(0x1F000000) : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
        ],
      ),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(22),
      liquid: LiquidGlass.regular,
    );
  }
}

class _PhotosTabBar extends StatelessWidget {
  const _PhotosTabBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 62,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x14000000),
                        borderRadius: BorderRadius.circular(27),
                      ),
                      child: const _TabItem(
                        CupertinoIcons.photo_fill_on_rectangle_fill,
                        'Library',
                        selected: true,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: _TabItem(
                      CupertinoIcons.rectangle_stack_fill,
                      'Collections',
                    ),
                  ),
                ],
              ),
            ),
          ).asGlass(
            clipBorderRadius: BorderRadius.circular(31),
            liquid: LiquidGlass.regular,
          ),
        ),
        const SizedBox(width: 12),
        const _GlassIconButton(
          CupertinoIcons.search,
          liquid: LiquidGlass.regular,
          color: Color(0xFF1C1C1E),
          size: 62,
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem(
    this.icon,
    this.label, {
    this.selected = false,
    this.color = const Color(0xFF1C1C1E),
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = selected ? _blue : color;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: c, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Music: a dark library with a glass mini player and tab bar.

/// A music app home screen in dark mode.
class MusicScreen extends StatelessWidget {
  /// Creates the screen.
  const MusicScreen({super.key});

  static const _recent = [
    (541, 'Deep Water', 'Hollow Coast'),
    (306, 'Lotus', 'Mira Vance'),
    (1069, 'Bioluminescence', 'The Tidelines'),
    (211, 'Harbour Lights', 'Old Pier'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 8,
              20,
              bottom + 160,
            ),
            children: [
              const Row(
                children: [
                  Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFF6B3D),
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Top Picks for You'),
              const SizedBox(height: 10),
              const SizedBox(
                height: 240,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _FeatureCard(452, 'Live Tonight', 'Concert mix'),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _FeatureCard(184, 'Night Drive', 'Ambient'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _SectionTitle('Recently Played'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  for (final (id, title, artist) in _recent)
                    _AlbumTile(id, title, artist),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 2,
            child: const Column(
              children: [_MiniPlayer(), SizedBox(height: 10), _MusicTabBar()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          CupertinoIcons.chevron_right,
          size: 18,
          color: Color(0xFF8E8E93),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.id, this.title, this.subtitle);

  final int id;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Photo(id, width: 600, height: 800),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xB0000000)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile(this.id, this.title, this.artist);

  final int id;
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _Photo(id, width: 500, height: 500),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          artist,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox.square(
                dimension: 44,
                child: _Photo(1069, width: 200, height: 200),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bioluminescence',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'The Tidelines',
                    style: TextStyle(fontSize: 13, color: Color(0xFFAEAEB2)),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.pause_fill,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(width: 22),
            const Icon(
              CupertinoIcons.forward_fill,
              color: Colors.white,
              size: 26,
            ),
          ],
        ),
      ),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(30),
      liquid: _darkRegular,
    );
  }
}

class _MusicTabBar extends StatelessWidget {
  const _MusicTabBar();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE5E5EA);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 62,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x24FFFFFF),
                        borderRadius: BorderRadius.circular(27),
                      ),
                      child: const _TabItem(
                        CupertinoIcons.house_fill,
                        'Home',
                        selected: true,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: _TabItem(
                      CupertinoIcons.square_grid_2x2_fill,
                      'New',
                      color: color,
                    ),
                  ),
                  const Expanded(
                    child: _TabItem(
                      CupertinoIcons.dot_radiowaves_left_right,
                      'Radio',
                      color: color,
                    ),
                  ),
                  const Expanded(
                    child: _TabItem(
                      CupertinoIcons.music_albums_fill,
                      'Library',
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ).asGlass(
            clipBorderRadius: BorderRadius.circular(31),
            liquid: _darkRegular,
          ),
        ),
        const SizedBox(width: 12),
        const _GlassIconButton(
          CupertinoIcons.search,
          liquid: _darkRegular,
          size: 62,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weather: the same widget as plain glass, liquid regular and liquid clear.

/// One weather widget rendered three ways, for comparing the glass styles.
class WeatherScreen extends StatelessWidget {
  /// Creates the screen.
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Photo(1043, width: 1400, height: 2800),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Labelled(
                    'asGlass()',
                    child: const _Forecast(
                      foreground: Colors.white,
                    ).asGlass(clipBorderRadius: BorderRadius.circular(28)),
                  ),
                  _Labelled(
                    'asGlass(liquid: LiquidGlass.regular)',
                    child: const _Forecast(
                      foreground: Color(0xFF1C1C1E),
                    ).asGlass(
                      clipBorderRadius: BorderRadius.circular(28),
                      liquid: LiquidGlass.regular,
                    ),
                  ),
                  _Labelled(
                    'asGlass(liquid: LiquidGlass.clear)',
                    child: const _Forecast(foreground: Colors.white).asGlass(
                      clipBorderRadius: BorderRadius.circular(28),
                      liquid: LiquidGlass.clear,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled(this.label, {required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 6, color: Color(0xAA000000))],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.foreground});

  final Color foreground;

  static const _hours = [
    ('Now', CupertinoIcons.cloud_sun_fill, '18°'),
    ('14', CupertinoIcons.sun_max_fill, '20°'),
    ('15', CupertinoIcons.sun_max_fill, '21°'),
    ('16', CupertinoIcons.cloud_sun_fill, '19°'),
    ('17', CupertinoIcons.cloud_fill, '17°'),
    ('18', CupertinoIcons.sunset_fill, '15°'),
  ];

  @override
  Widget build(BuildContext context) {
    final muted = foreground.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valley Trailhead',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  Text(
                    '18°',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      height: 1.1,
                      color: foreground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    CupertinoIcons.cloud_sun_fill,
                    color: foreground,
                    size: 26,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partly Cloudy',
                    style: TextStyle(fontSize: 14, color: foreground),
                  ),
                  Text(
                    'H:21°  L:9°',
                    style: TextStyle(fontSize: 14, color: muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: foreground.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (hour, icon, temp) in _hours)
                Column(
                  children: [
                    Text(
                      hour,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(icon, size: 20, color: foreground),
                    const SizedBox(height: 6),
                    Text(
                      temp,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
