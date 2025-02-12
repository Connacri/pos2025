import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show Platform, Process, ProcessResult;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:pincode_input_fields/pincode_input_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'MyApp.dart';

class hashPage extends StatefulWidget {
  @override
  _hashPageState createState() => _hashPageState();
}

class _hashPageState extends State<hashPage> {
  String _deviceIdentifier = '';
  String _hash512 = '';
  String _shortHash = '';
  String _numHash = '';
  String _enteredHash = '';
  String _p4ssw0rd = "Oran2024";
  String _p4ssw0rdSupabase = '';
  bool _isShowMessage = false;
  bool _isLicenseValidated = false;
  bool _isLicenseDemoValidated = false;
  String _statusMessage = "Entrer le Code PIN";
  int _lengthPin = 10;
  int _attempts = 0;
  String _statusMessage2 = "";
  bool _isInputDisabled = false;

  @override
  void initState() {
    super.initState();
    _initDeviceIdentifier();
    _checkLicenseStatus();
  }

  Future<void> _initDeviceIdentifier() async {
    String? identifier = await getDeviceIdentifier();
    if (identifier != null) {
      if (mounted) {
        setState(() {
          _deviceIdentifier = identifier;
          _hash512 = generateHash(_deviceIdentifier, _p4ssw0rd);
          _shortHash = generateShortHash(_hash512, _p4ssw0rd);
          _numHash = generateNumHash(_hash512, _p4ssw0rd, _lengthPin);
        });
      }
    }
  }

  Future<void> _checkLicenseStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLicenseValidated = prefs.getBool('isLicenseValidated');
    if (isLicenseValidated != null && isLicenseValidated) {
      setState(() {
        _isLicenseValidated = true;
      });
    }
  }

  Future<void> _saveLicenseStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLicenseValidated', status);
  }

  Future<void> _saveLicenseDemoStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLicenseDemoValidated', status);
  }

  Future<void> _removeLicenseStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLicenseValidated');
    setState(() {
      _isLicenseValidated = false;
      _statusMessage = "Entrer le PIN (depuis l'application mobile)";
    });
  }

  void _disableInput(Duration duration) {
    setState(() {
      _isInputDisabled = true;
    });
    Timer(duration, () {
      setState(() {
        _isInputDisabled = false;
      });
    });
  }

  bool _showMacAndPhoneFields = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Licence App'),
        actions: [
          IconButton(
            onPressed: () async {
              await getDeviceIdentifier();
            },
            icon: Icon(
              Icons.verified,
              color: Colors.blue,
            ),
          ),
          Platform.isAndroid || Platform.isIOS
              ? IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => HashAdmin(lengthPin: _lengthPin)));
                  },
                  icon: Icon(Icons.add_chart_rounded),
                )
              : Container(),
          SizedBox(
            width: 50,
          ),
        ],
      ),
      body: _isLicenseValidated || _isLicenseDemoValidated
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                Lottie.asset('assets/lotties/1 (28).json'),
                Spacer(),
                Center(
                  child: FutureBuilder<int>(
                    future: _getRemainingDays(), // Récupérer les jours restants
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Afficher un indicateur de chargement pendant que les données sont récupérées
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        // Gérer les erreurs
                        return Text(
                          "Erreur lors de la récupération des jours restants.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 25, color: Colors.red),
                        );
                      } else {
                        final remainingDays = snapshot.data ??
                            -1; // Valeur par défaut si non trouvée
                        return Text(
                          _isLicenseDemoValidated
                              ? "Licence Démonstration de 30 Jours,\nJours restants : $remainingDays\nL'application est activée Temporairement."
                              : "Licence validée,\nL'application est activée.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 25, color: Colors.green),
                        );
                      }
                    },
                  ),
                ),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _removeLicenseStatus();
                    },
                    child: Text('Delete Licence'),
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.red),
                      foregroundColor:
                          WidgetStateProperty.all<Color>(Colors.white),
                    ),
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MyMain()),
                    );
                  },
                  label: Text('Go to Home'),
                  icon: Icon(Icons.home),
                ),
                Spacer(),
                Spacer(),
                Spacer(),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Ce QR code doit etre scanner par un Admin"),
                  Spacer(),
                  Container(
                    child: _hash512.isNotEmpty
                        ? Center(
                            child: PrettyQr(
                              data: _hash512.toString(),
                              size: 200.0,
                              elementColor: Theme.of(context).hintColor,
                            ),
                          )
                        : CircularProgressIndicator(),
                  ),
                  Spacer(),
                  // Divider(),
                  // SelectableText(
                  //   generateHash(_deviceIdentifier, _p4ssw0rd), //_hash512
                  //   textAlign: TextAlign.center,
                  // ),
                  // Divider(),
                  // SelectableText(generateShortHash(_hash512, _p4ssw0rd)),
                  // Divider(),
                  // SelectableText(
                  //     generateNumHash(_hash512, _p4ssw0rd, _lengthPin)),
                  // Divider(),
                  Spacer(),
                  Center(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage == "Licence Numerique validée!"
                            ? Colors.green
                            : _statusMessage == "PIN Hash incorrect!"
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Center(
                  //   child: PincodeInputFields(
                  //     onChanged: (value) {
                  //       setState(() {
                  //         _enteredHash = value;
                  //       });
                  //     },
                  //     // onInputComplete: () {
                  //     //   if (validateNumHash(
                  //     //       _enteredHash, _hash512, _p4ssw0rd)) {
                  //     //     ScaffoldMessenger.of(context).showSnackBar(
                  //     //       SnackBar(
                  //     //           content: Text("Licence Numerique validée!")),
                  //     //     );
                  //     //     _saveLicenseStatus(true);
                  //     //     setState(() {
                  //     //       _isLicenseValidated = true;
                  //     //     });
                  //     //   } else {
                  //     //     ScaffoldMessenger.of(context).showSnackBar(
                  //     //       SnackBar(content: Text("num Hash incorrect!")),
                  //     //     );
                  //     //   }
                  //     // },
                  //     onInputComplete: () {
                  //       setState(() {
                  //         _statusMessage = "Validation en cours...";
                  //       });
                  //
                  //       Future.delayed(Duration(seconds: 2), () {
                  //         if (validateNumHash(
                  //             _enteredHash, _hash512, _p4ssw0rd, _lengthPin)) {
                  //           _saveLicenseStatus(true);
                  //           setState(() {
                  //             _isLicenseValidated = true;
                  //             _statusMessage = "Licence Numérique validée!";
                  //           });
                  //         } else {
                  //           setState(() {
                  //             _statusMessage = "PIN Hash incorrect!";
                  //           });
                  //         }
                  //       });
                  //     },
                  //     autoFocus: true,
                  //     length: _lengthPin,
                  //     heigth: 54,
                  //     width: 51,
                  //     borderRadius: BorderRadius.circular(9),
                  //     unfocusBorder: Border.all(
                  //       width: 1,
                  //       color: const Color(0xFF5B6774),
                  //     ),
                  //     focusBorder: Border.all(
                  //       width: 1,
                  //       color: const Color(0xFF9B71F4),
                  //     ),
                  //     // cursorColor: Colors.white,
                  //     cursorWidth: 2,
                  //     focusFieldColor: const Color(0xFFB1B8F1),
                  //     //unfocusFieldColor: const Color(0xFF2A2B32),
                  //     textStyle: const TextStyle(
                  //       color: Colors.black54,
                  //       fontSize: 21,
                  //     ),
                  //   ),
                  // ),
                  PincodeInputFields(
                    onChanged: (value) {
                      setState(() {
                        _enteredHash = value;
                      });
                    },
                    // onInputComplete: () {
                    //   setState(() {
                    //     _statusMessage = "Validation en cours...";
                    //   });
                    //   //////////////////Licence Démonstration Beta!//////////////////
                    //   checkAndValidateDemoLicense();
                    //   ///////////////////////////////////////////////////////////////
                    //   Future.delayed(Duration(seconds: 2), () {
                    //     if (validateNumHash(
                    //         _enteredHash, _hash512, _p4ssw0rd, _lengthPin)) {
                    //       _saveLicenseStatus(true);
                    //       setState(() {
                    //         _isLicenseValidated = true;
                    //         _statusMessage2 = "Licence Numérique validée!";
                    //       });
                    //     } else {
                    //       _attempts++;
                    //       if (_attempts >= 3 && _attempts < 6) {
                    //         _statusMessage2 =
                    //             "PIN Hash incorrect! Tentatives restantes: ${3 - _attempts}";
                    //         if (_attempts == 3) {
                    //           _disableInput(Duration(minutes: 1));
                    //         }
                    //       } else if (_attempts >= 6 && _attempts < 9) {
                    //         _statusMessage2 =
                    //             "PIN Hash incorrect! Tentatives restantes: ${6 - _attempts}";
                    //         if (_attempts == 6) {
                    //           _disableInput(Duration(minutes: 5));
                    //         }
                    //       } else if (_attempts >= 9) {
                    //         _statusMessage2 =
                    //             "Trop de tentatives échouées. Veuillez entrer votre adresse MAC et votre numéro de téléphone.";
                    //         _showMacAndPhoneFields;
                    //       } else {
                    //         _statusMessage2 = "PIN Hash incorrect!";
                    //       }
                    //     }
                    //   });
                    // },
                    onInputComplete: () async {
                      setState(() {
                        _statusMessage = "Validation en cours...";
                      });

                      // Vérifier et valider la licence de démonstration
                      // await checkAndValidateDemoLicense();

                      Future.delayed(Duration(seconds: 2), () async {
                        if (validateNumHash(
                            _enteredHash, _hash512, _p4ssw0rd, _lengthPin)) {
                          await _saveLicenseStatus(true);
                          setState(() {
                            _isLicenseValidated = true;
                            _statusMessage2 = "Licence Numérique validée!";
                          });
                        } else {
                          _attempts++;
                          if (_attempts >= 3 && _attempts < 6) {
                            _statusMessage2 =
                                "PIN Hash incorrect! Tentatives restantes: ${3 - _attempts}";
                            if (_attempts == 3) {
                              _disableInput(Duration(minutes: 1));
                            }
                          } else if (_attempts >= 6 && _attempts < 9) {
                            _statusMessage2 =
                                "PIN Hash incorrect! Tentatives restantes: ${6 - _attempts}";
                            if (_attempts == 6) {
                              _disableInput(Duration(minutes: 5));
                            }
                          } else if (_attempts >= 9) {
                            _statusMessage2 =
                                "Trop de tentatives échouées. Veuillez entrer votre adresse MAC et votre numéro de téléphone.";
                          } else {
                            _statusMessage2 = "PIN Hash incorrect!";
                          }
                        }
                      });
                    },
                    autoFocus: true,
                    length: _lengthPin,
                    heigth: 54,
                    width: 51,
                    borderRadius: BorderRadius.circular(9),
                    unfocusBorder: Border.all(
                      width: 1,
                      color: const Color(0xFF5B6774),
                    ),
                    focusBorder: Border.all(
                      width: 1,
                      color: const Color(0xFF9B71F4),
                    ),
                    cursorWidth: 2,
                    focusFieldColor: const Color(0xFFB1B8F1),
                    textStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 21,
                    ),
                    enabled: !_isInputDisabled,
                  ),
                  SizedBox(height: 16),
                  Text(_statusMessage2),
                  if (_showMacAndPhoneFields)
                    Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Adresse MAC",
                          ),
                          onChanged: (value) {
                            // Save the MAC address value
                          },
                        ),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Numéro de téléphone",
                          ),
                          onChanged: (value) {
                            // Save the phone number value
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Send the MAC address and phone number to the administrator
                          },
                          child: Text("Envoyer"),
                        ),
                      ],
                    ),
                  Spacer(),

                  // _isShowMessage
                  //     ? Center(
                  //         child: Text(
                  //         "Licence Numerique validée!",
                  //         style: const TextStyle(
                  //           color: Colors.green,
                  //           fontSize: 24,
                  //         ),
                  //       ))
                  //     : Center(
                  //         child: Text(
                  //         "num Hash incorrect!",
                  //         style: const TextStyle(
                  //           color: Colors.red,
                  //           fontSize: 24,
                  //         ),
                  //       )),
                  // Spacer(),
                  // Text("Entrer le hash court (depuis l'application mobile):"),
                  // Spacer(),
                  // Container(
                  //   width: Platform.isIOS || Platform.isAndroid
                  //       ? double.infinity
                  //       : 400,
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(8.0),
                  //     child: TextFormField(
                  //       //  keyboardType: TextInputType.number,
                  //       textAlign: TextAlign.center,
                  //       decoration: InputDecoration(
                  //         labelStyle: TextStyle(),
                  //
                  //         border: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(8.0),
                  //           borderSide: BorderSide.none, // Supprime le contour
                  //         ),
                  //         enabledBorder: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(8.0),
                  //           borderSide: BorderSide
                  //               .none, // Supprime le contour en état normal
                  //         ),
                  //         focusedBorder: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(8.0),
                  //           borderSide: BorderSide
                  //               .none, // Supprime le contour en état focus
                  //         ),
                  //         //border: InputBorder.none,
                  //         filled: true,
                  //         contentPadding: EdgeInsets.all(15),
                  //       ),
                  //       onChanged: (value) {
                  //         setState(() {
                  //           _enteredHash = value;
                  //         });
                  //       },
                  //     ),
                  //   ),
                  // ),
                  // Spacer(),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     if (validateHash(_enteredHash, _hash512, _p4ssw0rd)) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(content: Text("Licence validée!")));
                  //       _saveLicenseStatus(true);
                  //       setState(() {
                  //         _isLicenseValidated = true;
                  //       });
                  //     } else {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(content: Text("Hash incorrect!")));
                  //     }
                  //   },
                  //   child: Text("Valider"),
                  // ),
                  Spacer(),
                  Spacer(),
                ],
              ),
            ),
    );
  }

  Future<void> checkAndValidateDemoLicense() async {
    final supabase = Supabase.instance.client;

    try {
      // Vérifier si _enteredHash existe dans la table Supabase
      final response = await supabase
          .from('hashCodeTemp') // Nom de la table
          .select(
              'hash_code, expires_at') // Récupérer le hash_code et la date d'expiration
          .eq('hash_code',
              _enteredHash.trim()) // Vérifier si _enteredHash correspond
          .single(); // Récupérer un seul enregistrement

      // Afficher les détails de la réponse pour le débogage
      print('Response: $response');
      print('_enteredHash: $_enteredHash');

      if (response != null) {
        // Si _enteredHash existe dans Supabase
        print('Code trouvé dans Supabase');
        print('_enteredHash: $_enteredHash');
        print('Response: $response');

        // Récupérer les valeurs de la réponse
        final hashCode = response['hash_code'] as String?;
        final expiresAtString = response['expires_at'] as String?;

        // Vérifier si les champs requis sont non nuls
        if (hashCode != null && expiresAtString != null) {
          // Vérifier si _enteredHash correspond au hash_code dans la réponse
          if (hashCode == _enteredHash.trim()) {
            // Parser la date d'expiration
            final expiresAt = DateTime.parse(expiresAtString);

            // Calculer les jours restants
            final now = DateTime.now();
            final remainingDays = expiresAt.difference(now).inDays;

            // Sauvegarder les informations de la licence dans SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'licenseExpiresAt', expiresAt.toIso8601String());
            await prefs.setInt('remainingDays', remainingDays);

            // Sauvegarder l'état de la licence de démonstration
            await _saveLicenseDemoStatus(true);

            // Mettre à jour l'état de l'application
            setState(() {
              _isLicenseDemoValidated = true;
              _statusMessage2 =
                  "Licence Démonstration Beta! Jours restants: $remainingDays";
            });
          } else {
            // Si _enteredHash ne correspond pas au hash_code dans la réponse
            setState(() {
              _statusMessage2 = "Code incorrect!";
            });
          }
        } else {
          // Si des champs requis sont manquants dans la réponse
          setState(() {
            _statusMessage2 =
                "Données de licence incomplètes dans la base de données.";
          });
        }
      } else {
        // Si _enteredHash n'existe pas dans Supabase
        print('Code non trouvé dans Supabase');
        setState(() {
          _statusMessage2 =
              "Code incorrect ou non trouvé dans la base de données.";
        });
      }
    } catch (e) {
      // Gérer les erreurs de requête (par exemple, absence de connexion Internet)
      print('Erreur lors de la requête Supabase: $e');

      // Utiliser les données locales pour vérifier le temps restant
      final remainingDays = await _getRemainingDays();

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
          _statusMessage2 =
              "Licence Démonstration Beta! Jours restants: $remainingDays";
        });
      }
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
  final lastOnlineCheck = DateTime.parse(lastOnlineCheckString);
  final now = DateTime.now();

  // Vérifier si l'utilisateur est hors ligne depuis plus de 2 jours
  final offlineDuration = now.difference(lastOnlineCheck);
  if (offlineDuration.inDays > 2) {
    return 0; // Bloquer l'application après 2 jours hors ligne
  }

  // Calculer le temps restant
  final remainingTime = expiresAt.difference(now);
  return remainingTime.inDays;
}

Future<String?> getDeviceIdentifier() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // Utilisez Android ID
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo
        .identifierForVendor; // Utilisez l'identifiant pour fournisseur
  } else if (Platform.isLinux) {
    LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
    return linuxInfo.machineId; // Identifiant unique pour Linux
  } else if (Platform.isMacOS) {
    MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
    return macInfo.systemGUID; // Identifiant unique pour macOS
  } else if (Platform.isWindows) {
    WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
    return windowsInfo.deviceId; // Identifiant unique pour Windows
  } else if (kIsWeb) {
    // Pour Flutter Web
    WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
    return webInfo
        .userAgent; // Utilisez le User Agent comme identifiant (limité sur le Web)
  } else {
    // Autres plateformes comme Fuchsia
    return "Unsupported platform";
  }
}

String generateHash(String deviceIdentifier, String password) {
  var bytes = utf8.encode(deviceIdentifier + password);
  var digest = sha512.convert(bytes);
  return digest.toString();
}

String generateShortHash(String _hash512, String password) {
  var bytes = utf8.encode(_hash512 + password);
  var digest = sha1.convert(bytes);
  return digest.toString();
}

bool validateHash(String enteredHash, String _hash512, String password) {
  var calculatedHash = generateShortHash(_hash512, password);
  return enteredHash == calculatedHash;
}

bool validateNumHash(
    String enteredHash, String _hash512, String password, int _lengthPin) {
  var calculatedHash = generateNumHash(_hash512, password, _lengthPin);
  return enteredHash == calculatedHash;
}

String generateNumHash(String _hash512, String password, int _lengthPin) {
  return generateNumericCode(_hash512, password, _lengthPin);
}

String generateNumericCode(String _hash512, String password, int _lengthPin) {
  var bytes = utf8.encode(_hash512 + password);
  var digest = sha256.convert(bytes); // Utilisation de SHA-256
  var hexString = digest.toString();

  // Convertir le hash hexadécimal en un grand entier
  BigInt bigInt = BigInt.parse(hexString, radix: 16);

  // Extraire les 10 premiers chiffres
  String numericCode = bigInt.toString().substring(0, _lengthPin);

  return numericCode;
}

class HashAdmin extends StatefulWidget {
  const HashAdmin({super.key, required this.lengthPin});

  final int lengthPin;

  @override
  _HashAdminState createState() => _HashAdminState();
}

class _HashAdminState extends State<HashAdmin> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  //QRViewController? controller;
  MobileScannerController? controller;
  String? qrCodeHash;
  String? qrCodeNumHash; // Ajout d'une variable pour le hash numérique
  String _p4ssw0rd = "Oran2024";

  @override
  void initState() {
    super.initState();
    _resetQrCodeData(); // Réinitialiser les données QR
  }

  void _resetQrCodeData() {
    qrCodeHash = null;
    qrCodeNumHash = null;
  }

// Fonction à appeler dans initState()
  void _initializeScanner() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _onQRViewCreated(controller!);
  }

  void _onQRViewCreated(MobileScannerController controller) {
    this.controller = controller;
    _resetQrCodeData(); // Réinitialiser les données QR à chaque création de vue
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scanner de QR Code'),
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                // child: QRView(
                //   key: qrKey,
                //   onQRViewCreated: _onQRViewCreated,
                // ),
                // Dans le widget build, remplacez QRView par MobileScanner
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        setState(() {
                          qrCodeHash =
                              generateHash(barcode.rawValue!, _p4ssw0rd);
                          qrCodeNumHash = generateNumHash(
                              barcode.rawValue!, _p4ssw0rd, widget.lengthPin);
                        });
                      }
                    }
                  },
                ),
              ),
              if (qrCodeHash != null)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            //Text('Hash QR code: $qrCodeHash'),
                            FittedBox(
                                child: Text('Serial PIN: $qrCodeNumHash')),
                            // Affichage du code numérique
                            Divider(),
                            // SelectableText(
                            //   generateHash(qrCodeHash!, _p4ssw0rd), //_hash512
                            //   textAlign: TextAlign.center,
                            // ),
                            // Divider(),
                            // SelectableText(generateShortHash(qrCodeHash!, _p4ssw0rd)),
                            // Divider(),

                            // Text('Licence: ' +
                            //     _validateHash(qrCodeHash!, _p4ssw0rd).toString()),
                            // ElevatedButton(
                            //   onPressed: () {
                            //     if (_validateHash(qrCodeHash!, _p4ssw0rd)) {
                            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            //           content: Text("Licence validée avec succès!")));
                            //     } else {
                            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            //           content:
                            //               Text("Hash incorrect, licence invalide!")));
                            //     }
                            //   },
                            //   child: Text('Valider la licence'),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // void _onQRViewCreated(QRViewController controller) {
  //   this.controller = controller;
  //   _resetQrCodeData(); // Réinitialiser les données QR à chaque création de vue
  //   controller.scannedDataStream.listen((scanData) async {
  //     setState(() {
  //       qrCodeHash = generateHash(scanData.code!, _p4ssw0rd);
  //       qrCodeNumHash = generateNumHash(scanData.code!, _p4ssw0rd,
  //           widget.lengthPin); // Génération du code numérique
  //     });
  //   });
  // }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    controller
        ?.dispose(); // Détruire le contrôleur lorsque la page est désactivée
    super.deactivate();
  }

// @override
// void reassemble() {
//   super.reassemble();
//   controller?.pauseCamera(); // Pause la caméra lors du hot reload
//   controller?.resumeCamera(); // Reprendre la caméra après le hot reload
// }
}
