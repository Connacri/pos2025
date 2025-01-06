import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../Entity.dart';
import '../MyProviders.dart';
import '../Utils/QRViewExample.dart';
import 'FournisseurListScreen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AddFournisseurFormFromProduit extends StatefulWidget {
  final Produit produit;

  AddFournisseurFormFromProduit({Key? key, required this.produit})
      : super(key: key);
  @override
  _AddFournisseurFormFromProduitState createState() =>
      _AddFournisseurFormFromProduitState();
}

class _AddFournisseurFormFromProduitState
    extends State<AddFournisseurFormFromProduit> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _creationController = TextEditingController();
  final _derniereModificationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fournisseurs'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .viewInsets
              .bottom, // Permet de remonter le BottomSheet lorsque le clavier apparaît
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter un Fournisseur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomController,
                    decoration: InputDecoration(labelText: 'Nom'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'Phone'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un Tel';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _adresseController,
                    decoration: InputDecoration(labelText: 'Adresse'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une adresse';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final fournisseur = Fournisseur(
                        qr: '',
                        nom: _nomController.text,
                        phone: _phoneController.text,
                        adresse: _adresseController.text,
                        derniereModification: DateTime.now(),
                      )..crud.target = Crud(
                          createdBy: 1,
                          updatedBy: 1,
                          deletedBy: 1,
                          dateCreation:
                              DateTime.parse(_creationController.text),
                          derniereModification: DateTime.parse(
                              _derniereModificationController.text),
                          dateDeleting: null,
                        );
                      context
                          .read<CommerceProvider>()
                          .addFournisseur(fournisseur);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Ajouter'),
                ),
              ],
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _phoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }
}

class FournisseurSelectionScreen extends StatefulWidget {
  final Produit? produit;
  final List<Fournisseur> selectedFournisseurs;
  final Function(List<Fournisseur>) onSelectedFournisseursChanged;

  const FournisseurSelectionScreen({
    Key? key,
    this.produit,
    required this.selectedFournisseurs,
    required this.onSelectedFournisseursChanged,
  }) : super(key: key);

  @override
  _FournisseurSelectionScreenState createState() =>
      _FournisseurSelectionScreenState();
}

class _FournisseurSelectionScreenState
    extends State<FournisseurSelectionScreen> {
  String _searchQuery = '';
  late List<Fournisseur> _selectedFournisseurs;

  @override
  void initState() {
    super.initState();
    _selectedFournisseurs = List.from(widget.selectedFournisseurs);
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
        title: Text('Sélectionner Fournisseurs'),
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
          ElevatedButton(
            onPressed: () {
              widget.onSelectedFournisseursChanged(_selectedFournisseurs);
              Navigator.of(context).pop();
            },
            child: Text('Sauvegarder Sélection'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFournisseurs.length,
              itemBuilder: (context, index) {
                final fournisseur = filteredFournisseurs[index];
                final isSelected = _selectedFournisseurs.contains(fournisseur);
                return ListTile(
                  title: Text(fournisseur.nom),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected!) {
                          _selectedFournisseurs.add(fournisseur);
                        } else {
                          _selectedFournisseurs.remove(fournisseur);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FournisseurSearchDelegate extends SearchDelegate<Fournisseur> {
  final Produit produit;

  FournisseurSearchDelegate(this.produit);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestions(context);
  }

  Widget _buildSuggestions(BuildContext context) {
    final fournisseurProvider =
        Provider.of<CommerceProvider>(context, listen: false);
    final produitProvider =
        Provider.of<CommerceProvider>(context, listen: false);

    final fournisseurs = fournisseurProvider.fournisseurs.where((fournisseur) {
      return fournisseur.nom.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: fournisseurs.length,
      itemBuilder: (context, index) {
        final fournisseur = fournisseurs[index];

        return ListTile(
          title: Text(fournisseur.nom),
          onTap: () {
            close(context, fournisseur);
          },
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Vérifie si le fournisseur n'est pas déjà dans la liste des fournisseurs du produit
              if (!produit.approvisionnements.any(
                  (appro) => appro.fournisseur.target?.id == fournisseur.id)) {
                // Crée un nouvel approvisionnement avec le fournisseur
                Approvisionnement nouvelApprovisionnement = Approvisionnement(
                  quantite:
                      0, // Valeur par défaut ou à modifier selon ton besoin
                  prixAchat:
                      0, // Valeur par défaut ou à modifier selon ton besoin
                  derniereModification: DateTime.now(),
                );
                nouvelApprovisionnement.fournisseur.target = fournisseur;

                // Ajoute l'approvisionnement au produit
                produit.approvisionnements.add(nouvelApprovisionnement);
                // Met à jour le produit dans le provider
                produitProvider.updateProduit(produit);
              }
              // Ferme le dialogue ou la page actuelle
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
