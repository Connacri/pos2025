import 'package:flutter/material.dart';

import '../../objectbox.g.dart';
import '../Entity.dart';

class DuplicateGroup {
  final String qr;
  final List<Produit> produits;

  DuplicateGroup(this.qr, this.produits);
}

Future<List<DuplicateGroup>> getDuplicateProducts() async {
  final store = await openStore();
  final produitBox = store.box<Produit>();

  final allProducts = produitBox.getAll();
  final Map<String, List<Produit>> nameMap = {};

  for (var produit in allProducts) {
    final cleanName = produit.nom!.replaceAll(' ', '').trim().toLowerCase();
    if (nameMap.containsKey(cleanName)) {
      nameMap[cleanName]!.add(produit);
    } else {
      nameMap[cleanName] = [produit];
    }
  }

  final duplicates = nameMap.entries
      .where((entry) => entry.value.length > 1)
      .map((entry) => DuplicateGroup(entry.key, entry.value))
      .toList();

  store.close();
  return duplicates;
}

class DuplicateProductsListView extends StatefulWidget {
  @override
  _DuplicateProductsListViewState createState() =>
      _DuplicateProductsListViewState();
}

class _DuplicateProductsListViewState extends State<DuplicateProductsListView> {
  List<DuplicateGroup> duplicateGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDuplicates();
  }

  Future<void> fetchDuplicates() async {
    try {
      final duplicates = await getDuplicateProducts();
      setState(() {
        duplicateGroups = duplicates;
        isLoading = false;
      });
    } catch (error) {
      print("Erreur lors de la récupération des doublons: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          appBar: AppBar(), body: Center(child: CircularProgressIndicator()));
    }

    if (duplicateGroups.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
              'Aucun doublon trouvé. Tous les produits ont des noms uniques.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: duplicateGroups.length,
        itemBuilder: (context, index) {
          final group = duplicateGroups[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text('Nom du produit: ${group.qr}'),
              children: group.produits
                  .map((produit) => ListTile(
                        title: Text(produit.nom),
                        subtitle: Text(
                            'ID: ${produit.id}, Dernière modification: ${produit.derniereModification}'),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
