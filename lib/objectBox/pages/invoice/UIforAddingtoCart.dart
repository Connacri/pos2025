import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import '../../../objectbox.g.dart';
import '../../Entity.dart';
import 'package:flutter/services.dart';
import '../addProduct.dart';
import 'providers.dart';

class AddToCartPage extends StatefulWidget {
  @override
  State<AddToCartPage> createState() => _AddToCartPageState();
}

class _AddToCartPageState extends State<AddToCartPage> {
  String _barcodeBuffer = '';
  late FocusNode _invisibleFocusNode;
  bool _isEditingImpayer = false;
  double _localImpayer = 0.0;
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
    final commerceProvider = Provider.of<CommerceProvider1>(context);
    final cartProvider = Provider.of<CartProvider1>(context);
    final items = cartProvider.facture.lignesDocument;
    final totalAmount = cartProvider.totalAmount;
    final tva = totalAmount * 0.19;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add to Cart'),
      ),
      body: KeyboardListener(
        focusNode: _invisibleFocusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_barcodeBuffer.isEmpty || _barcodeBuffer.trim().isEmpty) {
                _barcodeBuffer = _barcodeBufferController.text;
              }

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Entrée invalide. Veuillez entrer un code valide.')),
                );
                _barcodeBuffer = '';
              }
            } else {
              _barcodeBuffer += event.character ?? '';
            }
          }
        },
        child: Column(
          children: [
            Row(
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

                        if (value.isNotEmpty &&
                            double.tryParse(value) != null) {
                          _processBarcode(
                            context,
                            commerceProvider,
                            cartProvider,
                            double.parse('1'),
                            cartProvider.facture.lignesDocument,
                          );
                          _barcodeBufferController.clear();
                        } else {
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
                    child: ProductSearchField(
                        _barcodeBufferController, _processBarcode),
                  ),
                ),
              ],
            ),
            Expanded(
              child: buildColumn(context, cartProvider, items, totalAmount, tva,
                  _localImpayer, _isEditingImpayer, commerceProvider),
            ),
          ],
        ),
      ),
    );
  }

  Column buildColumn(
      BuildContext context,
      CartProvider1 cartProvider,
      ToMany<LigneDocument> items,
      double totalAmount,
      double tva,
      double impayer,
      bool _isEditingImpayer,
      CommerceProvider1 commerceProvider1) {
    return Column(
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
                  cartProvider.facture.impayer =
                      double.tryParse(_impayerController.text) ?? 0.0;

                  try {
                    await cartProvider.saveFacture(commerceProvider1);
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
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.grey.shade300;
                      }
                      return null;
                    },
                  ),
                  showBottomBorder: true,
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: 30,
                        child: Text('QR', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 290,
                        child: Text('Produit', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 50,
                        child: Text('Prix', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 50,
                        child: Text('Quantité', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 50,
                        child: Text('Total', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 50,
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
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50)
      ],
    );
  }

  Widget _buildImpayerRow() {
    return Consumer<CartProvider1>(builder: (context, cartProvider, child) {
      double impayer = 0;
      impayer = cartProvider.facture.impayer ?? 0.0;
      _localImpayer = impayer;

      _impayerController.text = impayer.toStringAsFixed(2);

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
                          onTap: () {
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
                        final newImpayer =
                            double.tryParse(_impayerController.text) ??
                                _localImpayer;
                        cartProvider.updateImpayer(newImpayer);
                        _localImpayer = newImpayer;
                      } else {
                        _impayerController.text =
                            _localImpayer.toStringAsFixed(2);
                      }
                      _isEditingImpayer = !_isEditingImpayer;
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

  void _processBarcode(
    BuildContext context,
    CommerceProvider1 commerceProvider1,
    CartProvider1 cartProvider1,
    double enteredQuantity,
    ToMany<LigneDocument> ligneFacture,
  ) async {
    if (_barcodeBuffer.isNotEmpty) {
      final produit = await commerceProvider1.getProduitByQr(_barcodeBuffer);

      if (produit == null) {
        _navigateToAddProductPage(context, commerceProvider1, cartProvider1);
      } else {
        cartProvider1.addToCart(produit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit ajouté : ${produit.nom}'),
            backgroundColor: Colors.green,
            showCloseIcon: true,
            duration: _snackBarDisplayDuration(),
          ),
        );
      }
      _barcodeBuffer = '';
    }
  }

  void _navigateToAddProductPage(BuildContext context,
      CommerceProvider1 commerceProvider, CartProvider1 cartProvider) async {
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
                    if (enteredQuantity <= 0.0)
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
    return Duration(seconds: 1);
  }
}

class ProductSearchField extends StatelessWidget {
  final TextEditingController _controller;
  final Function(
      BuildContext context,
      CommerceProvider1 commerceProvider1,
      CartProvider1 cartProvider1,
      double enteredQuantity,
      ToMany<LigneDocument> ligneFacture) _processBarcode;

  ProductSearchField(this._controller, this._processBarcode);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Rechercher un produit',
        border: OutlineInputBorder(),
      ),
      onFieldSubmitted: (value) {
        final commerceProvider =
            Provider.of<CommerceProvider1>(context, listen: false);
        final cartProvider = Provider.of<CartProvider1>(context, listen: false);
        _processBarcode(
          context,
          commerceProvider,
          cartProvider,
          double.parse('1'),
          cartProvider.facture.lignesDocument,
        );
      },
    );
  }
}
