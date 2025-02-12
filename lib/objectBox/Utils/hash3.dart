import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../MyApp.dart';
import '../hash.dart';

class LicenseCheckScreen extends StatefulWidget {
  @override
  _LicenseCheckScreenState createState() => _LicenseCheckScreenState();
}

class _LicenseCheckScreenState extends State<LicenseCheckScreen> {
  bool _isLicenseValidated = false;
  bool _isLicenseDemoValidated = false;
  int _attempts = 0;
  String _statusMessage = "";
  String _statusMessage2 = "";
  String _enteredHash = "";
  bool _showMacAndPhoneFields = false;

  @override
  void initState() {
    super.initState();
    _checkLicenseStatus();
  }

  Future<void> _checkLicenseStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Vérifier les deux états dans SharedPreferences
    bool? isLicenseValidated = prefs.getBool('isLicenseValidated');
    bool? isLicenseDemoValidated = prefs.getBool('isLicenseDemoValidated');

    // Mettre à jour l'état en fonction des valeurs récupérées
    if (isLicenseValidated != null && isLicenseValidated) {
      setState(() {
        _isLicenseValidated = true;
      });
    } else if (isLicenseDemoValidated != null && isLicenseDemoValidated) {
      // Vérifier si la connexion à Supabase est interrompue depuis plus de 2 jours
      final lastOnlineCheckString = prefs.getString('lastOnlineCheck');
      if (lastOnlineCheckString != null) {
        final lastOnlineCheck = DateTime.parse(lastOnlineCheckString);
        final now = DateTime.now();
        final offlineDuration = now.difference(lastOnlineCheck);

        if (offlineDuration.inDays <= 2) {
          setState(() {
            _isLicenseDemoValidated = true;
          });
        } else {
          setState(() {
            _statusMessage2 =
                "Licence terminée. Veuillez recontacter le fournisseur.";
          });
        }
      } else {
        setState(() {
          _isLicenseDemoValidated = true;
        });
      }
    }
  }

  Future<void> checkAndValidateDemoLicense() async {
    final supabase = Supabase.instance.client;

    try {
      // Vérifier si _enteredHash existe dans la table Supabase
      final response = await supabase
          .from('hashCodeTemp')
          .select('hash_code, expires_at, is_demo')
          .eq('hash_code', _enteredHash.trim())
          .single();

      if (response != null) {
        final hashCode = response['hash_code'] as String?;
        final expiresAtString = response['expires_at'] as String?;
        final isDemo = response['is_demo'] as bool?;

        if (hashCode != null && expiresAtString != null && isDemo != null) {
          if (hashCode == _enteredHash.trim()) {
            final expiresAt = DateTime.parse(expiresAtString);
            final now = DateTime.now();
            final remainingDays = expiresAt.difference(now).inDays;

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'licenseExpiresAt', expiresAt.toIso8601String());
            await prefs.setBool('isDemoLicense', isDemo);
            await prefs.setInt('remainingDays', remainingDays);
            await prefs.setString('lastOnlineCheck', now.toIso8601String());

            setState(() {
              _isLicenseDemoValidated = true;
              _statusMessage2 =
                  isDemo ? "Licence Démonstration Beta!" : "Licence Finale!";
            });
          } else {
            setState(() {
              _statusMessage2 = "Code incorrect!";
            });
          }
        } else {
          setState(() {
            _statusMessage2 =
                "Données de licence incomplètes dans la base de données.";
          });
        }
      } else {
        setState(() {
          _statusMessage2 =
              "Code incorrect ou non trouvé dans la base de données.";
        });
      }
    } catch (e) {
      print('Erreur lors de la requête Supabase: $e');

      // Utiliser les données locales pour vérifier le temps restant
      final remainingDays = await _getRemainingDays();
      final isDemo = await _isDemoLicense();

      if (remainingDays == -1) {
        setState(() {
          _statusMessage2 = "Aucune licence valide trouvée.";
        });
      } else if (remainingDays == 0) {
        setState(() {
          _statusMessage2 =
              "Licence expirée ou utilisation hors ligne dépassée.";
        });
      } else {
        setState(() {
          _statusMessage2 = isDemo
              ? "Licence Démonstration Beta! Jours restants: $remainingDays"
              : "Licence Finale! Jours restants: $remainingDays";
        });
      }
    }
  }

  Future<int> _getRemainingDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final expiresAtString = prefs.getString('licenseExpiresAt');
    final lastOnlineCheckString = prefs.getString('lastOnlineCheck');

    if (expiresAtString == null || lastOnlineCheckString == null) {
      return -1; // Aucune licence valide trouvée
    }

    final expiresAt = DateTime.parse(expiresAtString);
    final now = DateTime.now();
    final offlineDuration =
        now.difference(DateTime.parse(lastOnlineCheckString));

    if (offlineDuration.inDays > 2) {
      return 0; // Bloquer l'application après 2 jours hors ligne
    }

    final remainingTime = expiresAt.difference(now);
    return remainingTime.inDays;
  }

  Future<bool> _isDemoLicense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDemoLicense') ?? false;
  }

  void _disableInput(Duration duration) {
    setState(() {
      _statusMessage2 =
          "Entrée désactivée pendant ${duration.inMinutes} minutes.";
    });
    Future.delayed(duration, () {
      setState(() {
        _statusMessage2 = "";
      });
    });
  }

  bool validateNumHash(
      String enteredHash, String hash512, String p4ssw0rd, int lengthPin) {
    // Implémentez votre logique de validation ici
    return enteredHash == hash512; // Exemple simplifié
  }

  void _saveLicenseStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLicenseValidated', status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLicenseValidated || _isLicenseDemoValidated
          ? MyMain() // Afficher l'écran principal si une licence est valide
          : hashPage(), // Afficher la page de saisie du hash sinon
    );
  }
}
