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
      body: Consumer<CartProvider>(builder: (context, cartProvider, child) {
        return KeyboardListener(
            focusNode: _invisibleFocusNode,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  // Si _barcodeBuffer est vide, utiliser la valeur du TextFormField
                  if (_barcodeBuffer.isEmpty || _barcodeBuffer.trim().isEmpty) {
                    _barcodeBuffer = _barcodeBufferController.text;
                  }

                  // Vérifiez si le buffer contient une valeur valide avant de convertir
                  if (_barcodeBuffer.isNotEmpty &&
                      double.tryParse(_barcodeBuffer) != null) {
                    _processBarcode(
                      context,
                      commerceProvider,
                      cartProvider,
                      double.parse('1'),
                      cartProvider.facture.lignesDocument,
                    );
                  } else {
                    // Afficher un message d'erreur ou nettoyer le buffer si la valeur n'est pas valide
                    print(
                        'Erreur: Valeur du buffer invalide pour double.parse()');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Entrée invalide. Veuillez entrer un code valide.')),
                    );
                    _barcodeBuffer = ''; // Réinitialiser le buffer
                  }
                } else {
                  // Ajouter le caractère entré au buffer
                  _barcodeBuffer += event.character ?? '';
                }
              }
            },
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildClientInfo(context, cartProvider),
                    Expanded(
                      flex: 3,
                      child: Card(
                        color: Colors.green,
                        child: Container(
                          height: 146,
                          child: Center(
                            child: FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  NumberFormat.currency(
                                    locale: 'fr_DZ', // Locale pour l'Algérie
                                    symbol: '', // Symbole de la devise
                                    decimalDigits: 2, // Nombre de décimales
                                  ).format(totalAmount + tva - _localImpayer),
                                  style: TextStyle(
                                      fontSize: 100,
                                      color: Colors.white,
                                      fontFamily: 'oswald',
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        height: 146,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total: ${totalAmount.toStringAsFixed(2)} DZD',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'TVA (19%): ${tva.toStringAsFixed(2)} DZD',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Total TTC: ${(totalAmount + tva).toStringAsFixed(2)} DZD',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            _localImpayer > 0.9
                                ? Text(
                                    'Impayés: ${_localImpayer.toStringAsFixed(2)} DZD',
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 20,
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ProductSearch(context, commerceProvider, cartProvider),
                buildColumn(context, cartProvider, items, totalAmount, tva,
                    _localImpayer, _isEditingImpayer, commerceProvider),
              ],
            ));
      }),
    );
  }

  Row ProductSearch(BuildContext context, CommerceProvider commerceProvider,
      CartProvider cartProvider) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _barcodeBufferController,
              decoration: InputDecoration(
                labelText: 'Code Produit (ID ou QR)',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) {
                if (value.isEmpty || value.trim().isEmpty) {
                  value = _barcodeBufferController.text;
                }

                if (value.isNotEmpty && double.tryParse(value) != null) {
                  _processBarcode(
                    context,
                    commerceProvider,
                    cartProvider,
                    double.parse('1'),
                    cartProvider.facture.lignesDocument,
                  );
                  _barcodeBufferController.clear();
                } else {
                  print(
                      'Erreur: Valeur du buffer invalide pour double.parse()');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Entrée invalide. Veuillez entrer un code valide.')),
                  );
                  value = '';
                }
              },
              onChanged: (value) {
                _barcodeBufferController.text = value;
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                ProductSearchField(_barcodeBufferController, _processBarcode),
          ),
        ),
      ],
    );
  }

  Expanded buildColumn(
      BuildContext context,
      CartProvider cartProvider,
      ToMany<LigneDocument> items,
      double totalAmount,
      double tva,
      double impayer,
      bool _isEditingImpayer,
      CommerceProvider commerceProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildImpayerRow(),
                Spacer(),
                TextButton.icon(
                  onPressed: () {
                    cartProvider.clearCart();
                    _localImpayer = 0;
                    impayer = 0;
                    _impayerController.clear();
                  },
                  label: Text('Nouvel Facture'),
                  icon: Icon(Icons.add),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    // cartProvider.facture.impayer = _localImpayer;
                    // Mettre à jour l'impayé dans le CartProvider avant de sauvegarder
                    cartProvider.facture.impayer = //_localImpayer ?? 0.0;
                        double.tryParse(_impayerController.text) ?? 0.0;

                    try {
                      await cartProvider.saveFacture(commerceProvider);
                      //    _localImpayer = 0.0;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Facture sauvegardée!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                    _localImpayer = 0;
                    impayer = 0;
                    _impayerController.clear();
                  },
                  child: Text('Sauvegarder la facture'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(Colors.blue.shade100),
                    // Couleur de l'entête
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        // Alternance des couleurs des lignes
                        if (states.contains(WidgetState.selected)) {
                          return Colors.grey.shade300;
                        }
                        return null; // Couleur par défaut
                      },
                    ),
                    showBottomBorder: true,
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: 30, // Largeur fixe pour QR
                          child: Text('QR', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 290, // Largeur fixe pour Produit
                          child: Text('Produit', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 50, // Largeur fixe pour Prix
                          child: Text('Prix', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 50, // Largeur fixe pour Quantité
                          child: Text('Quantité', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 50, // Largeur fixe pour Total
                          child: Text('Total', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 50, // Largeur fixe pour Actions
                          child: Text('Actions', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                    rows: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ligneDocument = entry.value;
                      final produit = ligneDocument.produit.target!;
                      final TextEditingController _quantiteController =
                          TextEditingController(
                        text: ligneDocument.quantite.floor().toString(),
                      );
                      final TextEditingController _prixController =
                          TextEditingController(
                        text: ligneDocument.prixUnitaire.floor().toString(),
                      );

                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            // Alternance des couleurs : grise et transparente
                            return index.isEven ? null : Colors.grey.shade200;
                          },
                        ),
                        cells: [
                          DataCell(Text(produit.qr!)),
                          DataCell(Text(produit.nom)),
                          DataCell(Text(
                              ligneDocument.prixUnitaire.toStringAsFixed(2))),
                          DataCell(Text(ligneDocument.quantite.toString())),
                          DataCell(Text((ligneDocument.prixUnitaire *
                                  ligneDocument.quantite)
                              .toStringAsFixed(2))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    _showEditQuantityDialog(
                                        context,
                                        ligneDocument,
                                        _quantiteController,
                                        _prixController);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    cartProvider.removeFromCart(produit);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    // rows: items.map((ligneDocument) {
                    //   final produit = ligneDocument.produit.target!;
                    //   final TextEditingController _quantiteController =
                    //       TextEditingController(
                    //     text: ligneDocument.quantite.floor().toString(),
                    //   );
                    //   final TextEditingController _prixController =
                    //       TextEditingController(
                    //     text: ligneDocument.prixUnitaire.floor().toString(),
                    //   );
                    //   return DataRow(
                    //     cells: [
                    //       DataCell(Text(produit.qr!)),
                    //       DataCell(Text(produit.nom)),
                    //       DataCell(
                    //           Text(ligneDocument.prixUnitaire.toStringAsFixed(2))),
                    //       DataCell(Text(ligneDocument.quantite.toString())),
                    //       DataCell(Text(
                    //           (ligneDocument.prixUnitaire * ligneDocument.quantite)
                    //               .toStringAsFixed(2))),
                    //       DataCell(
                    //         Row(
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [
                    //             IconButton(
                    //               icon: Icon(Icons.edit),
                    //               onPressed: () async {
                    //                 _showEditQuantityDialog(context, ligneDocument,
                    //                     _quantiteController, _prixController);
                    //               },
                    //             ),
                    //             IconButton(
                    //               icon: Icon(
                    //                 Icons.delete,
                    //                 color: Colors.red,
                    //               ),
                    //               onPressed: () {
                    //                 cartProvider.removeFromCart(produit);
                    //               },
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   );
                    // }).toList(),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 50)
        ],
      ),
    );
  }

  Widget _buildImpayerRow() {
    return Consumer<CartProvider>(builder: (context, cartProvider, child) {
      double impayer = 0;
      // widget.factureToEdit != null
      //    ?
      impayer = cartProvider.facture.impayer ?? 0.0;
      _localImpayer = impayer;

      // Synchronisation du TextEditingController avec le Provider
      // if (_impayerController.text != impayer.toStringAsFixed(2)) {
      _impayerController.text = impayer.toStringAsFixed(2);
      //}

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final isCompact = constraints.maxWidth < 700;

          return Container(
            width: isCompact
                ? MediaQuery.of(context).size.width * 0.8
                : MediaQuery.of(context).size.width * 1 / 6,
            child: Row(
              children: [
                _isEditingImpayer
                    ? Flexible(
                        child: TextFormField(
                          controller: _impayerController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Impayés',
                            border: OutlineInputBorder(),
                            suffixText: 'DZD',
                          ),

                          // onChanged: (value) {
                          //   setState(() {
                          //     _localImpayer = double.tryParse(value) ?? 0.00;
                          //   });
                          // },
                          onTap: () {
                            // Effacer le champ si la valeur initiale est 0
                            if (_impayerController.text == '0' ||
                                _impayerController.text == '0.0' ||
                                _impayerController.text == '0.00') {
                              _impayerController.clear();
                            }
                          },
                          autofocus: true,
                        ),
                      )
                    : Text(
                        'Impayés: ${impayer.toStringAsFixed(2)} DZD',
                        style:
                            TextStyle(fontSize: 16, color: Colors.deepOrange),
                      ),
                IconButton(
                  icon: Icon(
                    _isEditingImpayer ? Icons.check : Icons.edit,
                    color: _isEditingImpayer ? Colors.green : Colors.blue,
                    size: _isEditingImpayer ? 22 : 17,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_isEditingImpayer) {
                        // Récupérer la valeur saisie et mettre à jour le Provider
                        final newImpayer =
                            double.tryParse(_impayerController.text) ??
                                _localImpayer;
                        cartProvider.updateImpayer(newImpayer);
                        _localImpayer =
                            newImpayer; // Met à jour la valeur locale
                      } else {
                        // Pré-remplir le TextFormField avec la valeur locale
                        _impayerController.text =
                            _localImpayer.toStringAsFixed(2);
                      }
                      _isEditingImpayer =
                          !_isEditingImpayer; // Alterner entre édition et lecture
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }

  AppBar buildAppBar(BuildContext context, CommerceProvider commerceProvider,
      CartProvider cartProvider) {
    return AppBar(
      title: Text('Facture'),
      actions: [
        // Center(
        //   child: ElevatedButton(
        //     onPressed: () async {
        //       await ObjectBox().cleanQrCodes().whenComplete(() =>
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             SnackBar(content: Text('QR codes nettoyés avec succès.')),
        //           ));
        //     },
        //     child: Text('Nettoyer les QR Codes'),
        //   ),
        // ),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            showSearch(
              context: context,
              delegate: ProduitSearchDelegateMain(commerceProvider),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.account_circle),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ClientSelectionPage(),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.account_circle_outlined),
          onPressed: () async {
            Client? newClient = await showModalBottomSheet<Client>(
              context: context,
              isScrollControlled: true,
              // Permet de redimensionner en fonction de la hauteur du contenu
              builder: (context) => AddClientForm(),
            );

            if (newClient != null) {
              setState(() {
                _selectedClient = newClient;
              });
              cartProvider.setSelectedClient(newClient);
            } else {
              print("Le client n'a pas été créé ou l'opération a été annulée.");
            }
          },
        ),
        kIsWeb ||
                Platform.isWindows ||
                Platform.isLinux ||
                Platform.isFuchsia ||
                Platform.isIOS
            ? Container()
            : IconButton(
                icon: Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BarcodeScannerSimple(), // QRViewExample(),
                    ),
                  );
                  if (result != null) {
                    final produit =
                        await commerceProvider.getProduitByQr(result);
                    if (produit != null) {
                      Provider.of<CartProvider>(context, listen: false)
                          .addToCart(produit);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Produit introuvable!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
        kIsWeb ||
                Platform.isWindows ||
                Platform.isLinux ||
                Platform.isFuchsia ||
                Platform.isIOS
            ? SizedBox(width: 100)
            : SizedBox(width: 0),
      ],
    );
  }

  void _processBarcode(
    BuildContext context,
    CommerceProvider commerceProvider,
    CartProvider cartProvider,
    double enteredQuantity,
    ligneFacture,
  ) async {
    if (_barcodeBuffer.isNotEmpty) {
      final produit = await commerceProvider.getProduitByQr(_barcodeBuffer);

      if (produit == null) {
        _navigateToAddProductPage(context, commerceProvider, cartProvider);
      } else {
        // if (
        //     // enteredQuantity > 0 ||
        //     //     enteredQuantity
        //     ligneFacture.quantite <= ligneFacture.produit.target!.stock) {
        cartProvider.addToCart(produit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit ajouté : ${produit.nom}'),
            backgroundColor: Colors.green,
            showCloseIcon: true,
            duration: _snackBarDisplayDuration(),
          ),
        );
        // } else {
        //   SnackBar(
        //     content: Text(
        //         'La quantité doit être entre 0 et ${ligneFacture.produit.target!.stock}'),
        //     backgroundColor: Colors.green,
        //   );
        // }
      }
      _barcodeBuffer = '';
    }
  }

  void _navigateToAddProductPage(BuildContext context,
      CommerceProvider commerceProvider, CartProvider cartProvider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => addProduct(),
      ),
    );

    if (result != null && result is Produit) {
      cartProvider.addToCart(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nouveau produit ajouté : ${result.nom}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildClientInfo(BuildContext context, CartProvider cartProvider) {
    final client =
        cartProvider.facture.client.target ?? cartProvider.selectedClient;

    return Expanded(
      flex: 3,
      child: Card(
        margin: EdgeInsets.all(8),
        child: InkWell(
          onTap: () async {
            client != null
                ? await Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => ClientDetailsPage(
                      client: client,
                    ),
                  ))
                : await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ClientSelectionPage(),
                    ),
                  );
          },
          child: Padding(
            padding: EdgeInsets.all(8),
            child: client != null
                ? Row(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          cartProvider.resetClient();
                        },
                        child: Container(
                          height: 130,
                          width: 130,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: SfBarcodeGenerator(
                                value: '${client.qr}',
                                symbology: QRCode(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${client.nom.capitalize()}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 25),
                            ),
                            Text(
                              'Téléphone: ${client.phone}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Adresse: ${client.adresse.capitalize()}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Qr: ${client.qr}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Nombre de factures : ${client.factures.length}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Container(
                    height: 130,
                    child: Column(
                      children: [
                        Text(
                          ' ',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(' '),
                        Text(
                          'client non-Identifié...',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(' '),
                        Text(' '),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showEditQuantityDialog(
      BuildContext context,
      LigneDocument ligneFacture,
      TextEditingController _quantiteController,
      TextEditingController _prixController) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Modifier la quantité pour ${ligneFacture.produit.target!.nom}\nReste En Stock  ${ligneFacture.produit.target!.stock.toStringAsFixed(ligneFacture.produit.target!.stock.truncateToDouble() == ligneFacture.produit.target!.stock ? 0 : 2)}'
            //  ${ligneFacture.produit.target!.prixAchat.toStringAsFixed(2)} et ${ligneFacture.produit.target!.prixVente.toStringAsFixed(2)}'
            ,
            textAlign: TextAlign.center,
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _quantiteController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none, // Supprime le contour
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide.none, // Supprime le contour en état normal
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide.none, // Supprime le contour en état focus
                    ),
                    //border: InputBorder.none,
                    filled: true,
                    contentPadding: EdgeInsets.all(15),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une quantité';
                    }
                    final double? enteredQuantity = double.tryParse(value);
                    if (enteredQuantity == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    if (enteredQuantity <= 0)
                      return 'La quantité doit être Superieur à 0.0';

                    if (enteredQuantity > ligneFacture.produit.target!.stock) {
                      return 'La quantité doit être entre 0.0 et ${ligneFacture.produit.target!.stock.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: _prixController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Prix',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none, // Supprime le contour
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide.none, // Supprime le contour en état normal
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide.none, // Supprime le contour en état focus
                    ),
                    //border: InputBorder.none,
                    filled: true,
                    contentPadding: EdgeInsets.all(15),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une Prix';
                    }
                    final double? enteredPrice = double.tryParse(value);
                    if (enteredPrice == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    if (enteredPrice <= 0)
                      return 'La Prix doit être Superieur à 0.0';
                    if ( //enteredPrice < ligneFacture.produit.target!.prixAchat ||
                        enteredPrice > ligneFacture.produit.target!.prixVente) {
                      return 'La Prix doit être entre'
                          //  ${ligneFacture.produit.target!.prixAchat.toStringAsFixed(2)}
                          'et ${ligneFacture.produit.target!.prixVente.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final double newQuantity =
                      double.parse(_quantiteController.text);
                  final double newPrice = double.parse(_prixController.text);
                  ligneFacture.quantite = newQuantity;
                  ligneFacture.prixUnitaire = newPrice;
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Duration _snackBarDisplayDuration() {
    return Duration(seconds: 1); // Afficher la SnackBar pendant 1 secondes
  }
}
