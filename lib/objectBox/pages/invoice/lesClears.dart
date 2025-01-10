// class FactureDetail extends StatelessWidget {
//   final TextEditingController _rechercheController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<FacturationProvider>(context);
//     final facture = provider.factureEnCours;
//
//     return Column(
//       children: [
//         TextField(
//           controller: _rechercheController,
//           decoration: InputDecoration(
//             labelText: 'Rechercher un produit',
//             suffixIcon: IconButton(
//               icon: Icon(Icons.clear),
//               onPressed: () {
//                 _rechercheController.clear();
//                 provider.rechercherProduits('');
//               },
//             ),
//           ),
//           onChanged: (value) {
//             provider.rechercherProduits(value);
//           },
//         ),
//         if (provider.produitsTrouves.isNotEmpty)
//           Expanded(
//             child: ListView.builder(
//               itemCount: provider.produitsTrouves.length,
//               itemBuilder: (context, index) {
//                 final produit = provider.produitsTrouves[index];
//                 return ListTile(
//                   title: Text(produit.nom),
//                   subtitle: Text('Prix: ${produit.prixVente}'),
//                   trailing: IconButton(
//                     icon: Icon(Icons.add),
//                     onPressed: () {
//                       provider.ajouterProduitALaFacture(
//                           produit, 1, produit.prixVente);
//                       provider.rechercherProduits(
//                           ''); // Fermer la liste des produits
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             children: [
//               Text(
//                   'Total HT: ${provider.calculerTotalHT().toStringAsFixed(2)}'),
//               Text('TVA: ${provider.calculerTVA().toStringAsFixed(2)}'),
//               Text(
//                   'Total TTC: ${provider.calculerTotalTTC().toStringAsFixed(2)}'),
//             ],
//           ),
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 provider.creerNouvelleFacture(); // Crée une nouvelle facture
//               },
//               child: Text('Nouvelle Facture'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (provider.factureEnCours == null) {
//                   provider
//                       .creerNouvelleFacture(); // Crée une nouvelle facture si aucune n'est sélectionnée
//                 }
//                 provider.sauvegarderFacture();
//               },
//               child: Text('Sauvegarder la facture'),
//             ),
//           ],
//         ),
//         Expanded(
//           child: SingleChildScrollView(
//             child: DataTable(
//               columns: const [
//                 DataColumn(label: Text('Produit')),
//                 DataColumn(label: Text('Quantité')),
//                 DataColumn(label: Text('Prix Unitaire')),
//                 DataColumn(label: Text('Total')),
//                 DataColumn(label: Text('Actions')),
//               ],
//               rows: provider.lignesFacture.map((ligne) {
//                 final index = provider.lignesFacture.indexOf(ligne);
//                 final state = provider.getLigneEditionState(index);
//
//                 return DataRow(
//                   cells: [
//                     DataCell(
//                         Text(ligne.produit.target?.nom ?? 'Produit inconnu')),
//                     DataCell(
//                       state.isEditedQty
//                           ? TextFormField(
//                               initialValue: ligne.quantite.toStringAsFixed(2),
//                               keyboardType: TextInputType.number,
//                               onChanged: (value) {
//                                 final nouvelleQuantite =
//                                     double.tryParse(value) ?? 0;
//                                 provider.modifierLigne(
//                                   index,
//                                   nouvelleQuantite,
//                                   ligne.prixUnitaire,
//                                 );
//                               },
//                               onTapOutside: (event) {
//                                 provider.toggleEditQty(
//                                     index); // Désactiver l'édition de la quantité
//                               },
//                               onEditingComplete: () {
//                                 provider.toggleEditQty(
//                                     index); // Désactiver l'édition de la quantité
//                               },
//                             )
//                           : Text(ligne.quantite.toStringAsFixed(2)),
//                       onTap: () {
//                         provider.toggleEditQty(
//                             index); // Activer l'édition de la quantité
//                       },
//                     ),
//                     DataCell(
//                       state.isEditedPu
//                           ? TextFormField(
//                               initialValue:
//                                   ligne.prixUnitaire.toStringAsFixed(2),
//                               keyboardType: TextInputType.number,
//                               onChanged: (value) {
//                                 final nouveauPrix = double.tryParse(value) ?? 0;
//                                 provider.modifierLigne(
//                                   index,
//                                   ligne.quantite,
//                                   nouveauPrix,
//                                 );
//                               },
//                               onTapOutside: (event) {
//                                 provider.toggleEditPu(
//                                     index); // Désactiver l'édition du prix
//                               },
//                             )
//                           : Text(ligne.prixUnitaire.toStringAsFixed(2)),
//                       onTap: () {
//                         provider
//                             .toggleEditPu(index); // Activer l'édition du prix
//                       },
//                     ),
//                     DataCell(Text((ligne.quantite * ligne.prixUnitaire)
//                         .toStringAsFixed(2))),
//                     DataCell(
//                       IconButton(
//                         icon: Icon(Icons.delete),
//                         onPressed: () {
//                           provider.supprimerLigne(index);
//                         },
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class FactureDetail extends StatefulWidget {
//   @override
//   State<FactureDetail> createState() => _FactureDetailState();
// }
//
// class _FactureDetailState extends State<FactureDetail> {
//   final TextEditingController _rechercheController = TextEditingController();
//
//   bool isEditedQty = false;
//
//   bool isEditedPu = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<FacturationProvider>(context);
//     final facture = provider.factureEnCours;
//
//     return Column(
//       children: [
//         TextField(
//           controller: _rechercheController,
//           decoration: InputDecoration(
//             labelText: 'Rechercher un produit',
//             suffixIcon: IconButton(
//               icon: Icon(Icons.clear),
//               onPressed: () {
//                 _rechercheController.clear();
//                 provider.rechercherProduits('');
//               },
//             ),
//           ),
//           onChanged: (value) {
//             provider.rechercherProduits(value);
//           },
//         ),
//         if (provider.produitsTrouves.isNotEmpty)
//           Expanded(
//             child: ListView.builder(
//               itemCount: provider.produitsTrouves.length,
//               itemBuilder: (context, index) {
//                 final produit = provider.produitsTrouves[index];
//                 return ListTile(
//                   title: Text(produit.nom),
//                   subtitle: Text('Prix: ${produit.prixVente}'),
//                   trailing: IconButton(
//                     icon: Icon(Icons.add),
//                     onPressed: () {
//                       provider.ajouterProduitALaFacture(
//                           produit, 1, produit.prixVente);
//                       provider.rechercherProduits(
//                           ''); // Fermer la liste des produits
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             children: [
//               Text(
//                   'Total HT: ${provider.calculerTotalHT().toStringAsFixed(2)}'),
//               Text('TVA: ${provider.calculerTVA().toStringAsFixed(2)}'),
//               Text(
//                   'Total TTC: ${provider.calculerTotalTTC().toStringAsFixed(2)}'),
//             ],
//           ),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (provider.factureEnCours == null) {
//               provider
//                   .creerNouvelleFacture(); // Crée une nouvelle facture si aucune n'est sélectionnée
//             }
//             provider.sauvegarderFacture();
//           },
//           child: Text('Sauvegarder la facture'),
//         ),
//         Expanded(
//           child: SingleChildScrollView(
//             child: DataTable(
//               columns: const [
//                 DataColumn(label: Text('Produit')),
//                 DataColumn(label: Text('Quantité')),
//                 DataColumn(label: Text('Prix Unitaire')),
//                 DataColumn(label: Text('Total')),
//                 DataColumn(label: Text('Actions')),
//               ],
//               rows: provider.lignesFacture.map((ligne) {
//                 return DataRow(
//                   cells: [
//                     DataCell(
//                         Text(ligne.produit.target?.nom ?? 'Produit inconnu')),
//                     DataCell(
//                         isEditedQty
//                             ? TextFormField(
//                                 initialValue: ligne.quantite.toStringAsFixed(2),
//                                 keyboardType: TextInputType.number,
//                                 onChanged: (value) {
//                                   final nouvelleQuantite =
//                                       double.tryParse(value) ?? 0;
//                                   provider.modifierLigne(
//                                     provider.lignesFacture.indexOf(ligne),
//                                     nouvelleQuantite,
//                                     ligne.prixUnitaire,
//                                   );
//                                 },
//                                 onEditingComplete: () {
//                                   setState(() {
//                                     isEditedQty = !isEditedQty;
//                                   });
//                                 },
//                               )
//                             : Text(ligne.quantite.toStringAsFixed(2)),
//                         onTap: () {
//                       setState(() {
//                         isEditedQty = !isEditedQty;
//                       });
//                     }),
//                     DataCell(
//                         isEditedPu
//                             ? TextFormField(
//                                 initialValue:
//                                     ligne.prixUnitaire.toStringAsFixed(2),
//                                 keyboardType: TextInputType.number,
//                                 onChanged: (value) {
//                                   final nouveauPrix =
//                                       double.tryParse(value) ?? 0;
//                                   provider.modifierLigne(
//                                     provider.lignesFacture.indexOf(ligne),
//                                     ligne.quantite,
//                                     nouveauPrix,
//                                   );
//                                 },
//                                 onEditingComplete: () {
//                                   setState(() {
//                                     isEditedPu = !isEditedPu;
//                                   });
//                                 },
//                               )
//                             : Text(ligne.prixUnitaire.toStringAsFixed(2)),
//                         onTap: () {
//                       setState(() {
//                         isEditedPu = !isEditedPu;
//                       });
//                     }),
//                     DataCell(Text((ligne.quantite * ligne.prixUnitaire)
//                         .toStringAsFixed(2))),
//                     DataCell(
//                       IconButton(
//                         icon: Icon(Icons.delete),
//                         onPressed: () {
//                           provider.supprimerLigne(
//                               provider.lignesFacture.indexOf(ligne));
//                         },
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
