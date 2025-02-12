import 'dart:io';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:string_extensions/string_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../Entity.dart';
import '../MyProviders.dart';
import '../Utils/country_flags.dart';
import '../Utils/mobile_scanner/barcode_scanner_window.dart';
import '../Utils/winMobile.dart';
import 'ProduitListScreen.dart';
import 'package:timeago/timeago.dart' as timeago;

class addProduct extends StatefulWidget {
  const addProduct({super.key});

  @override
  State<addProduct> createState() => _addProductState();
}

class _addProductState extends State<addProduct> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout();
  }
}

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyApp = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _stockController = TextEditingController();
  final _serialController = TextEditingController();
  final _datePeremptionController = TextEditingController();
  final _minimStockController = TextEditingController(text: '5');
  final _alertPeremptionController = TextEditingController(text: '2');
  final _qtyPartielController = TextEditingController(text: '1');
  final TextEditingController _pricePartielVenteController =
      TextEditingController();
  final FocusNode _serialFocusNode = FocusNode();
  final FocusNode _focusNodeNom = FocusNode();
  final FocusNode _focusNodePV = FocusNode();
  final FocusNode _focusNodeStock = FocusNode();

  File? _image;
  String? _existingImageUrl;
  String _tempProduitId = '';
  String _produitNom = '';
  String _produitDesignation = '';
  String _produitImage = '';
  String _produitImageTile = '';
  String _produitQr = '';
  double _produitStock = 0.0;
  double stockGlobale = 0.0; // Déclaration de la variable
  double stockTemp = 0;
  double _produitPV = 0.0;
  String _resultatPrixPartiel = '0';

  DateTime selectedDate = DateTime.now();
  final List<String> _qrCodesTemp = [];
  List<Fournisseur> _selectedFournisseurs = [];

  Fournisseur? _selectedFournisseur;
  Fournisseur? _currentFournisseur;
  Approvisionnement? _currentApprovisionnement;
  List<Approvisionnement> _approvisionnementTemporaire = [];
  bool _isFinded = false;
  bool _searchQr = true;
  bool _isFirstFieldRempli = false;
  bool _showDescription = false;
  bool _showAppro = false;
  bool _showDetail = false;
  bool _isEditing = false;
  bool _isLoadingSauv = false;
  bool _isFirstTap = true;

  @override
  void initState() {
    super.initState();
    _serialController.addListener(_onSerialChanged);
    _serialController.addListener(_checkFirstField);
    _clearAllFields();

    _qrCodesTemp.clear();
    _selectedFournisseurs.clear();
    _approvisionnementTemporaire.clear();
    _showDescription = false;
    _isFirstFieldRempli = false;
    _isFinded = false;
    // Ajoutez les listeners
    _prixVenteController.addListener(updatePricePartiel);
    _qtyPartielController.addListener(updatePricePartiel);
  }

  void updatePricePartiel() {
    if (_prixVenteController.text.isNotEmpty &&
        _qtyPartielController.text.isNotEmpty) {
      try {
        double prix = double.parse(_prixVenteController.text);
        double qty = double.parse(_qtyPartielController.text);
        if (qty != 0) {
          setState(() {
            _pricePartielVenteController.text = (prix / qty).toStringAsFixed(2);
            _resultatPrixPartiel = (prix / qty).toStringAsFixed(2);
          });
        }
      } catch (e) {
        setState(() {
          _pricePartielVenteController.text = '0';
          _resultatPrixPartiel = '0';
        });
      }
    } else {
      setState(() {
        _pricePartielVenteController.text = '0';
        _resultatPrixPartiel = '0';
      });
    }
  }

  void _onSerialChanged() {
    final code = _serialController.text.replaceAll(' ', '');

    // Vérifie si le champ est vide en premier lieu pour éviter des opérations inutiles.
    if (code.isEmpty && _qrCodesTemp.isEmpty
        // || _serialController.text == ''
        /*|| code == _lastScannedCode*/) {
      _clearAllFields();

      // return;
    }

    if (_searchQr) {
      //_updateProductInfo(code);
      _productInfo(code);
    }
  }

  void _checkFirstField() {
    // _serialController.text.isEmpty
    //     ? _approvisionnementTemporaire.clear()
    //     : null; /////// A VOIRE
    setState(() {
      _isFirstFieldRempli = _serialController.text.trim().isNotEmpty;
    });
  }

  Future<void> _updateProductInfo(String code) async {
    final provider = Provider.of<CommerceProvider>(context, listen: false);
    final produit = await provider.getProduitByQr(code);

    if (produit != null) {
      // Calculer le stock total des approvisionnements pour ce produit
      double stockTemp = produit.calculerStockTotal();
      print('Stock total pour le produit ${produit.nom} : $stockTemp');
    }

    if (produit != null) {
      setState(() {
        _tempProduitId = produit.id.toString();
        _nomController.text = produit.nom;
        _descriptionController.text = produit.description ?? '';
        //   _prixAchatController.text = produit.prixAchat.toStringAsFixed(2);
        _prixVenteController.text = produit.prixVente.toStringAsFixed(2);
        _stockController.text = produit.stock.toStringAsFixed(2);
        // _minimStockController.text = produit.minimStock!.toStringAsFixed(2);
        stockTemp = double.parse(produit.stock.toStringAsFixed(2));
        // _datePeremptionController.text =
        //     produit.datePeremption!.format('yMMMMd', 'fr_FR');
        _alertPeremptionController.text = produit.alertPeremption.toString();
        //_selectedFournisseurs = List.from(produit.fournisseurs);
        _existingImageUrl = produit.image;

        _isFinded = true;
        _image = null;
        _approvisionnementTemporaire = produit.approvisionnements.toList();
      });
    } else {
      if (_tempProduitId.isNotEmpty) {
        _tempProduitId = '';
        _nomController.clear();
        _descriptionController.clear();
        stockTemp = 0.0;
        _prixAchatController.clear();
        _prixVenteController.clear();
        _stockController.clear();
        _selectedFournisseurs.clear();
        _datePeremptionController.clear();
        _minimStockController.clear();
        _alertPeremptionController.clear();
        _approvisionnementTemporaire.clear();
        _existingImageUrl = '';
        _isFinded = false;
        // _image = null;
      }
    }
  }

  Future<void> _productInfo(String code) async {
    final provider = Provider.of<CommerceProvider>(context, listen: false);
    final produit = await provider.getProduitByQr(code);

    if (produit != null) {
      // Calculer le stock total des approvisionnements pour ce produit
      double stockTemp = produit.calculerStockTotal();
      print('Stock total pour le produit ${produit.nom} : $stockTemp');
    }

    if (produit != null) {
      setState(() {
        _tempProduitId = produit.id.toString();
        _produitNom = produit.nom;
        _produitDesignation = produit.description ?? '';
        _produitPV = produit.prixVente;
        _produitStock = produit.stock;
        _produitQr = produit.qr!;
        _produitImage = produit.image!;
        _produitImageTile = produit.image!;
        _isFinded = true;
        //_image = null;
      });
    } else {
      _tempProduitId = '';
      _produitNom = '';
      _produitDesignation = '';
      _produitPV = 0.0;
      _produitStock = 0.0;
      _produitImage = '';
      _isFinded = false;
      // _image = null;
    }
  }

  @override
  void dispose() {
    _serialController.removeListener(_onSerialChanged);
    _serialController.removeListener(_checkFirstField);
    _serialController.dispose();
    _nomController.dispose();
    _descriptionController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _stockController.dispose();
    _alertPeremptionController.dispose();
    _datePeremptionController.dispose();
    _serialFocusNode.dispose();
    // N'oubliez pas de disposer les contrôleurs
    _qtyPartielController.dispose();
    _pricePartielVenteController.dispose();
    // Nettoyer les FocusNodes
    _focusNodeNom.dispose();
    _focusNodePV.dispose();
    _focusNodeStock.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produitProvider =
        Provider.of<CommerceProvider>(context, listen: false);
    final iskeyboard = MediaQuery.of(context).viewInsets.bottom != 0;
    return SafeArea(
      maintainBottomViewPadding: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile layout
            return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                actions: [
                  WinMobile(),
                  buildButton_Add(context, produitProvider, _isFinded),
                  SizedBox(width: 50)
                ],
              ),
              body: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MobileLayout(),
                ),
              ),
            );
          } else if (constraints.maxWidth < 1200) {
            // Tablet layout
            return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  actions: [
                    WinMobile(),
                    buildButton_Add(context, produitProvider, _isFinded),
                    SizedBox(width: 50)
                  ],
                ),
                body: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 400, // largeur maximale de 200 pixels
                            // maxHeight: 100, // hauteur maximale de 100 pixels
                          ),
                          child: TabletLayout()),
                    ),
                  ),
                ));
          } else {
            // Desktop layout
            return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  actions: [
                    WinMobile(),
                    buildButton_Add(context, produitProvider, _isFinded),
                    SizedBox(width: 50)
                  ],
                ),
                body: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 400, // largeur maximale de 200 pixels
                        //maxHeight: 100, // hauteur maximale de 100 pixels
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DesktopLayout(),
                      ),
                    ),
                  ),
                ));
          }
        },
      ),
    );
  }

  Column MobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildColumn()),
        // Expanded(child: Container()),
      ],
    );
  }

  Row TabletLayout() {
    return Row(
      children: [
        Expanded(child: _buildColumn()),
        //Expanded(child: _buildColumn()),
      ],
    );
  }

  Row DesktopLayout() {
    return Row(
      children: [
        Expanded(child: _buildColumn()),
        // Expanded(child: _buildColumn()),
      ],
    );
  }

  Padding _buildColumn() {
    var largeur = MediaQuery.of(context).size.width;

    final String fallbackImage =
        'https://source.unsplash.com/random/1920x1080/?wallpaper,landscape';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          _searchQr == true && _tempProduitId.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          selectedColor: Colors.transparent,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            // _updateProductInfo(_serialController.text);
                            _addQRCodeFromText();
                            // final produit =
                            //     await provider.getProduitByQr(code);
                            // await Navigator.of(context)
                            //     .push(MaterialPageRoute(
                            //         builder: (ctx) => ProduitDetailPage(
                            //               produit: produit!,
                            //             )));
                          },
                          leading: _produitImageTile.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                  _produitImageTile,
                                  errorListener: (Object error) {
                                    setState(() {
                                      _produitImageTile =
                                          fallbackImage; // Remplacer par l'image de secours
                                    });
                                  },
                                  // Pour Web
                                ))
                              : CircleAvatar(
                                  child: Icon(Icons.image_not_supported),
                                ),
                          title: Text('${_produitNom.capitalize}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15)),
                          trailing: Text(
                            '${_produitPV.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              // : Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: ListTile(
              //       title: Text(
              //         'L\'ID du Produit n\'a pas encore été créer'
              //             .capitalize,
              //         style:
              //             TextStyle(fontSize: 14, color: Colors.black54),
              //       ),
              //     ),
              //   )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      'Nouveau ID du produit sera créer'.capitalize,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
          //id
          // Padding(
          //   padding: const EdgeInsets.all(20.0),
          //   child: Container(
          //     height: 30,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.start,
          //       children: [
          //         Transform.scale(
          //           scale:
          //               0.7, // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
          //           child: Switch(
          //             value: _searchQr,
          //             onChanged: (bool newValue) {
          //               setState(() {
          //                 _searchQr = newValue;
          //               });
          //             },
          //           ),
          //         ),
          //         // SizedBox(width: 10),
          //         FittedBox(
          //           child: Text(
          //             _searchQr
          //                 ? 'Recherche Activé'.capitalize
          //                 : 'Recherche Désactivé'.capitalize,
          //             overflow: TextOverflow.ellipsis,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ), //switch recherche auto
          _isFirstFieldRempli || _qrCodesTemp.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _serialController.text.isNotEmpty
                      ? FlagDetector(
                          barcode: _serialController.text,
                          height: 25,
                          width: 40,
                        ) // Afficher FlagDetector avec le code-barres
                      : FlagDetector(
                          barcode: _serialController.text,
                          height: 25,
                          width: 40,
                        ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 25,
                    width: 40,
                  ),
                ), // Flag
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: TextFormField(
              controller: _serialController,
              enabled: !_isLoadingSauv,
              focusNode: _serialFocusNode, // Attache FocusNode au TextFormField
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Code Barre / QrCode',
                prefixIcon: Transform.scale(
                  scale:
                      0.7, // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
                  child: Switch(
                    value: _searchQr,
                    onChanged: (bool newValue) {
                      setState(() {
                        _searchQr = newValue;
                      });
                    },
                  ),
                ),
                suffixIcon: (Platform.isIOS || Platform.isAndroid)
                    ? IconButton(
                        icon: Icon(Icons.qr_code_scanner),
                        onPressed: _scanQRCode,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.all(15),
              ),
              onFieldSubmitted: (value) {
                _addQRCodeFromText(); // Appel lors de l'appui sur "Entrée"
              },
            ),
          ), // Serial Qr Code
          _qrCodesTemp.isEmpty
              ? Container()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0, // Espacement horizontal entre les Chips
                    runSpacing: 7.0, // Espacement vertical entre les Chips
                    children: [
                      if (_qrCodesTemp.isNotEmpty)
                        Chip(
                          padding: EdgeInsets.zero,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blueAccent.withOpacity(
                                      0.2) // Couleur pour le thème sombre
                                  : Colors.blueAccent.withOpacity(
                                      0.6), // Couleur pour le thème clair
                          visualDensity: VisualDensity(vertical: -1),
                          label: Text(
                            '${_qrCodesTemp.length}',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                      .white // Couleur du texte pour le thème sombre
                                  : Colors
                                      .black, // Couleur du texte pour le thème clair
                            ),
                          ),
                        ),
                      ..._qrCodesTemp.map(
                        (code) => Chip(
                          padding: EdgeInsets.zero,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blueAccent.withOpacity(
                                      0.2) // Couleur pour le thème sombre
                                  : Colors.blueAccent.withOpacity(
                                      0.6), // Couleur pour le thème clair
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20.0), // Coins arrondis
                          ),
                          avatar: Align(
                            alignment: Alignment
                                .center, // Centre l'avatar verticalement
                            child: CircularFlagDetector(
                              barcode: code,
                              size: 25, // Adjust the size as needed
                            ),
                          ),
                          visualDensity: VisualDensity(
                              vertical:
                                  -1), // Ajustement vertical pour recentrer le contenu
                          label: Text(
                            code,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                      .white // Couleur du texte pour le thème sombre
                                  : Colors
                                      .black, // Couleur du texte pour le thème clair
                            ),
                          ), // Affiche le QR code dans le Chip
                          deleteIcon: Icon(Icons.delete, color: Colors.red),

                          onDeleted: () {
                            setState(() {
                              _qrCodesTemp.remove(
                                  code); // Supprime le QR code sélectionné
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ), // wrap qrcode
          _isFirstFieldRempli || _qrCodesTemp.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: buildColumnPicSuppliers(largeur, context),
                )
              : Container(), // photo
          _isFirstFieldRempli || _qrCodesTemp.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    enabled: !_isLoadingSauv,
                    controller: _nomController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next, // Action "Suivant"
                    onFieldSubmitted: (_) {
                      _focusNodePV.requestFocus(); // Passe au champ 2
                    },
                    // onChanged: (value) {
                    //   // Force la validation à chaque changement
                    //   _formKey.currentState?.validate();
                    // },
                    decoration: InputDecoration(
                      //  fillColor: _isFirstFieldFilled ? Colors.green.shade100 : null,
                      suffixIcon: !_showDescription
                          ? Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDescription = true;
                                    });
                                  },
                                  icon: Icon(Icons.arrow_downward_rounded)),
                            )
                          : null,
                      prefixIcon: _isFirstFieldRempli
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _clearAllFields();
                              },
                              tooltip: 'Effacer tous les champs',
                            )
                          : null,
                      labelText: 'Nom Du Produit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none, // Supprime le contour
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide
                            .none, // Supprime le contour en état normal
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide
                            .none, // Supprime le contour en état focus
                      ),
                      filled: true,
                      contentPadding: EdgeInsets.all(15),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom du Produit';
                      }
                      return null;
                    },
                  ),
                )
              : Container(), // nom
          Container(
            child: !_showDescription
                ? Container()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_isLoadingSauv,
                          onFieldSubmitted: (_) {
                            _focusNodePV.requestFocus(); // Passe au champ 2
                          },
                          maxLines: 5,
                          keyboardType: TextInputType.text,
                          textInputAction:
                              TextInputAction.next, // Action "Suivant"
                          decoration: InputDecoration(
                            hintText: 'Déscription',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide:
                                  BorderSide.none, // Supprime le contour
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide
                                  .none, // Supprime le contour en état normal
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide
                                  .none, // Supprime le contour en état focus
                            ),
                            filled: true,
                            contentPadding: EdgeInsets.all(15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_upward,
                            ),
                            onPressed: () {
                              setState(() {
                                _showDescription = false;
                              });
                            },
                            tooltip: 'Effacer tous les champs',
                          ),
                        ),
                      ],
                    ),
                  ),
          ), // description
          _isFirstFieldRempli || _qrCodesTemp.isNotEmpty
              ? Container(
                  width: largeur,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            enabled: !_isLoadingSauv,

                            controller: _prixVenteController,
                            textAlign: TextAlign.center,
                            textInputAction:
                                TextInputAction.next, // Action "Suivant"
                            onFieldSubmitted: (_) {
                              _focusNodeStock
                                  .requestFocus(); // Passe au champ 2
                            },
                            // onChanged: (value) {
                            //   // Force la validation à chaque changement
                            //   _formKey.currentState?.validate();
                            // },
                            decoration: InputDecoration(
                              labelText: 'Prix de vente',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                    BorderSide.none, // Supprime le contour
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide
                                    .none, // Supprime le contour en état normal
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide
                                    .none, // Supprime le contour en état focus
                              ),
                              //border: InputBorder.none,
                              filled: true,
                              contentPadding: EdgeInsets.all(15),
                            ),
                            // keyboardType: TextInputType.number,
                            // validator: (value) {
                            //   if (value == null || value.isEmpty) {
                            //     return 'Veuillez entrer le prix de vente';
                            //   }
                            //   return null;
                            // },
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: true, signed: true),

                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            // onChanged: (value) {
                            //   if (value.isNotEmpty) {
                            //     double? parsed = double.tryParse(value);
                            //     if (parsed != null) {
                            //       _prixVenteController.text = parsed.toStringAsFixed(2);
                            //       _prixVenteController.selection =
                            //           TextSelection.fromPosition(
                            //         TextPosition(
                            //             offset: _prixVenteController.text.length),
                            //       );
                            //     }
                            //   }
                            // },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le prix d\'achat';
                              }
                              // if (double.tryParse(value) == null) {
                              //   return 'Veuillez entrer un prix valide';
                              // }
                              return null;
                            },
                          ),
                        ),
                      ), // prix de vente
                      _showAppro
                          ? Container()
                          : Expanded(
                              child: TextFormField(
                                enabled: !_isLoadingSauv,
                                controller: _stockController,
                                onFieldSubmitted: (_) {
                                  _focusNodePV
                                      .requestFocus(); // Passe au champ 2
                                },
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'Stock',
                                  // suffixIcon: Padding(
                                  //   padding: const EdgeInsets.all(4.0),
                                  //   child: IconButton(
                                  //       onPressed: _showAddQuantityDialog,
                                  //       icon: Icon(Icons.add)),
                                  // ),

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide:
                                        BorderSide.none, // Supprime le contour
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide
                                        .none, // Supprime le contour en état normal
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide
                                        .none, // Supprime le contour en état focus
                                  ),
                                  //border: InputBorder.none,
                                  filled: true,
                                  contentPadding: EdgeInsets.all(15),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer le stock';
                                  }
                                  return null;
                                },
                              ),
                            ),
                      // stock alert
                    ],
                  ),
                ) // prix de vente
              : Container(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: !_showDetail
                ? _isFirstFieldRempli || _qrCodesTemp.isNotEmpty
                    ? TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDetail = true;
                          });
                        },
                        icon: Icon(Icons.keyboard_arrow_down),
                        label: Text('Detail'),
                      )
                    : Container()
                : Container(
                    padding: EdgeInsets.all(
                        8.0), // Espacement à l'intérieur du cadre
                    decoration: BoxDecoration(
                      //      color: Colors.grey, // Couleur de fond
                      borderRadius:
                          BorderRadius.circular(8.0), // Bords arrondis
                      border: Border.all(
                        color: Colors.grey, // Couleur de la bordure
                        width: 1.0, // Épaisseur de la bordure
                      ),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showDetail = false;
                            });
                          },
                          icon: Icon(Icons.keyboard_arrow_up),
                        ),
                        Container(
                          width: largeur,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    enabled: !_isLoadingSauv,
                                    onFieldSubmitted: (_) {
                                      _focusNodePV
                                          .requestFocus(); // Passe au champ 2
                                    },
                                    controller: _qtyPartielController,
                                    textAlign: TextAlign.center,
                                    textInputAction: TextInputAction
                                        .next, // Action "Suivant"
                                    // onFieldSubmitted: (_) {
                                    //   _focusNodeStock
                                    //       .requestFocus(); // Passe au champ 2
                                    // },
                                    // onChanged: (value) {
                                    //   // Force la validation à chaque changement
                                    //   _formKey.currentState?.validate();
                                    // },
                                    decoration: InputDecoration(
                                      labelText: 'Piéce dans ce Pack',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour en état normal
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour en état focus
                                      ),
                                      //border: InputBorder.none,
                                      filled: true,
                                      contentPadding: EdgeInsets.all(15),
                                    ),
                                    // keyboardType: TextInputType.number,
                                    // validator: (value) {
                                    //   if (value == null || value.isEmpty) {
                                    //     return 'Veuillez entrer le prix de vente';
                                    //   }
                                    //   return null;
                                    // },
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true, signed: true),

                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    // onChanged: (value) {
                                    //   if (value.isNotEmpty) {
                                    //     double? parsed = double.tryParse(value);
                                    //     if (parsed != null) {
                                    //       _prixVenteController.text = parsed.toStringAsFixed(2);
                                    //       _prixVenteController.selection =
                                    //           TextSelection.fromPosition(
                                    //         TextPosition(
                                    //             offset: _prixVenteController.text.length),
                                    //       );
                                    //     }
                                    //   }
                                    // },
                                    // onTap: () {
                                    //   if (_isFirstTap) {
                                    //     _qtyPartielController
                                    //         .clear(); // Vider la valeur existante
                                    //     setState(() {
                                    //       _isFirstTap =
                                    //           false; // Ne pas effacer les prochains clics
                                    //     });
                                    //   }
                                    // },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer combien de piéce dans ce pack';
                                      }
                                      // if (double.tryParse(value) == null) {
                                      //   return 'Veuillez entrer un prix valide';
                                      // }
                                      return null;
                                    },
                                  ),
                                ),
                              ), // prix de vente
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TextFormField(
                                    enabled: !_isLoadingSauv,
                                    onFieldSubmitted: (_) {
                                      _focusNodePV
                                          .requestFocus(); // Passe au champ 2
                                    },
                                    controller: _pricePartielVenteController,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Prix detail : $_resultatPrixPartiel DZD',
                                      // suffixIcon: Padding(
                                      //   padding: const EdgeInsets.all(4.0),
                                      //   child: IconButton(
                                      //       onPressed: _showAddQuantityDialog,
                                      //       icon: Icon(Icons.add)),
                                      // ),

                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour en état normal
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour en état focus
                                      ),
                                      //border: InputBorder.none,
                                      filled: true,
                                      contentPadding: EdgeInsets.all(15),
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true, signed: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le prix de detail';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              // stock alert
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QtyfilledButton(5),
                            QtyfilledButton(10),
                            QtyfilledButton(15),
                            QtyfilledButton(20),
                          ],
                        ),
                      ],
                    ),
                  ),
          ), // details

          ///********************************************************************** 1
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: !_showAppro
                ? _isFirstFieldRempli || _qrCodesTemp.isNotEmpty
                    ? TextButton.icon(
                        icon: Icon(Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            _showAppro = true;
                          });
                        },
                        label: Text('Approvisionnement'),
                      )
                    : Container()
                : Container(
                    padding: EdgeInsets.all(
                        8.0), // Espacement à l'intérieur du cadre
                    decoration: BoxDecoration(
                      //      color: Colors.grey, // Couleur de fond
                      borderRadius:
                          BorderRadius.circular(8.0), // Bords arrondis
                      border: Border.all(
                        color: Colors.grey, // Couleur de la bordure
                        width: 1.0, // Épaisseur de la bordure
                      ),
                    ),
                    child: Form(
                      key: _formKeyApp,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.keyboard_arrow_up),
                            onPressed: () {
                              setState(() {
                                _showAppro = false;
                              });
                            },
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    enabled: !_isLoadingSauv,
                                    controller: _prixAchatController,
                                    textAlign: TextAlign.center,
                                    onFieldSubmitted: (_) {
                                      _focusNodePV
                                          .requestFocus(); // Passe au champ 2
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Prix d\'achat',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour en état normal
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide
                                            .none, // Supprime le contour en état focus
                                      ),
                                      //border: InputBorder.none,
                                      filled: true,
                                      contentPadding: EdgeInsets.all(15),
                                    ),
                                    // keyboardType: TextInputType.number,
                                    //  validator: (value) {
                                    //    if (value == null || value.isEmpty) {
                                    //      return 'Veuillez entrer le prix d\'achat';
                                    //    }
                                    //    return null;
                                    //  },
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    // onChanged: (value) {
                                    //   if (value.isNotEmpty) {
                                    //     double? parsed = double.tryParse(value);
                                    //     if (parsed != null) {
                                    //       _prixAchatController.text = parsed.toStringAsFixed(2);
                                    //       _prixAchatController.selection =
                                    //           TextSelection.fromPosition(
                                    //         TextPosition(
                                    //             offset: _prixAchatController.text.length),
                                    //       );
                                    //     }
                                    //   }
                                    // },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le prix d\'achat';
                                      }
                                      // if (double.tryParse(value) == null) {
                                      //   return 'Veuillez entrer un prix valide';
                                      // }
                                      // return null;
                                    },
                                  ),
                                ),
                              ), //prix d'achat
                              !_showAppro
                                  ? Container()
                                  : Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: TextFormField(
                                          enabled: !_isLoadingSauv,
                                          controller: _stockController,
                                          textAlign: TextAlign.center,
                                          onFieldSubmitted: (_) {
                                            _focusNodePV
                                                .requestFocus(); // Passe au champ 2
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Stock',
                                            // suffixIcon: Padding(
                                            //   padding: const EdgeInsets.all(4.0),
                                            //   child: IconButton(
                                            //       onPressed: _showAddQuantityDialog,
                                            //       icon: Icon(Icons.add)),
                                            // ),

                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide
                                                  .none, // Supprime le contour
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide
                                                  .none, // Supprime le contour en état normal
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide
                                                  .none, // Supprime le contour en état focus
                                            ),
                                            //border: InputBorder.none,
                                            filled: true,
                                            contentPadding: EdgeInsets.all(15),
                                          ),
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                  decimal: true, signed: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d+\.?\d{0,2}')),
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Veuillez entrer le stock';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                            ],
                          ), // stock
                          // Flexible(
                          //   flex: 2,
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(8.0),
                          //     child: TextFormField(
                          //       enabled: !_isLoadingSauv,
                          //       controller: _datePeremptionController,
                          //       textAlign: TextAlign.center,
                          //       onFieldSubmitted: (_) {
                          //         _focusNodePV
                          //             .requestFocus(); // Passe au champ 2
                          //       },
                          //       keyboardType: TextInputType.text,
                          //       decoration: InputDecoration(
                          //         // fillColor: _isFirstFieldFilled
                          //         //     ? Colors.yellow.shade200
                          //         //     : null,
                          //         labelText: 'Date de Péremption',
                          //         suffixIcon: IconButton(
                          //           icon: const Icon(Icons.date_range),
                          //           onPressed: () async {
                          //             final DateTime? dateTimePerem =
                          //                 await showDatePicker(
                          //               context: context,
                          //               initialDate: selectedDate,
                          //               firstDate: DateTime(2000),
                          //               lastDate: DateTime(2200),
                          //             );
                          //             if (dateTimePerem != null) {
                          //               setState(() {
                          //                 selectedDate = dateTimePerem;
                          //                 _datePeremptionController.text =
                          //                     dateTimePerem.format(
                          //                         'yMMMMd', 'fr_FR');
                          //               });
                          //             }
                          //           },
                          //         ),
                          //         border: OutlineInputBorder(
                          //           borderRadius: BorderRadius.circular(8.0),
                          //           borderSide:
                          //               BorderSide.none, // Supprime le contour
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
                          //         filled: true,
                          //         contentPadding: EdgeInsets.all(15),
                          //       ),
                          //       // validator: (value) {
                          //       //   if (value == null || value.isEmpty) {
                          //       //     return 'Veuillez entrer un nom du Produit';
                          //       //   }
                          //       //   return null;
                          //       // },
                          //     ),
                          //   ),
                          // ),
                          Flexible(
                            flex: 2,
                            child: FittedBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.date_range),
                                    color: Colors.blue,
                                    onPressed: () async {
                                      final DateTime? dateTimePerem =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2200),
                                        currentDate: DateTime.now(),
                                      );
                                      if (dateTimePerem != null) {
                                        setState(() {
                                          selectedDate = dateTimePerem;
                                          _datePeremptionController.text =
                                              DateFormat(
                                                      'dd MMMM yyyy', 'fr_FR')
                                                  .format(dateTimePerem);
                                        });
                                      }
                                    },
                                  ),
                                  Text(
                                    _datePeremptionController.text.isEmpty
                                        ? 'Sélectionner une date'
                                        : _datePeremptionController.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _datePeremptionController.text.isEmpty
                                              ? Colors.grey
                                              : Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  buildDatePeremptionInfo(),
                                  _datePeremptionController.text.isEmpty
                                      ? SizedBox.shrink()
                                      : IconButton(
                                          icon: Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () async {
                                            //  selectedDate = dateTimePerem;
                                            setState(() {
                                              _datePeremptionController.clear();
                                            });
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: largeur,
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: [
                                    // Affiche le fournisseur sélectionné
                                    if (_selectedFournisseur !=
                                        null) // Afficher seulement si un fournisseur est sélectionné
                                      !_isLoadingSauv
                                          ? GestureDetector(
                                              onTap: () async {
                                                final result =
                                                    await Navigator.of(context)
                                                        .push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FournisseurSelectionScreen(
                                                      selectedFournisseur:
                                                          _selectedFournisseur,
                                                      onSelectedFournisseurChanged:
                                                          _onSelectedFournisseurChanged,
                                                    ),
                                                  ),
                                                );
                                                if (result != null) {
                                                  setState(() {
                                                    _selectedFournisseur =
                                                        result; // Mettre à jour le fournisseur sélectionné
                                                  });
                                                }
                                              },
                                              child: Chip(
                                                label: Text(
                                                  _selectedFournisseur!.nom,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                            .chipTheme
                                                            .labelStyle
                                                            ?.color ??
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color,
                                                  ),
                                                ),
                                                onDeleted: () {
                                                  setState(() {
                                                    _selectedFournisseur =
                                                        null; // Réinitialiser la sélection
                                                  });
                                                },
                                                backgroundColor:
                                                    Theme.of(context)
                                                            .chipTheme
                                                            .backgroundColor ??
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .surface,
                                                deleteIconColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12), // Bordures rondes
                                                  side: BorderSide(
                                                    color: Theme.of(context)
                                                        .dividerColor, // Bordure subtile
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Chip(
                                              label: Text(_selectedFournisseur!
                                                  .nom), // Afficher le nom du fournisseur sélectionné

                                              onDeleted: null,
                                              // backgroundColor: Colors.grey
                                              //     .shade300, // Optionnel: couleur grisée
                                            ),

                                    // Icône pour ajouter un fournisseur (toujours la dernière)
                                    _selectedFournisseur == null
                                        ? TextButton(
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                            ),

                                            onPressed: !_isLoadingSauv
                                                ? () async {
                                                    final result =
                                                        await Navigator.of(
                                                                context)
                                                            .push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            FournisseurSelectionScreen(
                                                          selectedFournisseur:
                                                              _selectedFournisseur,
                                                          onSelectedFournisseurChanged:
                                                              _onSelectedFournisseurChanged,
                                                        ),
                                                      ),
                                                    );
                                                    if (result != null) {
                                                      setState(() {
                                                        _selectedFournisseur =
                                                            result; // Mettre à jour le fournisseur sélectionné
                                                      });
                                                    }
                                                  }
                                                : null, // Désactive si la condition est fausse

                                            child: const Text(
                                                'Selectionné un Fournisseur'),
                                          )
                                        : Container(),
                                    // IconButton(
                                    //   icon: Icon(Icons.add),
                                    //   onPressed: () async {
                                    //     final result =
                                    //         await Navigator.of(context).push(
                                    //       MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             FournisseurSelectionScreen(
                                    //           selectedFournisseur:
                                    //               _selectedFournisseur,
                                    //           onSelectedFournisseurChanged:
                                    //               _onSelectedFournisseurChanged,
                                    //         ),
                                    //       ),
                                    //     );
                                    //     if (result != null) {
                                    //       setState(() {
                                    //         _selectedFournisseur =
                                    //             result; // Mettre à jour le fournisseur sélectionné
                                    //       });
                                    //     }
                                    //   },
                                    // ),
                                  ],
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              icon: Icon(_isEditing ? Icons.edit : Icons.send,
                                  color:
                                      _isEditing ? Colors.blue : Colors.green),
                              onPressed: !_isLoadingSauv
                                  ? saveApprovisionnement
                                  : null,
                              label: Text(_isEditing
                                  ? 'Modifier le Stock'
                                  : 'Ajouter ce Stock'),
                            ),
                          ), //Ajouter ce Stock
                          Flexible(
                            child: Container(
                              width: largeur,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _approvisionnementTemporaire
                                    .length, // Utilisation de la liste temporaire
                                itemBuilder: (context, index) {
                                  // Utilisation de la liste inversée pour afficher les derniers en haut
                                  final approvisionnement =
                                      _approvisionnementTemporaire
                                          .reversed // Inversion de la liste
                                          .toList()[index];

                                  // Récupérer le fournisseur associé à cet approvisionnement
                                  final fournisseur =
                                      approvisionnement.fournisseur.target;

                                  return Card(
                                      child: InkWell(
                                    onTap: _isLoadingSauv
                                        ? null
                                        : () {
                                            // Démarrer l'édition de cet approvisionnement
                                            startEditing(approvisionnement);
                                          },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${approvisionnement.quantite.toStringAsFixed(approvisionnement.quantite.truncateToDouble() == approvisionnement.quantite ? 0 : 2)}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: _isLoadingSauv
                                                    ? Colors.black87
                                                        .withOpacity(0.6)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fournisseur != null
                                                    ? fournisseur.nom.trim()
                                                    : 'Fournisseur Inconnu',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: _isLoadingSauv
                                                      ? Colors.black87
                                                          .withOpacity(0.6)
                                                      : null,
                                                ),
                                              ),
                                              approvisionnement
                                                          .datePeremption !=
                                                      null
                                                  ? Text(
                                                      'Expire le : ${DateFormat('dd/MM/yyyy').format(approvisionnement.datePeremption!)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _isLoadingSauv
                                                            ? Colors.black87
                                                                .withOpacity(
                                                                    0.6)
                                                            : null,
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8),
                                              child: Text(
                                                '${approvisionnement.prixAchat!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: _isLoadingSauv
                                                      ? Colors.black87
                                                          .withOpacity(0.6)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: Icon(
                                                Icons.delete,
                                                color: _isLoadingSauv
                                                    ? Colors.white
                                                        .withOpacity(0.6)
                                                    : Colors.red,
                                                size: 15,
                                              ),
                                              onPressed: _isLoadingSauv
                                                  ? null
                                                  : () {
                                                      // Appeler la méthode pour supprimer l'approvisionnement
                                                      setState(() {
                                                        supprimerApprovisionnementTemporaire(
                                                            approvisionnement);
                                                        stockGlobale -=
                                                            approvisionnement
                                                                .quantite;
                                                      });
                                                    },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ));
                                },
                              ),
                            ),
                          ), //Liste des approvisionnements
                        ],
                      ),
                    ),
                  ),
          ),
          SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }

  FilledButton QtyfilledButton(int StringNum) {
    return FilledButton(
      onPressed:
          _prixVenteController.text == '' || _qtyPartielController.text == ''
              ? null
              : () {
                  setState(() {
                    _qtyPartielController.text = StringNum.toString();
                    _resultatPrixPartiel =
                        (double.parse(_prixVenteController.text) /
                                double.parse(_qtyPartielController.text))
                            .toStringAsFixed(2);
                  });
                },
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          CircleBorder(),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.all(16), // Pas de padding interne
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          // Change la couleur en fonction de l'état
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey; // Couleur désactivée
          }
          return Colors.blue; // Couleur activée
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white.withOpacity(0.6); // Couleur texte désactivé
          }
          return Colors.white; // Couleur texte activé
        }),
      ),
      child: Text(StringNum.toString(), style: TextStyle(fontSize: 16)),
    );
  }

  void _clearAllFields() {
    setState(() {
      _tempProduitId = '';
      //_serialController.clear();
      stockTemp = 0.0;
      _nomController.clear();
      _descriptionController.clear();
      _prixAchatController.clear();
      _prixVenteController.clear();
      _stockController.clear();
      _minimStockController.clear();
      _selectedFournisseurs.clear();
      // _datePeremptionController.clear();
      _alertPeremptionController.clear();
      _existingImageUrl = '';
      //_isFirstFieldFilled = false;
      _image = null;
      _approvisionnementTemporaire.clear();
      // _isFirstTap = true;
      // _qtyPartielController.clear();
      // _pricePartielVenteController.clear();
    });
  }

  void _clearAllFields2() {
    setState(() {
      _existingImageUrl = '';

      _image = null;
    });
  }

  Future<String> uploadImageToSupabase(File image, String? oldImageUrl) async {
    final String bucket = 'products';
    final supabase = Supabase.instance.client;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        '${_prixVenteController.text}${_stockController.text}$timestamp${path.extension(image.path)}';

    try {
      await supabase.storage.from(bucket).upload(fileName, image);

      final imageUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        final oldFileName = Uri.parse(oldImageUrl).pathSegments.last;
        await supabase.storage.from(bucket).remove([oldFileName]);
      }

      return imageUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image : $e');
      return '';
    }
  }

  Future<bool> _validateForm() async {
    final isValid = await _formKey.currentState?.validate() ?? false;
    return isValid;
  }

  Future<String> _prepareImageUrl() async {
    if (_image != null) {
      return await uploadImageToSupabase(_image!, _existingImageUrl);
    } else if (_existingImageUrl?.isNotEmpty ?? false) {
      return _existingImageUrl!;
    }
    return '';
  }

  void _addQrCodeIfNotExists() {
    final code = _serialController.text.trim();
    if (code.isNotEmpty && !_qrCodesTemp.contains(code)) {
      _qrCodesTemp.add(code);
    }
  }

//Étape 2 : Construction et Sauvegarde du Produit

  Produit _createProduit(String imageUrl) {
    return Produit(
      qr: _qrCodesTemp.toSet().toList().join(','),
      image: imageUrl,
      nom: _nomController.text,
      description: _descriptionController.text,
      prixVente: double.parse(_prixVenteController.text),
      qtyPartiel: double.parse(_qtyPartielController.text),
      pricePartielVente: double.parse(_pricePartielVenteController.text),
      derniereModification: DateTime.now(),
    )..crud.target = Crud(
        createdBy: 1,
        updatedBy: 1,
        deletedBy: 1,
        dateCreation: DateTime.now(),
        derniereModification: DateTime.now(),
      );
  }

  void _assignApprovisionnementsToProduit(Produit produit) {
    for (int i = 0; i < _approvisionnementTemporaire.length; i++) {
      final approvisionnement = _approvisionnementTemporaire[i];
      approvisionnement.produit.target = produit;
      if (i < _selectedFournisseurs.length) {
        approvisionnement.fournisseur.target = _selectedFournisseurs[i];
      }
      approvisionnement.crud.target = Crud(
        createdBy: 1,
        updatedBy: 1,
        deletedBy: 1,
        dateCreation: DateTime.now(),
        derniereModification: DateTime.now(),
      );
    }
  }

//Étape 3 : Gestion des Erreurs et du Retour UI

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

// Étape 4 :Combinaison des Étapes

  IconButton buildButton_Add(
    BuildContext context,
    CommerceProvider produitProvider,
    bool isFinded,
  ) {
    return IconButton(
      onPressed: _serialController.text.trim().isEmpty && _qrCodesTemp.isEmpty
          ? null
          : () async {
              if (!mounted) return;

              // Validation du formulaire
              if (!await _validateForm()) return;

              // Vérifier si le produit existe déjà avant d'afficher le ProgressDialog
              final existingProduct =
                  await produitProvider.getProduitByQr(_serialController.text);
              if (existingProduct != null) {
                print('Produit existant détecté');
                showExistingProductDialog(context, _serialController.text,
                    existingProduct, produitProvider);
                _showSnackBar(context, 'Produit déjà existant', Colors.orange);
                return; // Arrêter ici si le produit existe déjà
              }

              // Affichage du ProgressDialog uniquement pour un produit non existant
              setState(() => _isLoadingSauv = true);
              // showDialog(
              //   context: context,
              //   barrierDismissible: false,
              //   builder: (context) => const ProgressDialog(),
              // );

              try {
                // Préparation de l'URL de l'image
                final imageUrl = await _prepareImageUrl();
                _addQrCodeIfNotExists();

                // Création d'un nouveau produit avec les détails saisis
                final produit = _createProduit(imageUrl);

                if ( //_prixAchatController.text.isNotEmpty &&
                    _stockController.text.isNotEmpty) {
                  print('debut saveApprovisionnement');
                  saveApprovisionnement();
                  print('saveApprovisionnement');
                }
                _assignApprovisionnementsToProduit(produit);
                // Sauvegarde du nouveau produit
                produitProvider.ajouterProduit(produit, _selectedFournisseurs,
                    _approvisionnementTemporaire);
                _formKey.currentState?.save();
                setState(() => _isLoadingSauv = false);
                _showSnackBar(
                    context, 'Produit ajouté avec succès', Colors.green);

                Navigator.pop(context); // Ferme la page du formulaire
              } catch (e) {
                _showSnackBar(
                    context, 'Erreur lors de la sauvegarde : $e', Colors.red);
              } finally {
                if (mounted) {
                  setState(() => _isLoadingSauv = false);
                  //Navigator.pop(context); // Ferme le ProgressDialog
                }
              }
            },
      icon: _isLoadingSauv
          ? const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            )
          : Icon(
              isFinded && _serialController.text == _produitQr
                  ? Icons.edit
                  : _serialController.text.trim().isEmpty &&
                          _qrCodesTemp.isEmpty
                      ? null
                      : Icons.send,
              color: Colors.blueAccent,
            ),
    );
  }

  Future<void> _scanQRCode() async {
    // Simuler un scan de QR code pour tester
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWithScanWindow(), //QRViewExample(),
      ),
    );
    final provider = Provider.of<CommerceProvider>(context, listen: false);
    final produit = await provider.getProduitByQr(code!);
// Afficher une alerte avec les détails du produit existant
    if (produit != null) {
      showExistingProductDialog(context, code, produit, provider);
    }
    // Rediriger le focus vers le TextFormField après l'ajout
    FocusScope.of(context).requestFocus(_serialFocusNode);

    // if (code.isNotEmpty && !_qrCodesTemp.contains(code)) {
    //   setState(() {
    //     _serialController.text = code;
    //     _qrCodesTemp.add(code); // Ajout du QR code à la liste temporaire
    //     _searchQr = false;
    //   });
    //   // Rediriger le focus vers le TextFormField après l'ajout
    //   FocusScope.of(context).requestFocus(_serialFocusNode);
    //   final provider = Provider.of<CommerceProvider>(context, listen: false);
    //   //final produit = await provider.getProduitById(int.parse(code));
    //   final produit = await provider.getProduitByQr(code);
    //   if (produit == null) {
    //     if (code.isNotEmpty && !_qrCodesTemp.contains(code)) {
    //       setState(() {
    //         _qrCodesTemp.add(code);
    //         _serialController.clear();
    //         _searchQr = false;
    //       });
    //     } else {
    //       _serialController.clear();
    //     }
    //     FocusScope.of(context).requestFocus(_serialFocusNode);
    //   }
    //   // if (produit != null) {
    //   //   setState(() {
    //   //     _tempProduitId = produit.id.toString() ?? '';
    //   //     _nomController.text = produit.nom;
    //   //     _descriptionController.text = produit.description ?? '';
    //   //     // _prixAchatController.text = produit.prixAchat.toStringAsFixed(2);
    //   //     _prixVenteController.text = produit.prixVente.toStringAsFixed(2);
    //   //     _stockController.text = produit.stock.toStringAsFixed(2);
    //   //     stockTemp = double.parse(produit.stock.toStringAsFixed(2));
    //   //     _minimStockController.text = produit.minimStock!.toStringAsFixed(2);
    //   //     _alertPeremptionController.text = produit.alertPeremption.toString();
    //   //     // _datePeremptionController.text = produit
    //   //     //     .approvisionnements.first.datePeremption!
    //   //     //     .format('yMMMMd', 'fr_FR');
    //   //     //_selectedFournisseurs = List.from(produit.fournisseurs);
    //   //     _existingImageUrl = produit.image;
    //   //     _isFinded = true;
    //   //     _image = null;
    //   //     // Ajouter le QR code scanné à la liste
    //   //     produit.addQrCode(code); // Ajoute le QR code scanné à la liste
    //   //   });
    //   // } else {
    //   //   setState(() {
    //   //     _tempProduitId = '';
    //   //     _nomController.clear();
    //   //     _descriptionController.clear();
    //   //     _prixAchatController.clear();
    //   //     stockTemp = 0.0;
    //   //     _alertPeremptionController.clear();
    //   //     _prixVenteController.clear();
    //   //     _stockController.clear();
    //   //     _selectedFournisseurs.clear();
    //   //     _datePeremptionController.clear();
    //   //     _minimStockController.clear();
    //   //     _existingImageUrl = '';
    //   //     _isFinded = false;
    //   //     _image = null;
    //   //   });
    //   //   // Si un nouveau produit doit être créé, tu peux créer un objet Produit temporaire
    //   //   Produit newProduit = Produit(
    //   //     nom: _nomController.text,
    //   //     prixVente: double.parse(_prixVenteController.text),
    //   //     minimStock: double.parse(_minimStockController.text),
    //   //     alertPeremption: int.parse(_alertPeremptionController.text),
    //   //     derniereModification: DateTime.now(),
    //   //   );
    //   //
    //   //   // Ajoute le QR code scanné à ce nouveau produit
    //   //   newProduit.addQrCode(code);
    //   // }
    // }
    if (produit == null) {
      if (code.isNotEmpty && !_qrCodesTemp.contains(code)) {
        setState(() {
          _qrCodesTemp.add(code);
          _serialController.clear();
          _searchQr = false;
        });
      } else {
        _serialController.clear();
      }
      FocusScope.of(context).requestFocus(_serialFocusNode);
    }
  }

  // Méthode séparée pour afficher le dialogue
  // void showExistingProductDialog(BuildContext context, String code,
  //     Produit produit, CommerceProvider provider) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       // Récupérer la largeur et la hauteur de l'écran
  //       final screenWidth = MediaQuery.of(context).size.width;
  //       final screenHeight = MediaQuery.of(context).size.height;
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.all(Radius.circular(20)),
  //         ),
  //         titlePadding: EdgeInsets.all(0),
  //         contentPadding: EdgeInsets.all(20),
  //         insetPadding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
  //         title: Padding(
  //           padding: const EdgeInsets.all(0),
  //           child: Column(
  //             children: [
  //               Center(
  //                 child: produit.image != null
  //                     ? ClipRRect(
  //                         borderRadius: BorderRadius.circular(8.0),
  //                         child: AspectRatio(
  //                           aspectRatio: 1, // Conserve un ratio 1:1
  //                           child: CachedNetworkImage(
  //                             imageUrl: produit.image!,
  //                             fit: BoxFit
  //                                 .cover, // Remplit l'espace sans déformation
  //                             width: screenWidth *
  //                                 0.6, // 60% de la largeur de l'écran
  //                             height: screenHeight *
  //                                 0.6, // 60% de la largeur pour garder le ratio
  //                             placeholder: (context, url) => Center(
  //                               child:
  //                                   CircularProgressIndicator(), // Indicateur de chargement
  //                             ),
  //                             errorWidget: (context, url, error) => Center(
  //                               child: Lottie.asset(
  //                                 'assets/lotties/1 (8).json', // Chemin vers ton fichier Lottie
  //                                 width: screenWidth *
  //                                     0.2, // Ajuste la taille de l'erreur à 30%
  //                                 height: screenWidth * 0.2,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       )
  //                     : Center(
  //                         child: Lottie.asset(
  //                           'assets/lotties/1 (8).json', // Chemin vers ton fichier Lottie
  //                           width: screenWidth *
  //                               0.2, // Ajuste la taille de l'erreur à 30%
  //                           height: screenWidth * 0.2,
  //                         ),
  //                       ), // Affiche un container vide si pas d'image
  //               ),
  //               Text(
  //                 'Dernière Modification : ${produit.derniereModification.format('yMMMMd', 'fr_FR')}',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         content: SingleChildScrollView(
  //           child: SizedBox(
  //             width: 200, // Largeur fixe du dialogue
  //             // height: 300,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Center(
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(0.0),
  //                     child: RichText(
  //                       text: TextSpan(
  //                         text: 'BarCode'.toUpperCase(),
  //                         style: TextStyle(
  //                           color: Theme.of(context).brightness ==
  //                                   Brightness.dark
  //                               ? Colors
  //                                   .white // Couleur du texte pour le thème sombre
  //                               : Colors
  //                                   .black, // Couleur du texte pour le thème clair
  //                           fontSize: 20,
  //                           fontFamily: 'Oswald',
  //                         ),
  //                         children: <TextSpan>[
  //                           TextSpan(
  //                             text: ' ${code} '.toUpperCase(),
  //                             style: TextStyle(
  //                               fontFamily: 'Oswald',
  //                               fontSize: 20,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           TextSpan(
  //                             text: ' est déjà associé au '.toUpperCase(),
  //                             style: TextStyle(
  //                               fontFamily: 'Oswald',
  //                               fontSize: 20,
  //                             ),
  //                           ),
  //                           TextSpan(
  //                             text: '${produit.nom}'.toUpperCase(),
  //                             style: TextStyle(
  //                               fontFamily: 'Oswald',
  //                               fontSize: 20,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 if (produit.description != null &&
  //                     produit.description!.isNotEmpty)
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //                     child: Text(
  //                       'Description : ${produit.description}',
  //                       overflow: TextOverflow.ellipsis,
  //                       textAlign: TextAlign.justify,
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                       ),
  //                     ),
  //                   ),
  //                 Text(
  //                   'Prix de vente : ${produit.prixVente.toStringAsFixed(2)} DA',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                   ),
  //                 ),
  //                 Text(
  //                   'Stock : ${produit.stock.toStringAsFixed(2)}',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         actions: [
  //           // TextButton(
  //           //   style: TextButton.styleFrom(foregroundColor: Colors.red),
  //           //   child: Text('Supprimer le code'),
  //           //   onPressed: () async {
  //           //     await provider.removeQRCodeFromProduit(produit.id, code);
  //           //     Navigator.of(context).pop();
  //           //   },
  //           // ),
  //           TextButton(
  //             child: Text('OK', style: TextStyle(color: Colors.blue)),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             style: TextButton.styleFrom(foregroundColor: Colors.blue),
  //             child: Text('Voir Details...'),
  //             onPressed: () async {
  //               await Navigator.of(context).push(MaterialPageRoute(
  //                   builder: (ctx) => ProduitDetailPage(
  //                         produit: produit,
  //                       )));
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // Méthode séparée pour afficher le dialogue
  void showExistingProductDialog(BuildContext context, String code,
      Produit produit, CommerceProvider provider) {
    final commerceProvider =
        Provider.of<CommerceProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Récupérer la largeur et la hauteur de l'écran
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return Builder(builder: (BuildContext builderContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            titlePadding: EdgeInsets.all(0),
            contentPadding: EdgeInsets.all(20),
            insetPadding:
                EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            title: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Center(
                    child: produit.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: AspectRatio(
                              aspectRatio: 1, // Conserve un ratio 1:1
                              child: CachedNetworkImage(
                                imageUrl: produit.image!,
                                fit: BoxFit
                                    .cover, // Remplit l'espace sans déformation
                                width: screenWidth *
                                    0.4, // 60% de la largeur de l'écran
                                height: screenHeight *
                                    0.4, // 60% de la largeur pour garder le ratio
                                placeholder: (context, url) => Center(
                                  child:
                                      CircularProgressIndicator(), // Indicateur de chargement
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Lottie.asset(
                                    'assets/lotties/1 (8).json', // Chemin vers ton fichier Lottie
                                    width: screenWidth *
                                        0.2, // Ajuste la taille de l'erreur à 30%
                                    height: screenWidth * 0.2,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Lottie.asset(
                              'assets/lotties/1 (8).json', // Chemin vers ton fichier Lottie
                              width: screenWidth *
                                  0.2, // Ajuste la taille de l'erreur à 30%
                              height: screenWidth * 0.2,
                            ),
                          ), // Affiche un container vide si pas d'image
                  ),
                  Text(
                    'Dernière Modification : ${produit.derniereModification.format('yMMMMd', 'fr_FR')}',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 200, // Largeur fixe du dialogue
                // height: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 8.0, // Espacement horizontal entre les Chips
                        runSpacing: 7.0, // Espacement vertical entre les Chips
                        children: [
                          // Affiche uniquement les trois premiers Chips
                          ...produit.qr!
                              .split(',')
                              .map((e) => e.trim()) // Supprime les espaces
                              .take(3) // Prend les trois premiers éléments
                              .map(
                                (code) => Chip(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Theme.of(context)
                                              .brightness ==
                                          Brightness.dark
                                      ? Colors.blueAccent.withOpacity(
                                          0.2) // Couleur pour le thème sombre
                                      : Colors.blueAccent.withOpacity(
                                          0.6), // Couleur pour le thème clair
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        20.0), // Coins arrondis
                                  ),
                                  avatar: Align(
                                    alignment: Alignment
                                        .center, // Centre l'avatar verticalement
                                    child: CircularFlagDetector(
                                      barcode: code,
                                      size: 25, // Taille ajustée
                                    ),
                                  ),
                                  visualDensity: const VisualDensity(
                                    vertical: -1, // Ajustement vertical
                                  ),
                                  label: Text(
                                    code,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors
                                              .white // Texte pour le thème sombre
                                          : Colors
                                              .black, // Texte pour le thème clair
                                    ),
                                  ),
                                ),
                              ),

                          // Affiche une icône indiquant le nombre de Chips restants, si nécessaire
                          if (produit.qr!.split(',').length > 3)
                            Chip(
                              padding: EdgeInsets.zero,
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.withOpacity(
                                      0.2) // Couleur pour le thème sombre
                                  : Colors.grey.withOpacity(
                                      0.6), // Couleur pour le thème clair
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    20.0), // Coins arrondis
                              ),
                              avatar: Icon(
                                Icons
                                    .more_horiz, // Icône indiquant plus d'éléments
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              label: Text(
                                "+${produit.qr!.split(',').length - 3}", // Nombre d'éléments restants
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: RichText(
                          text: TextSpan(
                            text: 'BarCode'.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                      .white // Couleur du texte pour le thème sombre
                                  : Colors
                                      .black, // Couleur du texte pour le thème clair
                              fontSize: 20,
                              fontFamily: 'Oswald',
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: ' ${code} '.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: ' est déjà associé au '.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 20,
                                ),
                              ),
                              TextSpan(
                                text: '${produit.nom}'.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (produit.description != null &&
                        produit.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'Description : ${produit.description}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    Text(
                      'Prix de vente : ${produit.prixVente.toStringAsFixed(2)} DA',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Stock : ${produit.stock.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Supprimer code'),
                onPressed: () async {
                  // Ferme d'abord la boîte de dialogue
                  Navigator.of(builderContext).pop();
                  await provider
                      .removeQRCodeFromProduit(produit.id, code)
                      .whenComplete(() => print('suppression reusite'));

                  // Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Bye', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  // Ferme d'abord la boîte de dialogue
                  Navigator.of(builderContext).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: Text('Voir Details...'),
                onPressed: () async {
                  // Ferme d'abord la boîte de dialogue
                  Navigator.of(builderContext).pop();

                  // Ensuite, navigue vers la nouvelle page
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ProduitDetailPage(produit: produit),
                    ),
                  );
                },
              ),

              // TextButton(
              //   style: TextButton.styleFrom(foregroundColor: Colors.blue),
              //   child: Text('Voir Details...'),
              //   onPressed: () async {
              //     await Navigator.of(context).push(MaterialPageRoute(
              //             builder: (ctx) => ProduitDetailPage(
              //                   produit: produit,
              //                 )))
              //         // .whenComplete(
              //         //   () => Navigator.of(builderContext).pop(),
              //         // )
              //         ;
              //     // Navigator.of(context).pop();
              //     // Navigator.of(dialogContext).pop();
              //     Navigator.of(builderContext).pop();
              //   },
              // ),
            ],
          );
        });
      },
    );
  }

  // Votre méthode _addQRCodeFromText modifiée
  void _addQRCodeFromText() async {
    final code = _serialController.text.trim();
    final provider = Provider.of<CommerceProvider>(context, listen: false);
    final produit = await provider.getProduitByQr(code);

    if (produit != null) {
      showExistingProductDialog(context, code, produit, provider);
    }

    if (produit == null) {
      if (code.isNotEmpty && !_qrCodesTemp.contains(code)) {
        setState(() {
          _qrCodesTemp.add(code);
          _serialController.clear();
          _searchQr = false;
        });
      } else {
        _serialController.clear();
      }
      FocusScope.of(context).requestFocus(_serialFocusNode);
    }
  }

  Container buildColumnPicSuppliers(double largeur, BuildContext context) {
    return Container(
      child: Center(
        child: _image == null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                      ? Container(
                          width: largeur,
                          height:
                              Platform.isAndroid || Platform.isIOS ? 150 : 300,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(8.0), // Bords arrondis
                            border: Border.all(
                              color: Colors.grey, // Couleur de la bordure
                              width: 1.0, // Épaisseur de la bordure
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: _existingImageUrl!,
                              fit: BoxFit.cover, // Remplir le container
                              width: double.infinity, // Remplir en largeur
                              height: double.infinity, // Remplir en hauteur
                              placeholder: (context, url) => Center(
                                child:
                                    CircularProgressIndicator(), // Indicateur de chargement
                              ),
                              errorWidget: (context, url, error) =>
                                  Container(), // Widget en cas d'erreur
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.add_a_photo,
                            color: Colors.blue,
                          ),
                        ),
                  // Container(
                  //         width: largeur,
                  //         height:
                  //             Platform.isAndroid || Platform.isIOS ? 150 : 300,
                  //         decoration: BoxDecoration(
                  //           borderRadius:
                  //               BorderRadius.circular(8.0), // Bords arrondis
                  //           border: Border.all(
                  //             color: Colors.grey, // Couleur de la bordure
                  //             width: 1.0, // Épaisseur de la bordure
                  //           ),
                  //         ),
                  //         child: IconButton(
                  //           onPressed: _pickImage,
                  //           icon: Icon(
                  //             Icons.add_a_photo,
                  //             color: Colors.blue,
                  //           ),
                  //         ),
                  //       ),
                  _isLoadingSauv
                      ? _existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _clearAllFields2();
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ))
                          : IconButton(
                              onPressed: _pickImage,
                              icon: Icon(
                                Icons.add_a_photo,
                                color: Colors.blue,
                              ),
                            )
                      : Container(),
                ],
              )
            : Container(
                width: largeur,
                height: Platform.isAndroid || Platform.isIOS ? 150 : 300,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _image = null;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover, // Remplir le container
                          width: double.infinity, // Remplir en largeur
                          height: double.infinity, // Remplir en hauteur
                        ),
                      ),
                      Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImageSource? source = Platform.isAndroid || Platform.isIOS
        ? await showDialog<ImageSource>(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: const Text('Choisir une source'),
                children: <Widget>[
                  SimpleDialogOption(
                    padding: EdgeInsets.all(15),
                    onPressed: () {
                      Navigator.pop(context, ImageSource.gallery);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.photo),
                        SizedBox(
                          width: 5,
                        ),
                        const Text('Galerie'),
                      ],
                    ),
                  ),
                  // Platform.isAndroid || Platform.isIOS
                  //     ?
                  SimpleDialogOption(
                    padding: EdgeInsets.all(15),
                    onPressed: () {
                      Navigator.pop(context, ImageSource.camera);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
                        SizedBox(
                          width: 5,
                        ),
                        const Text('Caméra'),
                      ],
                    ),
                  )
                  // : Container()
                  ,
                ],
              );
            },
          )
        : ImageSource.gallery;

    if (source != null && mounted) {
      // Vérification ajoutée ici
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxHeight: 720, // Hauteur réduite pour les écrans mobiles
        maxWidth: 1280, // Largeur ajustée
        imageQuality:
            50, // Augmentation légère de la qualité pour un meilleur rendu
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _image = File(pickedFile.path);
          _produitImage = '';
          _existingImageUrl = '';
        });
      }
    }
  }

  double calculerStockGlobal() {
    double totalStock = 0.0;

    for (var approvisionnement in _approvisionnementTemporaire) {
      totalStock += approvisionnement.quantite;
    }

    return totalStock;
  }

// Appeler la méthode pour calculer le stock global
  void mettreAJourStockGlobal() {
    setState(() {
      stockGlobale = calculerStockGlobal();
    });
  }

  void startEditing(Approvisionnement approvisionnement) {
    setState(() {
      _currentApprovisionnement = approvisionnement;

      // Gérer les cas où `quantite` est non null, sinon mettre une valeur par défaut.
      _stockController.text = approvisionnement.quantite.toStringAsFixed(2);

      // Vérifier si `prixAchat` est non null, sinon laisser vide ou définir une valeur par défaut.
      _prixAchatController.text = approvisionnement.prixAchat != null
          ? approvisionnement.prixAchat!.toStringAsFixed(2)
          : ''; // Valeur par défaut vide

      // Vérifier si `datePeremption` est non null, sinon laisser vide.
      _datePeremptionController.text = approvisionnement.datePeremption != null
          ? DateFormat('dd MMMM yyyy', 'fr_FR')
              .format(approvisionnement.datePeremption!)
          : ''; // Valeur par défaut vide

      // Récupérer le fournisseur associé à l'approvisionnement
      _currentFournisseur = approvisionnement.fournisseur.target;
      _selectedFournisseur = _currentFournisseur;
      _isEditing = true;
    });
  }

  void supprimerApprovisionnementTemporaire(
      Approvisionnement approvisionnement) {
    setState(() {
      _approvisionnementTemporaire.remove(approvisionnement);
    });

    // Vous pouvez appeler setState() si vous utilisez un StatefulWidget
    // pour mettre à jour l'interface utilisateur.
  }

  void ajouterApprovisionnementTemporaire(Approvisionnement approvisionnement) {
    setState(() {
      _approvisionnementTemporaire.add(approvisionnement);
    });
  }

// Méthode pour gérer le changement de fournisseur
  void _onSelectedFournisseurChanged(Fournisseur fournisseur) {
    setState(() {
      _currentFournisseur = fournisseur; // Mise à jour de la variable correcte
    });
  }

  void saveApprovisionnement() {
    print(
        "Début de saveApprovisionnement"); // Log pour vérifier que la méthode est appelée

    // if (_formKeyApp.currentState!.validate())
    // {
    print("Formulaire validé avec succès");

    final quantite = double.parse(_stockController.text);
    print("Quantité récupérée : $quantite");

    // Vérification pour `prixAchat` : le laisser à null si le champ est vide
    double? prixAchat;
    if (_prixAchatController.text.isNotEmpty) {
      try {
        prixAchat = double.parse(_prixAchatController.text);
        print("Prix d'achat récupéré : $prixAchat");
      } catch (e) {
        print("Erreur lors de la conversion du prix d'achat : $e");
        return;
      }
    } else {
      print("Champ prixAchat vide, initialisé à 0.0");
      prixAchat = 0.0;
    }

    // Initialisation de `datePeremption` en vérifiant si le champ est vide
    DateTime? datePeremption;
    if (_datePeremptionController.text.isNotEmpty) {
      try {
        datePeremption = DateFormat('dd MMMM yyyy', 'fr_FR')
            .parse(_datePeremptionController.text);
        print("Date de péremption récupérée : $datePeremption");
      } catch (e) {
        print("Erreur lors du parsing de la date : $e");
        return;
      }
    } else {
      print("Aucune date de péremption spécifiée.");
    }

    // Vérifier si nous sommes en mode édition et que l'approvisionnement est sélectionné
    if (_isEditing && _currentApprovisionnement != null) {
      print("Mode édition activé pour l'approvisionnement existant");

      // Trouver l'index de l'approvisionnement dans la liste temporaire
      final int index = _approvisionnementTemporaire.indexWhere(
          (approvisionnement) =>
              approvisionnement == _currentApprovisionnement);

      if (index != -1) {
        print("Approvisionnement trouvé à l'index : $index");

        // Mettre à jour les valeurs de l'approvisionnement existant
        setState(() {
          _currentApprovisionnement!.quantite = quantite;
          _currentApprovisionnement!.prixAchat = prixAchat;
          _currentApprovisionnement!.datePeremption = datePeremption;

          // Vérifier si un fournisseur est sélectionné avant de l'assigner
          if (_selectedFournisseur != null) {
            _currentApprovisionnement!.fournisseur.target =
                _selectedFournisseur;
            print("Fournisseur sélectionné assigné à l'approvisionnement");
          } else {
            _currentApprovisionnement!.fournisseur.target = null;
            print("Aucun fournisseur sélectionné, valeur null assignée");
          }

          _currentApprovisionnement!.derniereModification = DateTime.now();
          print(
              "Dernière modification mise à jour : ${_currentApprovisionnement!.derniereModification}");

          // Remplacer l'approvisionnement dans la liste
          _approvisionnementTemporaire[index] = _currentApprovisionnement!;
          print("Approvisionnement mis à jour dans la liste temporaire");

          // Réinitialiser les champs après la modification
          _stockController.clear();
          _prixAchatController.clear();
          _datePeremptionController.clear();
          _currentFournisseur = null;
          _selectedFournisseur = null;
          _isEditing = false; // Désactiver le mode édition
          print("Champs réinitialisés et mode édition désactivé");
        });
      } else {
        print("Erreur : Approvisionnement non trouvé dans la liste.");
      }
    } else {
      print("Ajout d'un nouvel approvisionnement");

      // Si ce n'est pas une modification, créer un nouvel approvisionnement
      Approvisionnement nouveauApprovisionnement = Approvisionnement(
        quantite: quantite,
        prixAchat: prixAchat,
        datePeremption: datePeremption,
        derniereModification: DateTime.now(),
      );

      // Assigner le fournisseur sélectionné, ou laisser null si non sélectionné
      if (_currentFournisseur != null) {
        nouveauApprovisionnement.fournisseur.target = _currentFournisseur;
        print("Fournisseur courant assigné au nouvel approvisionnement");
      } else if (_selectedFournisseur != null) {
        nouveauApprovisionnement.fournisseur.target = _selectedFournisseur;
        print("Fournisseur sélectionné assigné au nouvel approvisionnement");
      } else {
        nouveauApprovisionnement.fournisseur.target = null;
        print("Aucun fournisseur assigné au nouvel approvisionnement");
      }

      // Ajouter le nouvel approvisionnement à la liste temporaire
      setState(() {
        _approvisionnementTemporaire.add(nouveauApprovisionnement);
        print("Nouveau approvisionnement ajouté à la liste temporaire");

        // Réinitialiser les champs après l'ajout
        _stockController.clear();
        _prixAchatController.clear();
        _datePeremptionController.clear();
        _currentFournisseur = null;
        _selectedFournisseur = null;
        _isEditing = false;
        print("Champs réinitialisés et mode édition désactivé après l'ajout");
      });
    }

    // Mettre à jour le stock global après modification ou ajout
    mettreAJourStockGlobal();
    print("Stock global mis à jour");
    // }
    // else {
    //   print("Formulaire invalide");
    // }

    print("Fin de saveApprovisionnement");
  }

  Widget buildDatePeremptionInfo() {
    if (_datePeremptionController.text.isEmpty) {
      // Si le champ est vide, retourner un widget vide
      return const SizedBox.shrink();
    }

    try {
      // Convertir la date de péremption
      final datePeremption = DateFormat('dd MMMM yyyy', 'fr_FR')
          .parse(_datePeremptionController.text);

      // Calculer la différence en jours
      final difference = datePeremption.difference(DateTime.now()).inDays;

      // Déterminer le message et la couleur
      String message;
      Color textColor;

      if (difference < 0) {
        // Date dépassée
        message = "Expiré depuis ${-difference} jour(s)";
        textColor = Colors.red;
      } else if (difference == 0) {
        // Aujourd'hui
        message = "Expire aujourd'hui";
        textColor = Colors.red;
      } else if (difference <= 2) {
        // Moins de 2 jours
        message = "Expire dans $difference jour(s)";
        textColor = Colors.orange;
      } else {
        // Date lointaine
        message = "Expire dans $difference jour(s)";
        textColor = Colors.black;
      }

      return Text(
        message,
        style: TextStyle(fontSize: 16, color: textColor),
      );
    } catch (e) {
      // En cas d'erreur de parsing, afficher un message d'erreur
      return const Text(
        "Date invalide",
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    }
  }
}

class FournisseurSelectionScreen extends StatefulWidget {
  final Fournisseur? selectedFournisseur; // Un seul fournisseur sélectionné
  final Function(Fournisseur)
      onSelectedFournisseurChanged; // Callback pour le changement

  const FournisseurSelectionScreen({
    Key? key,
    required this.selectedFournisseur,
    required this.onSelectedFournisseurChanged,
  }) : super(key: key);

  @override
  _FournisseurSelectionScreenState createState() =>
      _FournisseurSelectionScreenState();
}

class _FournisseurSelectionScreenState
    extends State<FournisseurSelectionScreen> {
  String _searchQuery = '';
  Fournisseur? _selectedFournisseur; // Pour stocker le fournisseur sélectionné

  @override
  void initState() {
    super.initState();
    _selectedFournisseur = widget.selectedFournisseur; // Initialisation
  }

  @override
  Widget build(BuildContext context) {
    final fournisseurProvider = Provider.of<CommerceProvider>(context);
    List<Fournisseur> filteredFournisseurs =
        fournisseurProvider.fournisseurs.where((fournisseur) {
      return fournisseur.nom.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner un Fournisseur'),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Rechercher'),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          // ElevatedButton(
          //   onPressed: () {
          //     if (_selectedFournisseur != null) {
          //       widget.onSelectedFournisseurChanged(_selectedFournisseur!);
          //     }
          //     Navigator.of(context).pop();
          //   },
          //   child: Text('Sauvegarder Sélection'),
          // ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFournisseurs.length,
              itemBuilder: (context, index) {
                final fournisseur = filteredFournisseurs[index];
                final isSelected = _selectedFournisseur ==
                    fournisseur; // Vérifie si c'est le fournisseur sélectionné
                return ListTile(
                  title: Text(fournisseur.nom),
                  tileColor: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : null, // Met en surbrillance le fournisseur sélectionné
                  onTap: () {
                    // Met à jour le fournisseur sélectionné
                    _selectedFournisseur = fournisseur;

                    // Appelle la fonction de callback pour notifier l'écran parent
                    if (_selectedFournisseur != null) {
                      widget
                          .onSelectedFournisseurChanged(_selectedFournisseur!);
                    }

                    // Renvoie le fournisseur sélectionné et ferme l'écran
                    Navigator.of(context).pop(_selectedFournisseur);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressDialog extends StatelessWidget {
  const ProgressDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          Colors.black.withOpacity(DialogConstants.opacityBackground),
      child: Padding(
        padding: const EdgeInsets.all(DialogConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: DialogConstants.padding),
            Text(
              DialogConstants.savingMessage,
              style: TextStyle(
                  color: Colors.white, fontSize: DialogConstants.fontSize),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogConstants {
  static const double opacityBackground = 0.5;
  static const double padding = 16.0;
  static const double fontSize = 16.0;
  static const String savingMessage = "Sauvegarde en cours...";
}
