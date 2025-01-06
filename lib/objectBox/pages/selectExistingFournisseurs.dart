// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../Entity.dart';
// import '../MyProviders.dart';
//
// class SelectFournisseursPage extends StatefulWidget {
//   final List<Fournisseur> allFournisseurs;
//   final List<Fournisseur> initiallySelectedFournisseurs;
//   final Produit produits;
//
//   SelectFournisseursPage({
//     required this.allFournisseurs,
//     required this.initiallySelectedFournisseurs,
//     required this.produits,
//   });
//
//   @override
//   _SelectFournisseursPageState createState() => _SelectFournisseursPageState();
// }
//
// class _SelectFournisseursPageState extends State<SelectFournisseursPage> {
//   late Set<int> selectedFournisseurIds;
//   String searchQuery = '';
//   TextEditingController searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     selectedFournisseurIds =
//         Set.from(widget.initiallySelectedFournisseurs.map((p) => p.id));
//   }
//
//   void updateSelection(Fournisseur fournisseur, bool? isSelected) {
//     setState(() {
//       if (isSelected == true) {
//         selectedFournisseurIds.add(fournisseur.id);
//       } else {
//         selectedFournisseurIds.remove(fournisseur.id);
//         supprimerFournisseur(fournisseur);
//       }
//     });
//   }
//
//   void supprimerFournisseur(Fournisseur fournisseur) {
//     final provider = Provider.of<CommerceProvider>(context, listen: false);
//     provider.supprimerFournisseurDuProduit(widget.produits, fournisseur);
//     print(
//         'Fournisseur supprimé - Produit ID: ${widget.produits.id}, Fournisseur  ID: ${fournisseur.id}');
//   }
//
//   List<Fournisseur> get filteredFournisseurs {
//     return widget.allFournisseurs
//         .where((fournisseurs) {
//           final lowercaseQuery = searchQuery.toLowerCase();
//           return fournisseurs.nom.toLowerCase().contains(lowercaseQuery) ||
//               fournisseurs.id.toString().contains(lowercaseQuery);
//         })
//         .toList()
//         .reversed
//         .toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Sélectionner des Fournisseurs'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.check),
//             onPressed: () {
//               Navigator.of(context).pop(widget.allFournisseurs
//                   .where((p) => selectedFournisseurIds.contains(p.id))
//                   .toList());
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 labelText: 'Rechercher par Nom de Fournisseur ou ID',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value;
//                 });
//               },
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredFournisseurs.length,
//               itemBuilder: (context, index) {
//                 final fournisseur = filteredFournisseurs[index];
//                 final isSelected =
//                     selectedFournisseurIds.contains(fournisseur.id);
//                 return ListTile(
//                   title: Text(fournisseur.nom),
//                   trailing: Checkbox(
//                     value: isSelected,
//                     onChanged: (bool? value) =>
//                         updateSelection(fournisseur, value),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
