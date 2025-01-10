import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/src/relations/to_many.dart';
import 'package:provider/provider.dart';
import '../../Entity.dart';
import '../../MyProviders.dart';
import '../../Utils/mobile_scanner/barcode_scanner_simple.dart';
import '../ClientListScreen.dart';
import '../FactureListScreen.dart';
import '../ProduitListScreen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../addProduct.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import 'uiPos_Widgets.dart';

class FacturePage extends StatefulWidget {
  FacturePage({Key? key, this.factureToEdit}) : super(key: key);

  Document? factureToEdit; // Nouvelle propriété

  @override
  State<FacturePage> createState() => _FacturePageState();
}

class _FacturePageState extends State<FacturePage> {
  Client? _selectedClient;
  String _barcodeBuffer = '';
  late FocusNode _invisibleFocusNode;
  bool _isEditingImpayer = false;
  double _localImpayer = 0.0;
  bool isEditing = false;

  final TextEditingController _impayerController = TextEditingController();
  final TextEditingController _barcodeBufferController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _invisibleFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invisibleFocusNode.requestFocus();
    });

    // if (widget.factureToEdit != null) {
    //   Future.microtask(() {
    //     final cartProvider = Provider.of<CartProvider>(context, listen: false);
    //
    //     isEditing = true;
    //     cartProvider.loadFactureForEditing(widget.factureToEdit!);
    //
    //     if (widget.factureToEdit!.client.target != null) {
    //       _selectedClient = widget.factureToEdit!.client.target;
    //       cartProvider.setSelectedClient(_selectedClient!);
    //     }
    //   });
    // }
    _loadFactureData();
  }

  void _loadFactureData() {
    if (widget.factureToEdit != null) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Charger les données de la facture
      isEditing = true;
      cartProvider.loadFactureForEditing(widget.factureToEdit!);

      // Mettre à jour l'impayé
      _localImpayer = widget.factureToEdit!.impayer ?? 0.00;
      _impayerController.text = _localImpayer.toStringAsFixed(2);

      // Mettre à jour le client sélectionné
      if (widget.factureToEdit!.client.target != null) {
        _selectedClient = widget.factureToEdit!.client.target;
        cartProvider.setSelectedClient(_selectedClient!);
      }
    } else {
      // Réinitialiser les valeurs si aucune facture n'est sélectionnée
      _localImpayer = 0.0;
      _impayerController.text = _localImpayer.toStringAsFixed(2);
      _selectedClient = null;
    }
  }

  @override
  void dispose() {
    _invisibleFocusNode.dispose();
    _impayerController.dispose();
    _localImpayer = 0.0;
    _barcodeBufferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commerceProvider = Provider.of<CommerceProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final clientProvider = Provider.of<ClientProvider>(context);
    final items = cartProvider.facture.lignesDocument;
    final totalAmount = cartProvider.totalAmount;
    final tva = totalAmount * 0.19; // TVA à 19%
    // widget.factureToEdit != null
    //     ? _localImpayer = cartProvider.facture.impayer ?? 0
    //     : _localImpayer = double.tryParse(_impayerController.text) ?? 0;

    return Scaffold(
      //appBar: buildAppBar(context, commerceProvider, cartProvider),
      body: KeyboardListener(
          focusNode: _invisibleFocusNode,
          autofocus: true,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // _buildClientInfo(context, cartProvider),
                  ClientInfo(
                      // cartProvider: cartProvider
                      ),
                  TTC(
                      totalAmount: totalAmount,
                      tva: tva,
                      localImpayer: _localImpayer),
                  TotalDetail(
                      totalAmount: totalAmount,
                      tva: tva,
                      localImpayer: _localImpayer),
                ],
              ),
              // ProductSearch(context, commerceProvider, cartProvider),
              ProductSearchBar(
                  // commerceProvider: commerceProvider,
                  // cartProvider: cartProvider,
                  barcodeBuffer: _barcodeBuffer,
                  barcodeBufferController: _barcodeBufferController),
              buildColumn(
                // commerceProvider: commerceProvider,
                // cartProvider: cartProvider,
                localImpayer: _localImpayer,
                impayerController: _impayerController,
                items: items,
                isEditingImpayer: _isEditingImpayer,
              )
            ],
          )),
    );
  }
}

// onKeyEvent: (KeyEvent event) async {
// if (event is KeyDownEvent) {
// if (event.logicalKey == LogicalKeyboardKey.enter) {
// // Si _barcodeBuffer est vide, utiliser la valeur du TextFormField
// if (_barcodeBuffer.isEmpty || _barcodeBuffer.trim().isEmpty) {
// _barcodeBuffer = _barcodeBufferController.text;
// }
//
// // Vérifiez si le buffer contient une valeur valide avant de continuer
// if (_barcodeBuffer.isNotEmpty &&
// double.tryParse(_barcodeBuffer) != null) {
// // Récupérer le produit via le code QR
// final produit =
// await commerceProvider.getProduitByQr(_barcodeBuffer);
//
// if (produit == null) {
// // Naviguer vers la page d'ajout de produit
// final result = await Navigator.push(
// context,
// MaterialPageRoute(builder: (context) => addProduct()),
// );
//
// // Si un produit est ajouté avec succès, l'ajouter au panier
// if (result != null && result is Produit) {
// cartProvider.addToCart(result);
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(
// content:
// Text('Nouveau produit ajouté : ${result.nom}'),
// backgroundColor: Colors.green,
// ),
// );
// }
// } else {
// // Ajouter le produit existant au panier
// cartProvider.addToCart(produit);
// ScaffoldMessenger.of(context).showSnackBar(
// SnackBar(
// content: Text('Produit ajouté : ${produit.nom}'),
// backgroundColor: Colors.green,
// duration: Duration(seconds: 1),
// ),
// );
// }
//
// // Réinitialiser le buffer
// _barcodeBuffer = '';
// } else {
// // Afficher un message d'erreur si la valeur est invalide
// ScaffoldMessenger.of(context).showSnackBar(
// const SnackBar(
// content: Text(
// 'Entrée invalide. Veuillez entrer un code valide.'),
// backgroundColor: Colors.red,
// ),
// );
// _barcodeBuffer = ''; // Réinitialiser le buffer
// }
// } else {
// // Ajouter le caractère entré au buffer
// _barcodeBuffer += event.character ?? '';
// }
// }
// },
