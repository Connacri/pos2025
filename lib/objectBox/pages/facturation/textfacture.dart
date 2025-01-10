import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LigneFactureTemp {
  int produitId;
  String nomProduit;
  double prixUnitaire;
  int quantite;
  double total;

  LigneFactureTemp({
    required this.produitId,
    required this.nomProduit,
    required this.prixUnitaire,
    required this.quantite,
  }) : total = prixUnitaire * quantite;

  void updateQuantite(int nouvelleQuantite) {
    quantite = nouvelleQuantite;
    total = prixUnitaire * quantite;
  }

  void updatePrix(double nouveauPrix) {
    prixUnitaire = nouveauPrix;
    total = prixUnitaire * quantite;
  }
}

class FactureProvider with ChangeNotifier {
  List<LigneFactureTemp> lignesFacture = [];

  void ajouterProduit(LigneFactureTemp ligne) {
    lignesFacture.add(ligne);
    notifyListeners();
  }

  void modifierProduit(int index, int nouvelleQuantite, double nouveauPrix) {
    lignesFacture[index].updateQuantite(nouvelleQuantite);
    lignesFacture[index].updatePrix(nouveauPrix);
    notifyListeners();
  }

  void supprimerProduit(int index) {
    lignesFacture.removeAt(index);
    notifyListeners();
  }

  void viderFacture() {
    lignesFacture.clear();
    notifyListeners();
  }
}

class FacturePageTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final factureProvider = Provider.of<FactureProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion de la Facture'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Sauvegarder la facture dans ObjectBox
              sauvegarderFactureDansObjectBox(factureProvider.lignesFacture);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Produit')),
                  DataColumn(label: Text('Quantité')),
                  DataColumn(label: Text('Prix Unitaire')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Actions')),
                ],
                rows:
                    factureProvider.lignesFacture.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ligne = entry.value;
                  return DataRow(cells: [
                    DataCell(Text(ligne.nomProduit)),
                    DataCell(
                      TextFormField(
                        initialValue: ligne.quantite.toString(),
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (val) {
                          final quantite = int.tryParse(val) ?? ligne.quantite;
                          factureProvider.modifierProduit(
                            index,
                            quantite,
                            ligne.prixUnitaire,
                          );
                        },
                      ),
                    ),
                    DataCell(
                      TextFormField(
                        initialValue: ligne.prixUnitaire.toStringAsFixed(2),
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (val) {
                          final prix =
                              double.tryParse(val) ?? ligne.prixUnitaire;
                          factureProvider.modifierProduit(
                            index,
                            ligne.quantite,
                            prix,
                          );
                        },
                      ),
                    ),
                    DataCell(Text(ligne.total.toStringAsFixed(2))),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          factureProvider.supprimerProduit(index);
                        },
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Ajouter un nouveau produit
              factureProvider.ajouterProduit(
                LigneFactureTemp(
                  produitId: 1,
                  nomProduit: 'Produit Exemple',
                  prixUnitaire: 100.0,
                  quantite: 1,
                ),
              );
            },
            child: Text('Ajouter Produit'),
          ),
        ],
      ),
    );
  }

  void sauvegarderFactureDansObjectBox(List<LigneFactureTemp> lignesFacture) {
    // Convertir la liste temporaire en entités ObjectBox
    // Sauvegarder dans la base
    print("Facture sauvegardée : ${lignesFacture.length} produits");
  }
}
