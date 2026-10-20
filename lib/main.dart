import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// Paramètres partagés par tous les rectangles.
class BoxSettings extends ChangeNotifier {
  Color? fillColor; // null = couleur aléatoire pour chaque rectangle
  Color borderColor = Colors.white;
  double borderWidth = 1;
  double borderRadius = 0;
  int colorVersion = 0; // change à chaque nouveau choix de couleur

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final settings = BoxSettings();
  int resetCount = 0; // changer la clé recrée le rectangle principal

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre du haut : titre + retour au début + bouton paramètres
      appBar: AppBar(
        title: const Text('Mon projet'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => resetCount++),
            icon: const Icon(Icons.home),
            label: const Text('Revenir au début'),
          ),
          // Bouton qui ouvre le panneau des paramètres
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Paramètres',
              icon: const Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Panneau de droite caché, qui s'ouvre au clic (comme sur mobile)
      endDrawer: Drawer(
        width: 260,
        child: SettingsPanel(settings: settings),
      ),
      body: SplitBox(
        key: ValueKey(resetCount),
        settings: settings,
      ),
    );
  }
}

class SettingsPanel extends StatelessWidget {
  final BoxSettings settings;
  const SettingsPanel({super.key, required this.settings});

  static const palette = <Color>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.black,
    Colors.white,
  ];

  Widget _swatch(Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Container(
          width: 260,
          color: Colors.grey.shade100,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Paramètres',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Couleur des rectangles
              const Text('Couleur des rectangles'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => settings.update(() {
                      settings.fillColor = null;
                      settings.colorVersion++;
                    }),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: settings.fillColor == null
                              ? Colors.deepPurple
                              : Colors.black26,
                          width: settings.fillColor == null ? 3 : 1,
                        ),
                      ),
                      child: const Text('Aléatoire'),
                    ),
                  ),
                  for (final c in palette)
                    _swatch(
                      c,
                      settings.fillColor == c,
                      () => settings.update(() {
                        settings.fillColor = c;
                        settings.colorVersion++;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Couleur de la bordure
              const Text('Couleur de la bordure'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in palette)
                    _swatch(
                      c,
                      settings.borderColor == c,
                      () => settings.update(() => settings.borderColor = c),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Épaisseur de la bordure
              Text('Épaisseur de la bordure : '
                  '${settings.borderWidth.toStringAsFixed(1)}'),
              Slider(
                value: settings.borderWidth,
                min: 0,
                max: 10,
                divisions: 20,
                onChanged: (v) =>
                    settings.update(() => settings.borderWidth = v),
              ),

              // Rayon de la bordure
              Text('Rayon de la bordure : '
                  '${settings.borderRadius.toStringAsFixed(0)}'),
              Slider(
                value: settings.borderRadius,
                min: 0,
                max: 60,
                divisions: 60,
                onChanged: (v) =>
                    settings.update(() => settings.borderRadius = v),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SplitBox extends StatefulWidget {
  final BoxSettings settings;
  final Color? startColor; // couleur reçue du parent au moment de la division
  final int startVersion;
  const SplitBox({
    super.key,
    required this.settings,
    this.startColor,
    this.startVersion = -1,
  });

  @override
  State<SplitBox> createState() => _SplitBoxState();
}

class _SplitBoxState extends State<SplitBox> {
  bool isSplit = false;
  Color? _color;
  int _version = -1;
  Color? _parentColor; // couleur de ce rectangle au moment où on le divise

  // Couleur aléatoire fixée une seule fois par rectangle
  late final Color randomColor = Color.fromARGB(
    255,
    Random().nextInt(256),
    Random().nextInt(256),
    Random().nextInt(256),
  );

  @override
  void initState() {
    super.initState();
    _color = widget.startColor;
    _version = widget.startVersion;
  }

  /// Éclaircit la couleur de 35 % vers le blanc.
  Color lighten(Color color) => Color.lerp(color, Colors.white, 0.35)!;

  /// Couleur affichée par ce rectangle.
  Color currentColor(BoxSettings s) {
    if (s.fillColor == null) return randomColor;
    // Si une nouvelle couleur a été choisie, on repart de cette couleur
    if (_color == null || _version != s.colorVersion) {
      _color = s.fillColor;
      _version = s.colorVersion;
    }
    return _color!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cas 1 : pas encore divisé -> rectangle cliquable
        if (!isSplit) {
          return ListenableBuilder(
            listenable: widget.settings,
            builder: (context, _) {
              final s = widget.settings;
              return GestureDetector(
                onTap: () => setState(() {
                  _parentColor = currentColor(s);
                  isSplit = true;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: currentColor(s),
                    borderRadius: BorderRadius.circular(s.borderRadius),
                    border: Border.all(
                      color: s.borderColor,
                      width: s.borderWidth,
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Cas 2 : divisé -> le 1er garde la couleur du parent,
        // le 2e (le nouveau) est plus clair
        final s = widget.settings;
        final children = [
          Expanded(
            child: SplitBox(
              settings: s,
              startColor: _parentColor,
              startVersion: s.colorVersion,
            ),
          ),
          Expanded(
            child: SplitBox(
              settings: s,
              startColor: lighten(_parentColor!),
              startVersion: s.colorVersion,
            ),
          ),
        ];

        // On coupe selon le côté le plus long pour obtenir des carrés
        return constraints.maxWidth > constraints.maxHeight
            ? Row(children: children)
            : Column(children: children);
      },
    );
  }
}
