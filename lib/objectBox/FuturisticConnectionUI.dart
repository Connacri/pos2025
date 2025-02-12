import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FuturisticConnectionUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond animé avec particules
          Lottie.asset(
            'assets/lotties/1 (83).json',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation Lottie holographique
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Lottie.asset(
                          'assets/lotties/1 (7).json',
                          animate: true,
                          repeat: true,
                        ),
                      ),
                    ],
                  ),

                  // Titre avec dégradé et effet néon
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.cyanAccent, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'CONNEXION ÉTABLIE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Sous-titre avec effet de lueur
                  Text(
                    'Connexion internet stable',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green, //.withOpacity(0.8),
                      shadows: [
                        Shadow(
                          color: Colors.blueAccent,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Bouton futuriste
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'CONTINUER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
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

class HoverGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const HoverGradientButton({
    required this.onPressed,
    required this.child,
  });

  @override
  _HoverGradientButtonState createState() => _HoverGradientButtonState();
}

class _HoverGradientButtonState extends State<HoverGradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered
                ? [Colors.cyanAccent, Colors.blueAccent]
                : [
                    Colors.blueAccent.withOpacity(0.6),
                    Colors.cyanAccent.withOpacity(0.6)
                  ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
