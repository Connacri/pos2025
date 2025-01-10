import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/src/relations/to_many.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import '../Entity.dart';
import '../MyProviders.dart';
import '../Utils/QRViewExample.dart';
import '../Utils/mobile_scanner/barcode_scanner_simple.dart';
import '../classeObjectBox.dart';
import 'ClientListScreen.dart';
import 'ProduitListScreen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'addProduct.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import 'facturation/FacturePage.dart';

class ClientSelectionPage extends StatefulWidget {
  @override
  _ClientSelectionPageState createState() => _ClientSelectionPageState();
}

class _ClientSelectionPageState extends State<ClientSelectionPage> {
  String _searchQuery = '';
  List<Client> _filteredClients = [];
  Client? _selectedClient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filteredClients = Provider.of<CommerceProvider>(context).clients;
    _filterClients(_searchQuery);
  }

  void _filterClients(String query) {
    setState(() {
      _searchQuery = query;
      _filteredClients = Provider.of<ClientProvider>(context, listen: false)
          .clients
          .where((client) =>
              client.nom.toLowerCase().contains(query.toLowerCase()) ||
              client.id.toString().contains(query) ||
              client.qr.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner un client'),
        actions: [
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
                  _filteredClients;
                });
                cartProvider.setSelectedClient(newClient);
              } else {}
            },
          ),
        ],
      ),
      body: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un client',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterClients,
            ),
            Expanded(
                child: ListView.builder(
              itemCount: _filteredClients.length,
              itemBuilder: (context, index) {
                final client =
                    _filteredClients[_filteredClients.length - 1 - index];
                return ListTile(
                  title: Text(client.id.toString() + '  ' + client.nom),
                  subtitle: Text(client.phone),
                  onTap: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .selectClient(client);
                    Navigator.of(context).pop();
                  },
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

class FactureDetailPage extends StatefulWidget {
  final Document facture;

  final CartProvider cartProvider;
  final CommerceProvider commerceProvider;

  FactureDetailPage({
    required this.facture,
    required this.cartProvider,
    required this.commerceProvider,
  });

  @override
  State<FactureDetailPage> createState() => _FactureDetailPageState();
}

class _FactureDetailPageState extends State<FactureDetailPage> {
  @override
  Widget build(BuildContext context) {
    final lignesFacture = widget.facture.lignesDocument;
    final client = widget.facture.client.target;
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Facture ${widget.facture.id}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                client != null
                    ? Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => ClientDetailsPage(
                          client: client,
                        ),
                      ))
                    : null;
              },
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: client != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Client: ${client.nom}',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text('Téléphone: ${client.phone}'),
                                  Text('Adresse: ${client.adresse}'),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text('qr: ${client.qr}'),
                                  Text(
                                      'Nombre de factures : ${client.factures.length}'),
                                ],
                              )
                            : Text('Aucun client sélectionné'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nom du Produit')),
                    DataColumn(label: Text('Prix Unitaire')),
                    DataColumn(label: Text('Quantité')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: lignesFacture.map((ligneFacture) {
                    final produit = ligneFacture.produit.target!;
                    return DataRow(cells: [
                      DataCell(Text(produit.id.toString())),
                      DataCell(Text(produit.nom)),
                      DataCell(Text(
                          '${ligneFacture.prixUnitaire.toStringAsFixed(2)} DZD')),
                      DataCell(Text(ligneFacture.quantite.toString())),
                      DataCell(Text(
                        '${(ligneFacture.prixUnitaire * ligneFacture.quantite).toStringAsFixed(2)} DZD',
                      )),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _showEditDialog(context, ligneFacture);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _showEditDialog(context, ligneFacture);
                              },
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${_calculateTotal().toStringAsFixed(2)} DZD',
                  style: TextStyle(color: Colors.green),
                ),
                Text('TVA (19%): ${_calculateTVA().toStringAsFixed(2)} DZD'),
                Text(
                    'Total TTC: ${(_calculateTotal() + _calculateTVA()).toStringAsFixed(2)} DZD'),
                Text(
                  'Impayer: ${widget.facture.impayer!.toStringAsFixed(2)} DZD',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.cartProvider.saveFacture(widget.commerceProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Facture sauvegardée!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
              }
            },
            child: Text('Sauvegarder la facture'),
          ),
          SizedBox(height: 40)
        ],
      ),
    );
  }

  double _calculateTotal() {
    return widget.facture.lignesDocument
        .fold(0, (sum, item) => sum + item.prixUnitaire * item.quantite);
  }

  double _calculateTVA() {
    return _calculateTotal() * 0.19;
  }

  void _showEditDialog(BuildContext context, LigneDocument ligneFacture) {
    TextEditingController _quantiteController = TextEditingController(
      text: ligneFacture.quantite.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier la quantité'),
          content: TextField(
            controller: _quantiteController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantité'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                double newQuantite =
                    double.tryParse(_quantiteController.text) ?? 0.0;
                if (newQuantite > 0) {
                  ligneFacture.quantite = newQuantite;
                  setState(() {});
                }
                Navigator.of(context).pop();
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

class ProductSearchField extends StatelessWidget {
  final TextEditingController _barcodeBufferController;
  final Function(BuildContext, CommerceProvider, CartProvider, double,
      List<LigneDocument>) _processBarcode;

  ProductSearchField(this._barcodeBufferController, this._processBarcode);

  @override
  Widget build(BuildContext context) {
    final commerceProvider = Provider.of<CommerceProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Autocomplete<Produit>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text == '') {
          return const Iterable<Produit>.empty();
        }
        return await commerceProvider.rechercherProduits(textEditingValue.text);
      },
      displayStringForOption: (Produit option) => '${option.id} ${option.nom}',
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: 'Code Produit (ID ou QR)',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: onFieldSubmitted,
            ),
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty && double.tryParse(value) != null) {
              _processBarcode(
                context,
                commerceProvider,
                cartProvider,
                double.parse('1'),
                cartProvider.facture.lignesDocument,
              );
              fieldTextEditingController.clear();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Entrée invalide. Veuillez entrer un code valide.')),
              );
            }
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Produit> onSelected,
          Iterable<Produit> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              height: 200.0,
              width: 300.0,
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Produit option = options.elementAt(index);
                  return ListTile(
                    title: Text('${option.id} ${option.nom}'),
                    subtitle: Text(
                        'Prix: ${option.prixVente.toStringAsFixed(2)} DZD'),
                    onTap: () {
                      onSelected(option);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        cartProvider.addToCart(option);
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //       content: Text('${option.nom} ajouté au panier')),
                        // );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (Produit selection) {
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
