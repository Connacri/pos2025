import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import '../../Entity.dart';
import '../ClientListScreen.dart';
import 'providers.dart';

class FacturationPageUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facturation'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: FactureDetail(),
          ),
          Expanded(
            flex: 1,
            child: FactureList(),
          ),
        ],
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

  // // Variable pour stocker le texte saisi
  // double _displayImpayer = 0.0;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   // Écouter les changements dans le champ de texte
  //   _impayerController.addListener(_updateDisplayText);
  // }

  // // Méthode pour mettre à jour le texte affiché
  // void _updateDisplayText() {
  //   setState(() {
  //     _displayImpayer = double.tryParse(_impayerController.text) ?? 0;
  //   });
  // }

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
    return Column(
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
        Row(
          children: [
            Expanded(flex: 4, child: ClientInfos()),
            Expanded(
              flex: 3,
              child: TTC(
                  totalAmount: provider.calculerTotalHT(), localImpayer: 0.0),
            ),
            Expanded(
              flex: 2,
              child: TotalDetail(
                totalAmount: provider.calculerTotalHT(),
                localImpayer: double.tryParse(_impayerController.text) ?? 0.0,
              ),
            ),
          ],
        ),
        // Text(
        //   _displayImpayer.toStringAsFixed(2),
        //   style: TextStyle(
        //     fontSize: 20,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Spacer(),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _impayerController,
                  decoration: InputDecoration(
                    labelText: 'Impayé',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  // Permet les nombres décimaux
                  onChanged: (value) {
                    // Valider et formater la valeur saisie
                    final impayer = double.tryParse(value) ?? 0.0;
                    provider.setImpayer(
                        impayer); // Mettre à jour l'impayer dans le provider
                  },
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: provider.lignesFacture.isEmpty
                  ? null
                  : () {
                      provider
                          .creerNouvelleFacture(); // Crée une nouvelle facture
                      _impayerController.clear();
                      _rechercheController.clear();
                    },
              child: Text('Nouvelle Facture'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: provider.lignesFacture.isEmpty
                  ? null
                  : () {
                      // if (provider.factureEnCours == null) {
                      //   provider
                      //       .creerNouvelleFacture(); // Crée une nouvelle facture si aucune n'est sélectionnée
                      // }
                      provider.sauvegarderFacture();
                      _impayerController.clear();
                    },
              child: Text('Sauvegarder la facture'),
            ),
            Spacer(),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Produit')),
                DataColumn(label: Text('Quantité')),
                DataColumn(label: Text('Prix Unitaire')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Actions')),
              ],
              rows: provider.lignesFacture.map((ligne) {
                final index = provider.lignesFacture.indexOf(ligne);
                final state = provider.getLigneEditionState(index);

                return DataRow(
                  cells: [
                    DataCell(
                        Text(ligne.produit.target?.nom ?? 'Produit inconnu')),
                    DataCell(
                      state.isEditedQty
                          ? TextFormField(
                              initialValue: ligne.quantite.toStringAsFixed(2),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final nouvelleQuantite =
                                    double.tryParse(value) ?? 0;
                                provider.modifierLigne(
                                  index,
                                  nouvelleQuantite,
                                  ligne.prixUnitaire,
                                );
                              },
                              onTapOutside: (event) {
                                provider.toggleEditQty(index);
                              },
                            )
                          : Text(ligne.quantite.toStringAsFixed(2)),
                      onTap: () {
                        provider.toggleEditQty(index);
                      },
                    ),
                    DataCell(
                      state.isEditedPu
                          ? TextFormField(
                              initialValue:
                                  ligne.prixUnitaire.toStringAsFixed(2),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final nouveauPrix = double.tryParse(value) ?? 0;
                                provider.modifierLigne(
                                  index,
                                  ligne.quantite,
                                  nouveauPrix,
                                );
                              },
                              onTapOutside: (event) {
                                provider.toggleEditPu(index);
                              },
                            )
                          : Text(ligne.prixUnitaire.toStringAsFixed(2)),
                      onTap: () {
                        provider.toggleEditPu(index);
                      },
                    ),
                    DataCell(Text((ligne.quantite * ligne.prixUnitaire)
                        .toStringAsFixed(2))),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          provider.supprimerLigne(index);
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class FactureList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);

    return ListView.builder(
      itemCount: provider.factures.length,
      itemBuilder: (context, index) {
        final facture = provider.factures.reversed.toList()[index];
        final estEnEdition = provider.estEnEdition(facture);

        return Column(
          children: [
            Card(
              color: estEnEdition ? Colors.yellow.shade300 : null,
              child: ListTile(
                onLongPress: () => provider.supprimerFacture(facture),
                leading: CircleAvatar(
                  child: estEnEdition
                      ? Icon(Icons.edit, color: Colors.orange)
                      : Icon(Icons.check,
                          color: Colors.green), // Icône de sauvegarde réussie
                ),
                title: Text(facture.qrReference),
                subtitle: Text.rich(
                  TextSpan(
                    text: 'Client: ',
                    style: TextStyle(color: Colors.black), // Style par défaut
                    children: [
                      TextSpan(
                        text: facture.client.target?.nom ?? 'Unknown Client',
                        style: facture.client.target != null
                            ? TextStyle(
                                color: Colors.blue, // Texte en bleu
                                fontWeight: FontWeight.w400, // Texte en gras
                              )
                            : TextStyle(
                                color: Colors
                                    .black), // Style par défaut si client est null
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  provider.selectionnerFacture(facture);
                  provider.commencerEdition(facture); // Commencer l'édition
                },
                trailing: Column(
                  children: [
                    Text(
                      '${facture.montantTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text('${facture.impayer!.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            Text(
              DateFormat('EEE dd MMM yyyy HH:mm', 'fr')
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
    );
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
        provider.factureEnCours?.client.target ?? provider.selectedClient;

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
                ).format(totalAmount + (totalAmount * 0.19) - _localImpayer),
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
  }) : _localImpayer = localImpayer;

  final double totalAmount;

  final double _localImpayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 146,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(2)} DZD',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TVA (19%): ',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Text(
                '${(totalAmount * 0.19).toStringAsFixed(2)} DZD',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total TTC:  ',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Text(
                '${(totalAmount * 1.19).toStringAsFixed(2)} DZD',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ],
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
    );
  }
}
