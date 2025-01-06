// import 'package:multicast_dns/multicast_dns.dart';
// import 'package:objectbox/objectbox.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:network_info_plus/network_info_plus.dart';
//
// import '../../../objectbox.g.dart';
//
// class DatabaseManager {
//   static const String _serviceName = '_myapp._tcp';
//   static const int _port = 8090;
//
//   Future<Store> getStore() async {
//     if (Platform.isAndroid) {
//       final desktopIp = await _findDesktopApp();
//       if (desktopIp != null) {
//         final authorized = await _requestAuthorization(desktopIp);
//         if (authorized) {
//           return _connectToDesktopDB(desktopIp);
//         }
//       }
//       return _useLocalAndroidDB();
//     } else if (Platform.isWindows) {
//       return _useLocalWindowsDB();
//     } else {
//       throw UnsupportedError('Plateforme non supportée');
//     }
//   }
//
//   Future<String?> _findDesktopApp() async {
//     final mdns = MDnsClient();
//     await mdns.start();
//
//     try {
//       await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
//           ResourceRecordQuery.serverPointer(_serviceName))) {
//         await for (final SrvResourceRecord srv
//             in mdns.lookup<SrvResourceRecord>(
//                 ResourceRecordQuery.service(ptr.domainName))) {
//           return srv.target;
//         }
//       }
//     } finally {
//       mdns.stop();
//     }
//     return null;
//   }
//
//   Future<bool> _requestAuthorization(String desktopIp) async {
//     // Implémentez ici la logique pour demander l'autorisation
//     // Par exemple, en utilisant une connexion socket pour communiquer avec l'app desktop
//     // Retournez true si l'autorisation est accordée, false sinon
//     return true; // Pour cet exemple, on suppose toujours l'autorisation accordée
//   }
//
//   Future<Store> _connectToDesktopDB(String desktopIp) async {
//     final dbPath = '\\\\$desktopIp\\shared\\mydb.obx';
//     return await openStore(getObjectBoxModel(), directory: dbPath);
//   }
//
//   Future<Store> _useLocalAndroidDB() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final dbPath = '${directory.path}/localdb.obx';
//     return await openStore(getObjectBoxModel(), directory: dbPath);
//   }
//
//   Future<Store> _useLocalWindowsDB() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final dbPath = '${directory.path}\\localdb.obx';
//     return await openStore(getObjectBoxModel(), directory: dbPath);
//   }
// }
//
// // Utilisation
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final dbManager = DatabaseManager();
//   final store = await dbManager.getStore();
//
//   // Utilisez le store pour vos opérations de base de données
//   //runApp(MyApp(store: store));
// }
