import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/objectBox/Entity.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import '../../Utils/winMobile.dart';
import '../ClientListScreen.dart';
import 'providers.dart';

class FacturationPageUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('POS'),
            Spacer(),
            Text(
              '${DateFormat('EEE dd MMM yyyy - HH:mm', 'fr').format(DateTime.now()).capitalize()}',
            ),
          ],
        ),
        actions: [
          WinMobile(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        icon: Icon(Icons.receipt_long, color: Colors.blue),
                        text: 'Détails',
                      ),
                      Tab(
                        icon: Icon(Icons.list, color: Colors.blue),
                        text: 'Liste',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        FactureDetail(),
                        FactureList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          // Pour les écrans moyens
          else if (constraints.maxWidth < 1200) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FactureDetail(),
                ),
                Expanded(
                  flex: 1,
                  child: FactureList(),
                ),
              ],
            );
          }
          // Pour les grands écrans
          else {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(child: FactureDetail()),
                ),
                Expanded(
                  flex: 1,
                  child: FactureList(),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class FactureDetail extends StatefulWidget {
  @override
  State<FactureDetail> createState() => _FactureDetailState();
}

class _FactureDetailState extends State<FactureDetail> {
  final TextEditingController _rechercheController = TextEditingController();

  final TextEditingController _impayerController =
      TextEditingController(text: '0');

  @override
  void dispose() {
    _rechercheController.dispose();
    _impayerController.dispose();
    // Nettoyer le contrôleur pour éviter les fuites de mémoire
    // _impayerController.removeListener(_updateDisplayText);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);
    // Mettez à jour l'impayerController lorsque la facture change
    if (provider.factureEnCours != null) {
      _impayerController.text = provider.impayer.toStringAsFixed(2);
    }

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TextField(
                controller: _rechercheController,
                decoration: InputDecoration(
                  labelText: 'Rechercher un produit',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _rechercheController.clear();
                      provider.rechercherProduits('');
                    },
                  ),
                ),
                onChanged: (value) {
                  provider.rechercherProduits(value);
                },
              ),
            ),
            if (provider.produitsTrouves.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ListView.builder(
                    itemCount: provider.produitsTrouves.length,
                    itemBuilder: (context, index) {
                      final produit = provider.produitsTrouves[index];
                      return ListTile(
                        title: Text(produit.nom),
                        subtitle: Text('Prix: ${produit.prixVente}'),
                        trailing: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            provider.ajouterProduitALaFacture(
                                produit, 1, produit.prixVente);
                            _rechercheController.clear();
                            provider.rechercherProduits('');
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClientInfos(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TTC(
                          totalAmount: provider.calculerTotalHT(),
                          localImpayer:
                              double.tryParse(_impayerController.text) ?? 0.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TotalDetail(
                            totalAmount: provider.calculerTotalHT(),
                            localImpayer:
                                double.tryParse(_impayerController.text) ?? 0.0,
                            facture: provider.factureEnCours!),
                      ),
                      provider.lignesFacture.isEmpty
                          ? SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: EditableField(
                                initialValue: provider.impayer,
                                impayerController: _impayerController,
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: provider.lignesFacture.isEmpty
                                  ? null
                                  : () {
                                      provider
                                          .creerNouvelleFacture(); // Crée une nouvelle facture
                                      _impayerController.clear();
                                      _rechercheController.clear();
                                      context
                                          .read<EditableFieldProvider>()
                                          .AlwaystoggleEditable();
                                    },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              label: Text('Nouvelle'),
                              icon: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Icon(Icons.add),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: provider.lignesFacture.isEmpty
                                  ? null
                                  : () {
                                      provider.sauvegarderFacture();
                                      _impayerController.clear();
                                      context
                                          .read<EditableFieldProvider>()
                                          .AlwaystoggleEditable();
                                    },
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              label: Text('Sauvegarder'),
                              icon: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Icon(Icons.save),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: provider.lignesFacture.length,
                        itemBuilder: (context, index) {
                          final ligne = provider.lignesFacture[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Slidable(
                                // Specify a key if the Slidable is dismissible.
                                key: const ValueKey(0),

                                // The start action pane is the one at the left or the top side.
                                startActionPane: ActionPane(
                                  // A motion is a widget used to control how the pane animates.
                                  motion: const ScrollMotion(),

                                  // A pane can dismiss the Slidable.
                                  dismissible: DismissiblePane(onDismissed: () {
                                    provider.supprimerLigne(index);
                                  }),

                                  // All actions are defined in the children parameter.
                                  children: [
                                    // A SlidableAction can have an icon and/or a label.
                                    SlidableAction(
                                      onPressed: (context) {
                                        provider.supprimerLigne(index);
                                      },
                                      backgroundColor: Color(0xFFFE4A49),
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),

                                // The end action pane is the one at the right or the bottom side.
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  dismissible: DismissiblePane(onDismissed: () {
                                    _showEditDialog(
                                        context, ligne, provider, index);
                                  }),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        _showEditDialog(
                                            context, ligne, provider, index);
                                      },
                                      backgroundColor: Color(0xFF0392CF),
                                      foregroundColor: Colors.white,
                                      icon: Icons.save,
                                      label: 'Edite',
                                    ),
                                  ],
                                ),

                                // The child of the Slidable is what the user sees when the
                                // component is not dragged.
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: FittedBox(
                                        child: Text(
                                            '${ligne.quantite.toStringAsFixed(2)}'),
                                      ),
                                    ),
                                  ),
                                  title: Text(ligne.produit.target?.nom ??
                                      'Produit inconnu'),
                                  subtitle: Text(
                                      'PU: ${ligne.prixUnitaire.toStringAsFixed(2)}'),
                                  trailing: Text(
                                    '${(ligne.quantite * ligne.prixUnitaire).toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                )),
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(flex: 4, child: ClientInfos()),
                            Expanded(
                              flex: 3,
                              child: TTC(
                                totalAmount: provider.calculerTotalHT(),
                                localImpayer:
                                    double.tryParse(_impayerController.text) ??
                                        0.0,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TotalDetail(
                                  totalAmount: provider.calculerTotalHT(),
                                  localImpayer: double.tryParse(
                                          _impayerController.text) ??
                                      0.0,
                                  facture: provider.factureEnCours),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Spacer(
                                flex: 1,
                              ),
                              Expanded(
                                flex: 3,
                                child: provider.lignesFacture.isEmpty
                                    ? SizedBox.shrink()
                                    : EditableField(
                                        initialValue: provider.impayer,
                                        impayerController: _impayerController,
                                      ),
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              ElevatedButton.icon(
                                onPressed: provider.lignesFacture.isEmpty
                                    ? null
                                    : () {
                                        provider
                                            .creerNouvelleFacture(); // Crée une nouvelle facture
                                        _impayerController.clear();
                                        _rechercheController.clear();
                                        context
                                            .read<EditableFieldProvider>()
                                            .AlwaystoggleEditable();
                                      },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                                label: Text('Nouvelle Facture'),
                                icon: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  child: Icon(Icons.add),
                                ),
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              ElevatedButton.icon(
                                onPressed: provider.lignesFacture.isEmpty
                                    ? null
                                    : () {
                                        provider.sauvegarderFacture();
                                        _impayerController.clear();
                                        context
                                            .read<EditableFieldProvider>()
                                            .AlwaystoggleEditable();
                                      },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                                label: Text('Sauvegarder la facture'),
                                icon: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  child: Icon(Icons.save),
                                ),
                              ),
                              Spacer(
                                flex: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: double.infinity,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Produit')),
                              DataColumn(label: Text('Quantité')),
                              DataColumn(label: Text('Prix Unitaire')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: provider.lignesFacture.map((ligne) {
                              final index =
                                  provider.lignesFacture.indexOf(ligne);
                              final state =
                                  provider.getLigneEditionState(index);

                              return DataRow(
                                cells: [
                                  DataCell(Text(ligne.produit.target?.nom ??
                                      'Produit inconnu')),
                                  DataCell(
                                    // state.isEditedQty
                                    //     ? TextFormField(
                                    //         initialValue: ligne.quantite.toStringAsFixed(2),
                                    //         keyboardType: TextInputType.number,
                                    //         onChanged: (value) {
                                    //           final nouvelleQuantite =
                                    //               double.tryParse(value) ?? 0;
                                    //           provider.modifierLigne(
                                    //             index,
                                    //             nouvelleQuantite,
                                    //             ligne.prixUnitaire,
                                    //           );
                                    //         },
                                    //         onTapOutside: (event) {
                                    //           provider.toggleEditQty(index);
                                    //         },
                                    //       )
                                    //     :
                                    Text(ligne.quantite.toStringAsFixed(2)),
                                    // onTap: () {
                                    //   provider.toggleEditQty(index);
                                    // },
                                    // onTapDown: (TapDownDetails) {
                                    //   provider.toggleEditQty(index);
                                    // },
                                    // onTapCancel: () {
                                    //   provider.toggleEditQty(index);
                                    // },
                                  ),
                                  DataCell(
                                    // state.isEditedPu
                                    //     ? TextFormField(
                                    //         initialValue:
                                    //             ligne.prixUnitaire.toStringAsFixed(2),
                                    //         keyboardType: TextInputType.number,
                                    //         onChanged: (value) {
                                    //           final nouveauPrix =
                                    //               double.tryParse(value) ?? 0;
                                    //           provider.modifierLigne(
                                    //             index,
                                    //             ligne.quantite,
                                    //             nouveauPrix,
                                    //           );
                                    //         },
                                    //         onTapOutside: (event) {
                                    //           provider.toggleEditPu(index);
                                    //         },
                                    //       )
                                    //     :
                                    Text(ligne.prixUnitaire.toStringAsFixed(2)),
                                    //     onTap: () {
                                    //   provider.toggleEditPu(index);
                                    // }, showEditIcon: true
                                  ),
                                  DataCell(Text(
                                      (ligne.quantite * ligne.prixUnitaire)
                                          .toStringAsFixed(2))),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            provider.supprimerLigne(index);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditDialog(context, ligne,
                                                provider, index);
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
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );

    //   Scaffold(
    //   body: SingleChildScrollView(
    //     scrollDirection: Axis.vertical,
    //     child: Column(
    //       children: [
    //         Padding(
    //           padding: const EdgeInsets.symmetric(horizontal: 28),
    //           child: TextField(
    //             controller: _rechercheController,
    //             decoration: InputDecoration(
    //               labelText: 'Rechercher un produit',
    //               suffixIcon: IconButton(
    //                 icon: Icon(Icons.clear),
    //                 onPressed: () {
    //                   _rechercheController.clear();
    //                   provider.rechercherProduits('');
    //                 },
    //               ),
    //             ),
    //             onChanged: (value) {
    //               provider.rechercherProduits(value);
    //             },
    //           ),
    //         ),
    //         if (provider.produitsTrouves.isNotEmpty)
    //           Expanded(
    //             child: Padding(
    //               padding: const EdgeInsets.symmetric(horizontal: 28),
    //               child: ListView.builder(
    //                 itemCount: provider.produitsTrouves.length,
    //                 itemBuilder: (context, index) {
    //                   final produit = provider.produitsTrouves[index];
    //                   return ListTile(
    //                     title: Text(produit.nom),
    //                     subtitle: Text('Prix: ${produit.prixVente}'),
    //                     trailing: IconButton(
    //                       icon: Icon(Icons.add),
    //                       onPressed: () {
    //                         provider.ajouterProduitALaFacture(
    //                             produit, 1, produit.prixVente);
    //                         _rechercheController.clear();
    //                         provider.rechercherProduits('');
    //                       },
    //                     ),
    //                   );
    //                 },
    //               ),
    //             ),
    //           ),
    //         LayoutBuilder(builder: (context, constraints) {
    //           if (constraints.maxWidth < 600) {
    //             return Column(
    //               children: [
    //                 ClientInfos(),
    //                 TTC(
    //                   totalAmount: provider.calculerTotalHT(),
    //                   localImpayer:
    //                       double.tryParse(_impayerController.text) ?? 0.0,
    //                 ),
    //                 TotalDetail(
    //                   totalAmount: provider.calculerTotalHT(),
    //                   localImpayer:
    //                       double.tryParse(_impayerController.text) ?? 0.0,
    //                 ),
    //               ],
    //             );
    //           } else {
    //             return Row(
    //               children: [
    //                 Expanded(flex: 4, child: ClientInfos()),
    //                 Expanded(
    //                   flex: 3,
    //                   child: TTC(
    //                     totalAmount: provider.calculerTotalHT(),
    //                     localImpayer:
    //                         double.tryParse(_impayerController.text) ?? 0.0,
    //                   ),
    //                 ),
    //                 Expanded(
    //                   flex: 2,
    //                   child: TotalDetail(
    //                     totalAmount: provider.calculerTotalHT(),
    //                     localImpayer:
    //                         double.tryParse(_impayerController.text) ?? 0.0,
    //                   ),
    //                 ),
    //               ],
    //             );
    //           }
    //         }),
    //         LayoutBuilder(builder: (context, constraints) {
    //           if (constraints.maxWidth < 600) {
    //             return Container(
    //               height: 60,
    //               child: Column(
    //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
    //                 children: [
    //                   Spacer(
    //                     flex: 1,
    //                   ),
    //                   Expanded(
    //                     flex: 3,
    //                     child: provider.lignesFacture.isEmpty
    //                         ? SizedBox.shrink()
    //                         : EditableField(
    //                             initialValue: provider.impayer,
    //                             impayerController: _impayerController,
    //                           ),
    //                   ),
    //                   Spacer(
    //                     flex: 2,
    //                   ),
    //                   ElevatedButton.icon(
    //                     onPressed: provider.lignesFacture.isEmpty
    //                         ? null
    //                         : () {
    //                             provider
    //                                 .creerNouvelleFacture(); // Crée une nouvelle facture
    //                             _impayerController.clear();
    //                             _rechercheController.clear();
    //                             context
    //                                 .read<EditableFieldProvider>()
    //                                 .AlwaystoggleEditable();
    //                           },
    //                     style: ElevatedButton.styleFrom(
    //                       foregroundColor:
    //                           Theme.of(context).colorScheme.onPrimary,
    //                       backgroundColor:
    //                           Theme.of(context).colorScheme.primary,
    //                       shape: RoundedRectangleBorder(
    //                         borderRadius: BorderRadius.circular(15.0),
    //                       ),
    //                     ),
    //                     label: Text('Nouvelle Facture'),
    //                     icon: Padding(
    //                       padding: const EdgeInsets.symmetric(vertical: 18),
    //                       child: Icon(Icons.add),
    //                     ),
    //                   ),
    //                   Spacer(
    //                     flex: 2,
    //                   ),
    //                   ElevatedButton.icon(
    //                     onPressed: provider.lignesFacture.isEmpty
    //                         ? null
    //                         : () {
    //                             provider.sauvegarderFacture();
    //                             _impayerController.clear();
    //                             context
    //                                 .read<EditableFieldProvider>()
    //                                 .AlwaystoggleEditable();
    //                           },
    //                     style: ElevatedButton.styleFrom(
    //                       shape: RoundedRectangleBorder(
    //                         borderRadius: BorderRadius.circular(15.0),
    //                       ),
    //                     ),
    //                     label: Text('Sauvegarder la facture'),
    //                     icon: Padding(
    //                       padding: const EdgeInsets.symmetric(vertical: 18),
    //                       child: Icon(Icons.save),
    //                     ),
    //                   ),
    //                   Spacer(
    //                     flex: 1,
    //                   ),
    //                 ],
    //               ),
    //             );
    //           } else {
    //             return Container(
    //               height: 60,
    //               child: Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
    //                 children: [
    //                   Spacer(
    //                     flex: 1,
    //                   ),
    //                   Expanded(
    //                     flex: 3,
    //                     child: provider.lignesFacture.isEmpty
    //                         ? SizedBox.shrink()
    //                         : EditableField(
    //                             initialValue: provider.impayer,
    //                             impayerController: _impayerController,
    //                           ),
    //                   ),
    //                   Spacer(
    //                     flex: 2,
    //                   ),
    //                   ElevatedButton.icon(
    //                     onPressed: provider.lignesFacture.isEmpty
    //                         ? null
    //                         : () {
    //                             provider
    //                                 .creerNouvelleFacture(); // Crée une nouvelle facture
    //                             _impayerController.clear();
    //                             _rechercheController.clear();
    //                             context
    //                                 .read<EditableFieldProvider>()
    //                                 .AlwaystoggleEditable();
    //                           },
    //                     style: ElevatedButton.styleFrom(
    //                       foregroundColor:
    //                           Theme.of(context).colorScheme.onPrimary,
    //                       backgroundColor:
    //                           Theme.of(context).colorScheme.primary,
    //                       shape: RoundedRectangleBorder(
    //                         borderRadius: BorderRadius.circular(15.0),
    //                       ),
    //                     ),
    //                     label: Text('Nouvelle Facture'),
    //                     icon: Padding(
    //                       padding: const EdgeInsets.symmetric(vertical: 18),
    //                       child: Icon(Icons.add),
    //                     ),
    //                   ),
    //                   Spacer(
    //                     flex: 2,
    //                   ),
    //                   ElevatedButton.icon(
    //                     onPressed: provider.lignesFacture.isEmpty
    //                         ? null
    //                         : () {
    //                             provider.sauvegarderFacture();
    //                             _impayerController.clear();
    //                             context
    //                                 .read<EditableFieldProvider>()
    //                                 .AlwaystoggleEditable();
    //                           },
    //                     style: ElevatedButton.styleFrom(
    //                       shape: RoundedRectangleBorder(
    //                         borderRadius: BorderRadius.circular(15.0),
    //                       ),
    //                     ),
    //                     label: Text('Sauvegarder la facture'),
    //                     icon: Padding(
    //                       padding: const EdgeInsets.symmetric(vertical: 18),
    //                       child: Icon(Icons.save),
    //                     ),
    //                   ),
    //                   Spacer(
    //                     flex: 1,
    //                   ),
    //                 ],
    //               ),
    //             );
    //           }
    //         }),
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
    //                     DataCell(Text(
    //                         ligne.produit.target?.nom ?? 'Produit inconnu')),
    //                     DataCell(
    //                       // state.isEditedQty
    //                       //     ? TextFormField(
    //                       //         initialValue: ligne.quantite.toStringAsFixed(2),
    //                       //         keyboardType: TextInputType.number,
    //                       //         onChanged: (value) {
    //                       //           final nouvelleQuantite =
    //                       //               double.tryParse(value) ?? 0;
    //                       //           provider.modifierLigne(
    //                       //             index,
    //                       //             nouvelleQuantite,
    //                       //             ligne.prixUnitaire,
    //                       //           );
    //                       //         },
    //                       //         onTapOutside: (event) {
    //                       //           provider.toggleEditQty(index);
    //                       //         },
    //                       //       )
    //                       //     :
    //                       Text(ligne.quantite.toStringAsFixed(2)),
    //                       // onTap: () {
    //                       //   provider.toggleEditQty(index);
    //                       // },
    //                       // onTapDown: (TapDownDetails) {
    //                       //   provider.toggleEditQty(index);
    //                       // },
    //                       // onTapCancel: () {
    //                       //   provider.toggleEditQty(index);
    //                       // },
    //                     ),
    //                     DataCell(
    //                       // state.isEditedPu
    //                       //     ? TextFormField(
    //                       //         initialValue:
    //                       //             ligne.prixUnitaire.toStringAsFixed(2),
    //                       //         keyboardType: TextInputType.number,
    //                       //         onChanged: (value) {
    //                       //           final nouveauPrix =
    //                       //               double.tryParse(value) ?? 0;
    //                       //           provider.modifierLigne(
    //                       //             index,
    //                       //             ligne.quantite,
    //                       //             nouveauPrix,
    //                       //           );
    //                       //         },
    //                       //         onTapOutside: (event) {
    //                       //           provider.toggleEditPu(index);
    //                       //         },
    //                       //       )
    //                       //     :
    //                       Text(ligne.prixUnitaire.toStringAsFixed(2)),
    //                       //     onTap: () {
    //                       //   provider.toggleEditPu(index);
    //                       // }, showEditIcon: true
    //                     ),
    //                     DataCell(Text((ligne.quantite * ligne.prixUnitaire)
    //                         .toStringAsFixed(2))),
    //                     DataCell(
    //                       Row(
    //                         children: [
    //                           IconButton(
    //                             icon: Icon(Icons.delete),
    //                             onPressed: () {
    //                               provider.supprimerLigne(index);
    //                             },
    //                           ),
    //                           IconButton(
    //                             icon: Icon(Icons.edit),
    //                             onPressed: () {
    //                               _showEditDialog(
    //                                   context, ligne, provider, index);
    //                             },
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                   ],
    //                 );
    //               }).toList(),
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

  void _showEditDialog(BuildContext context, LigneDocument ligne,
      FacturationProvider provider, int index) {
    final _formKey =
        GlobalKey<FormState>(); // Clé pour gérer l'état du formulaire
    final TextEditingController prixVenteController = TextEditingController(
      text: ligne.prixUnitaire.toStringAsFixed(2),
    );
    final TextEditingController quantiteController = TextEditingController(
      text: ligne.quantite.toStringAsFixed(2),
    );

    // Récupérer le prix d'achat et la quantité restante
    final prixAchat =
        ligne.produit.target?.approvisionnements.isNotEmpty == true
            ? ligne.produit.target!.approvisionnements
                    .map((a) => a.prixAchat ?? 0)
                    .reduce((a, b) => a + b) /
                ligne.produit.target!.approvisionnements.length
            : 0.0;
    final quantiteRestante = ligne.produit.target?.calculerStockTotal() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier la Quantité ou Prix'),
          content: Form(
            key: _formKey, // Associer la clé au formulaire
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Prix Minimal: ${prixAchat.toStringAsFixed(2)} DZD',
                  style: TextStyle(fontSize: 15),
                ),
                Text(
                  'Quantité Restante: ${quantiteRestante.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: prixVenteController,
                  decoration: InputDecoration(labelText: 'Prix de vente'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final prixVente = double.tryParse(value ?? '');
                    if (prixVente == null || prixVente < prixAchat) {
                      return 'Le prix de vente doit être ≥ ${prixAchat.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: quantiteController,
                  decoration: InputDecoration(labelText: 'Quantité'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final quantite = double.tryParse(value ?? '');
                    if (quantite == null ||
                        quantite <= 0 ||
                        quantite > quantiteRestante) {
                      return 'La quantité doit être > 0 et ≤ ${quantiteRestante.toStringAsFixed(2)}';
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
                Navigator.pop(context); // Fermer la boîte de dialogue
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Valider le formulaire
                if (_formKey.currentState?.validate() ?? false) {
                  // Récupérer les valeurs saisies
                  final prixVente = double.tryParse(prixVenteController.text);
                  final quantite = double.tryParse(quantiteController.text);

                  if (prixVente == null || quantite == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Veuillez saisir des valeurs valides')),
                    );
                    return;
                  }

                  // Mettre à jour la ligne avec les nouvelles valeurs
                  provider.modifierLigne(index, quantite, prixVente);
                  Navigator.pop(context); // Fermer la boîte de dialogue
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

class FactureList extends StatelessWidget {
  final TabController? tabController;

  const FactureList({this.tabController});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);
    final tabController = DefaultTabController.maybeOf(context);
    return Container(
        // color: Colors.yellow,
        child: ListView.builder(
      itemCount: provider.factures.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final facture = provider.factures.reversed.toList()[index];
        bool estEnEdition = provider.estEnEdition(facture);
        final isEditing = provider.isEditing;
        final hasChanges = provider.hasChanges;

        return Column(
          children: [
            Card(
              color: estEnEdition ? Colors.green.shade100 : null,
              child: ListTile(
                onLongPress: () => provider.supprimerFacture(facture),
                leading: CircleAvatar(
                    backgroundColor:
                        estEnEdition ? Colors.white70 : Colors.green,
                    child: estEnEdition
                        ? (isEditing && hasChanges
                            ? Icon(FontAwesomeIcons.penToSquare,
                                color: Colors.orange)
                            : Icon(FontAwesomeIcons.check, color: Colors.green))
                        : Icon(FontAwesomeIcons.check, color: Colors.white70)),
                title: Text(facture.qrReference),
                subtitle: Text.rich(
                  overflow: TextOverflow.ellipsis,
                  TextSpan(
                    text: 'Client: ',
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: facture.client.target?.nom ?? 'Inconnu',
                        style: facture.client.target != null
                            ? TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w400,
                              )
                            : TextStyle(
                                color: Colors.black,
                              ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  provider.selectionnerFacture(facture);
                  provider.commencerEdition(facture);
                  context.read<EditableFieldProvider>().AlwaystoggleEditable();
                  context.read<FacturationProvider>().AlwaystoggleEdit(index);
                  context.read<FacturationProvider>().AlwaystoggleEdit(index);
                  // Change to the detail tab
                  tabController?.animateTo(0);
                },
                trailing: facture.impayer! > 0.0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${facture.montantTotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            '${facture.impayer!.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.red),
                          )
                        ],
                      )
                    : Text(
                        '${facture.montantTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20),
                      ),
              ),
            ),
            Text(
              DateFormat('EEE dd MMM yyyy  -  HH:mm', 'fr')
                  .format(DateTime.parse(facture.date.toString()))
                  .capitalize(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        );
      },
    ));
  }
}

class ClientSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);
    final clients = provider.getClients();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner un client'),
      ),
      body: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return ListTile(
            title: Text(client.nom),
            subtitle: Text(client.phone),
            onTap: () {
              provider.selectClient(client);
              Navigator.pop(context);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Naviguer vers la page de création de client
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CreateClientPage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class CreateClientPage extends StatefulWidget {
  @override
  _CreateClientPageState createState() => _CreateClientPageState();
}

class _CreateClientPageState extends State<CreateClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _qrController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un nouveau client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
                decoration: InputDecoration(labelText: 'Téléphone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un téléphone';
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
              TextFormField(
                controller: _qrController,
                decoration: InputDecoration(labelText: 'QR Code'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await provider.createClient(
                        _nomController.text,
                        _phoneController.text,
                        _adresseController.text,
                        _qrController.text,
                        DateTime.now());
                    Navigator.pop(context);
                  }
                },
                child: Text('Créer le client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientInfos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);
    final client =
        //    provider.factureEnCours?.client.target ??
        provider.selectedClient;

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () async {
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
                        provider.resetClient();
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
                      children: [
                        Text(
                          'Client non identifié...',
                          style: TextStyle(fontSize: 18),
                        ),
                        Lottie.asset(
                          'assets/lotties/1 (8).json',
                          // Chemin vers ton fichier Lottie
                          width: 200, // Ajuste la taille de l'erreur à 30%
                          height: 100,
                        ),
                      ],
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
    required double localImpayer,
  }) : _localImpayer = localImpayer;

  final double totalAmount;

  final double _localImpayer;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                ).format(totalAmount - _localImpayer),
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
    );
  }
}

class TotalDetail extends StatelessWidget {
  const TotalDetail({
    super.key,
    required this.totalAmount,
    required double localImpayer,
    required this.facture,
  }) : _localImpayer = localImpayer;

  final double totalAmount;

  final double _localImpayer;
  final double fontSize = 15;
  final Document? facture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 146,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                facture != null ? 'Invoice N ${facture?.id}' : '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Total:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${totalAmount.toStringAsFixed(2)} DZD',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'TVA (19%):',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${(totalAmount * 0.19).toStringAsFixed(2)} DZD',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total TTC:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${(totalAmount * 1.19).toStringAsFixed(2)} DZD',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _localImpayer > 0.9
                  ? Card(
                      color: Colors.yellow,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Impayés:',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: fontSize * 1.3,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_localImpayer.toStringAsFixed(2)} DZD',
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: fontSize * 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class EditableField extends StatelessWidget {
  double initialValue;
  final TextEditingController impayerController;

  EditableField({
    required this.initialValue,
    required this.impayerController,
    Key? key,
  }) : super(key: key) {
    // Initialiser le contrôleur avec la valeur initiale
    impayerController.text = initialValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = context.watch<EditableFieldProvider>().isEditable;
    final provider = context.read<EditableFieldProvider>();
    final providerF = Provider.of<FacturationProvider>(context, listen: false);

    return Container(
      padding: EdgeInsets.all(8.0), // Espacement à l'intérieur du cadre
      decoration: BoxDecoration(
        //      color: Colors.grey, // Couleur de fond
        borderRadius: BorderRadius.circular(8.0), // Bords arrondis
        border: Border.all(
          color: Colors.grey, // Couleur de la bordure
          width: 1.0, // Épaisseur de la bordure
        ),
      ),
      child: Row(
        children: [
          Text('Impayé :'),
          Expanded(
            child: isEditable
                ? TextFormField(
                    // controller: impayerController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      //  labelText: 'Impayé',
                      prefixIcon: Transform.scale(
                        scale: 0.7,
                        // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
                        child: IconButton(
                          icon: Icon(isEditable ? Icons.check : Icons.edit),
                          color: isEditable ? Colors.green : Colors.blue,
                          onPressed: () {
                            if (isEditable) {
                              // Appliquer les modifications et mettre à jour la valeur dans le provider
                              final nouvelleValeur =
                                  double.tryParse(impayerController.text) ??
                                      0.0;
                              providerF.modifierImpayer(nouvelleValeur);
                            }
                            provider.toggleEditable();
                          },
                        ),
                      ),
                      suffixIcon: Transform.scale(
                        scale: 0.7,
                        // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
                        child: IconButton(
                          icon: Icon(Icons.close),
                          color: Colors.red,
                          onPressed: () {
                            impayerController
                                .clear(); // Vider le texte du champ
                            final nouvelleValeur = 0.0;

                            // Mettre à jour l'état du provider avec la nouvelle valeur
                            providerF.modifierImpayer(nouvelleValeur);
                          },
                        ),
                      ),
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8.0),
                      //   borderSide: BorderSide.none,
                      // ),
                      //filled: true,
                      //contentPadding: EdgeInsets.all(15),
                    ),
                    // initialValue: providerF.impayer.toStringAsFixed(2),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final nouvelleImpayer = double.tryParse(value) ?? 0;
                      providerF.modifierImpayer(nouvelleImpayer);
                    },
                  )
                : TextField(
                    readOnly: true,
                    controller: impayerController,
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      suffixIcon: Transform.scale(
                        scale: 0.7,
                        // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
                        child: IconButton(
                          icon: Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: () {
                            final nouvelleValeur =
                                double.tryParse(impayerController.text) ?? 0.0;
                            // providerF.modifierImpayer(nouvelleValeur);

                            provider.toggleEditable();
                          },
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.all(15),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    // Permet les nombres décimaux
                    onChanged: (value) {
                      // Valider et formater la valeur saisie
                      final impayer = double.tryParse(value) ?? 0.0;

                      providerF.setImpayer(
                          impayer); // Mettre à jour l'impayer dans le provider
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
