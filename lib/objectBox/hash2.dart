// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';
//
// class QRScannerPage extends StatefulWidget {
//   final int lengthPin;
//   final String p4ssw0rd;
//
//   const QRScannerPage(
//       {Key? key, required this.lengthPin, required this.p4ssw0rd})
//       : super(key: key);
//
//   @override
//   State<QRScannerPage> createState() => _QRScannerPageState();
// }
//
// class _QRScannerPageState extends State<QRScannerPage>
//     with WidgetsBindingObserver {
//   MobileScannerController? controller;
//   String? qrCodeHash;
//   String? qrCodeNumHash;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     controller = MobileScannerController(
//       detectionSpeed: DetectionSpeed.noDuplicates,
//       facing: CameraFacing.back,
//     );
//     _startScanner();
//   }
//
//   void _startScanner() {
//     controller?.start();
//     _resetQrCodeData();
//   }
//
//   void _resetQrCodeData() {
//     setState(() {
//       qrCodeHash = null;
//       qrCodeNumHash = null;
//     });
//   }
//
//   void _processBarcode(String rawValue) {
//     setState(() {
//       qrCodeHash = generateHash(rawValue, widget.p4ssw0rd);
//       qrCodeNumHash =
//           generateNumHash(rawValue, widget.p4ssw0rd, widget.lengthPin);
//     });
//   }
//
//   String generateHash(String input, String password) {
//     var bytes = utf8.encode(input + password);
//     var digest = sha256.convert(bytes);
//     return digest.toString();
//   }
//
//   String generateNumHash(String input, String password, int length) {
//     var hash = generateHash(input, password);
//     var numericHash = hash.replaceAll(RegExp(r'[a-zA-Z]'), '');
//     return numericHash.substring(0, length.clamp(0, numericHash.length));
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (controller == null) return;
//
//     if (state == AppLifecycleState.resumed) {
//       controller?.start();
//     } else if (state == AppLifecycleState.inactive) {
//       controller?.stop();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan QR Code')),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 4,
//             child: MobileScanner(
//               controller: controller,
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 for (final barcode in barcodes) {
//                   _processBarcode(barcode.rawValue ?? '');
//                 }
//               },
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('QR Code Hash: ${qrCodeHash ?? "Not scanned"}'),
//                   Text('Numeric Hash: ${qrCodeNumHash ?? "Not scanned"}'),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     controller?.dispose();
//     super.dispose();
//   }
// }
