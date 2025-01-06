import 'dart:async';
// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez cette ligne
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import 'dart:convert';
import 'objectBox/MyApp.dart';
import 'objectBox/hash.dart';

///gere les gestu
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      };
}


//late ObjectBox objectbox;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
// Vérifier que la plateforme est desktop avant d'initialiser window_manager
  if (!Platform.isAndroid && !Platform.isIOS) {
    // Initialiser window_manager uniquement pour les plateformes desktop
    await windowManager.ensureInitialized();

    // Désactiver le redimensionnement
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1920, 1080), // Taille initiale (mode desktop)
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
      // fullScreen: true,
      // skipTaskbar: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager
          .setResizable(false); // Désactiver redimensionnement manuel
      await windowManager.show();
    });
  }

  initializeDateFormatting(
      'fr_FR', null); // Initialisez la localisation française
  if (Platform.isAndroid || Platform.isIOS) {
    MobileAds.instance.initialize();
  } else {
    print("Google Mobile Ads n'est pas supporté sur cette plateforme");
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //final objectBox = await ObjectBox.create();
  await Supabase.initialize(
    url: 'https://wirxpjoeahuvjoocdnbk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indpcnhwam9lYWh1dmpvb2NkbmJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTYxNjI0MzAsImV4cCI6MjAzMTczODQzMH0.MQpp7i2TdH3Q5aPEbMq5qvUwbuYpIX8RccW_GH64r1U',
  );

///////////////////////////////////////////////////////////////////////////////////////////
//   final String message = 'objectbox-desktop-service';
//   final List<int> data = utf8.encode(message);
//
//   // Create a UDP socket
//   final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8081);
//   print('UDP server listening on port ${socket.port}');
//
//   socket.listen((RawSocketEvent event) {
//     if (event == RawSocketEvent.read) {
//       Datagram? dg = socket.receive();
//       if (dg != null) {
//         print(
//             'Received from ${dg.address.address}:${dg.port}: ${utf8.decode(dg.data)}');
//       }
//     }
//   });
//
//   // Broadcast the presence of the desktop application
//   Timer.periodic(Duration(seconds: 5), (Timer t) {
//     try {
//       socket.send(data, InternetAddress('255.255.255.255'), 8081);
//       print('Broadcast message sent');
//     } catch (e) {
//       print('Error sending broadcast: $e');
//     }
//   });
///////////////////////////////////////////////////////////////////////////////////////////////////////
  // splash.FlutterNativeSplash.removeAfter(initialization);
  //WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  //splash.FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());

  SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge, //.immersiveSticky,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  runApp(
    MyApp(
        // objectBox: objectBox,
        ),
  );
}

// Future<Database> initsembastDatabase() async {
//   final appDocumentDir = await getApplicationDocumentsDirectory();
//   final dbPath = p.join(appDocumentDir.path, 'my_sembast_database.db');
//   final database = await databaseFactoryIo.openDatabase(dbPath);
//   return database;
// }
//FlutterNativeSplash.remove();

Future initialization(BuildContext? context) async {
  Future.delayed(Duration(seconds: 5));
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  MyApp({
    super.key,
    /*required this.objectBox*/
  });
//  final ObjectBox objectBox;
//   static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
//   static FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

  static const String _title = 'DZ Wallet';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool _isLicenseValidated = false;
  //final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    _checkLicenseStatus();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        scrollBehavior:
        CustomScrollBehavior(), // Applique le nouveau ScrollBehavior
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'OSWALD',
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
          ),
        ),
        locale: const Locale('fr', 'CA'),

        //scaffoldMessengerKey: Utils.messengerKey,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Ramzi',
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
          ),
        ),
        home: Platform.isAndroid || Platform.isIOS
            ? MyMain()
            : _isLicenseValidated
            ? MyMain()
            : hashPage()
      // verifi_auth2(
      //     // objectBox: objectBox,
      //     ),
    );
  }

  @override
  void dispose() {

    super.dispose();
  }
}

class homeRescouse extends StatelessWidget {
  const homeRescouse({super.key});

  @override
  Widget build(BuildContext context) {
    return   MaterialApp(
            scrollBehavior:
            CustomScrollBehavior(), // Applique le nouveau ScrollBehavior
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              fontFamily: 'OSWALD',
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
              ),
            ),
            locale: const Locale('fr', 'CA'),

            //scaffoldMessengerKey: Utils.messengerKey,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Ramzi',
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.blueGrey,
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
              ),
            ),
            home: Center(child: Text('teste123265489798'),)
     );
  }
}
