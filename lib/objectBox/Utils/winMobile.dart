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
      try {
        // Attempt to get the window size
        final Size? currentSize = await windowManager.getSize();

        // Check if currentSize is not null before proceeding
        if (currentSize != null) {
          setState(() {
            // Determine if the size is similar to a phone
            isPhoneSize = (currentSize.width < 600);
            iconSign = isPhoneSize
                ? FontAwesomeIcons.desktop
                : FontAwesomeIcons.mobile;
          });
        } else {
          // Handle the case where getSize() returns null
          print("Window size is null. Unable to determine screen dimensions.");
        }
      } catch (e) {
        // Catch any exceptions and log them
        print("Error while checking window size: $e");
      }
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
