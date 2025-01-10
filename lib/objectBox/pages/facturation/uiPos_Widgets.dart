import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import '../../../objectbox.g.dart';
import '../../Entity.dart';
import '../../MyProviders.dart';
import '../ClientListScreen.dart';
import '../FactureListScreen.dart';
import '../addProduct.dart';
import 'buildImpayerRow.dart';

class ClientInfo extends StatefulWidget {
  const ClientInfo({Key? key}) : super(key: key);

  @override
  State<ClientInfo> createState() => _ClientInfoState();
}

class _ClientInfoState extends State<ClientInfo> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final client =
        cartProvider.facture.client.target ?? cartProvider.selectedClient;

    return Expanded(
      flex: 3,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: InkWell(
          onTap: () async {
            // Naviguer vers la page appropriée selon que le client est défini ou non
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => client != null
                    ? ClientDetailsPage(client: client)
                    : ClientSelectionPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: client != null
                ? Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 130,
                            width: 130,
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: SfBarcodeGenerator(
                                value: client.qr ?? '',
                                symbology: QRCode(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Client: ${client.nom.capitalize()}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18),
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
                      ),
                      IconButton(
                        color: Colors.black54,
                        onPressed: () {
                          setState(() {
                            cartProvider.resetClient(); // Réinitialiser
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      height: 130,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Client non identifié...',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class TTC extends StatelessWidget {
  const TTC({
    super.key,
    required this.totalAmount,
    required this.tva,
    required double localImpayer,
  }) : _localImpayer = localImpayer;

  final double totalAmount;
  final double tva;
  final double _localImpayer;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}

class TotalDetail extends StatelessWidget {
  const TotalDetail({
    super.key,
    required this.totalAmount,
    required this.tva,
    required double localImpayer,
  }) : _localImpayer = localImpayer;

  final double totalAmount;
  final double tva;
  final double _localImpayer;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }
}

class ProductSearchBar extends StatefulWidget {
  const ProductSearchBar({
    Key? key,
    // required this.commerceProvider,
    // required this.cartProvider,
    required barcodeBuffer,
    required TextEditingController barcodeBufferController,
  })  : _barcodeBufferController = barcodeBufferController,
        _barcodeBuffer = barcodeBuffer,
        super(key: key);

  // final CommerceProvider commerceProvider;
  // final CartProvider cartProvider;
  final TextEditingController _barcodeBufferController;
  final String _barcodeBuffer;

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final commerceProvider = Provider.of<CommerceProvider>(context);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: widget._barcodeBufferController,
              decoration: InputDecoration(
                labelText: 'Code Produit (ID ou QR)',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) {
                if (value.isEmpty || value.trim().isEmpty) {
                  value = widget._barcodeBufferController.text;
                }

                if (value.isNotEmpty && double.tryParse(value) != null) {
                  // _processBarcode(
                  //   context,
                  //   commerceProvider,
                  //   cartProvider,
                  //   double.parse('1'),
                  //   cartProvider.facture.lignesDocument,
                  // );
                  widget._barcodeBufferController.clear();
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
                widget._barcodeBufferController.text = value;
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ProductSearchField(
                widget._barcodeBufferController, _processBarcode),
          ),
        ),
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
    if (widget._barcodeBuffer.isNotEmpty) {
      final produit =
          await commerceProvider.getProduitByQr(widget._barcodeBuffer);

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

  Duration _snackBarDisplayDuration() {
    return Duration(seconds: 1); // Afficher la SnackBar pendant 1 secondes
  }
}

class buildColumn extends StatefulWidget {
  buildColumn({
    Key? key,
    // required this.commerceProvider,
    // required this.cartProvider,
    required isEditingImpayer,
    required double localImpayer,
    required TextEditingController impayerController,
    required this.items,
  })  : _impayerController = impayerController,
        _isEditingImpayer = isEditingImpayer,
        _localImpayer = localImpayer,
        super(key: key);

  // final CommerceProvider commerceProvider;
  // final CartProvider cartProvider;
  final TextEditingController _impayerController;
  ToMany<LigneDocument> items;
  bool _isEditingImpayer;
  double _localImpayer;

  @override
  State<buildColumn> createState() => _buildColumnState();
}

class _buildColumnState extends State<buildColumn> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final commerceProvider = Provider.of<CommerceProvider>(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                buildImpayerRow(
                    isEditingImpayer: widget._isEditingImpayer,
                    localImpayer: widget._localImpayer,
                    impayerController: widget._impayerController),
                Spacer(),
                TextButton.icon(
                  onPressed: () {
                    cartProvider.clearCart();
                    widget._localImpayer = 0;

                    widget._impayerController.clear();
                  },
                  label: Text('Nouvel Facture'),
                  icon: Icon(Icons.add),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    // cartProvider.facture.impayer = _localImpayer;
                    // Mettre à jour l'impayé dans le CartProvider avant de sauvegarder
                    cartProvider.facture.impayer =
                        //_localImpayer ?? 0.0;
                        double.tryParse(widget._impayerController.text) ?? 0.0;

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
                    widget._localImpayer = 0;

                    widget._impayerController.clear();
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
                    rows: widget.items.asMap().entries.map((entry) {
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
}
