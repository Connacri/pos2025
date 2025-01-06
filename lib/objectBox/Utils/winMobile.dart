import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:window_manager/window_manager.dart';

class WinMobile extends StatefulWidget {
  const WinMobile({super.key});

  @override
  State<WinMobile> createState() => _WinMobileState();
}

class _WinMobileState extends State<WinMobile> {
  bool isPhoneSize = false;
  IconData iconSign = FontAwesomeIcons.mobile;

  @override
  void initState() {
    super.initState();
    _checkCurrentSize(); // Vérifier la taille au démarrage
  }

  Future<void> _checkCurrentSize() async {
    if (Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isFuchsia) {
      final Size currentSize = await windowManager.getSize();
      setState(() {
        // Si la taille est proche de celle du mobile
        isPhoneSize =
            (currentSize.width < 500); // On utilise une valeur approximative
        iconSign =
            isPhoneSize ? FontAwesomeIcons.desktop : FontAwesomeIcons.mobile;
      });
    }
  }

  Future<void> _toggleWindowSize() async {
    if (isPhoneSize) {
      // Passer en mode Desktop
      await windowManager.setSize(const Size(1920, 1080));
      setState(() {
        isPhoneSize = false;
        iconSign = FontAwesomeIcons.mobile;
      });
    } else {
      // Passer en mode Mobile
      await windowManager.setSize(const Size(375, 812));
      if (mounted) {
        setState(() {
          isPhoneSize = true;
          iconSign = FontAwesomeIcons.desktop;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Platform.isIOS || Platform.isAndroid
          ? Container()
          : IconButton(
              onPressed: _toggleWindowSize,
              icon: Icon(iconSign),
            ),
    );
  }
}
