import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../Entity.dart';
import '../MyProviders.dart';
import 'FactureListScreen.dart';

class ClientListScreen extends StatefulWidget {
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  NativeAd? _nativeAd;

  bool _nativeAdIsLoaded = false;

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, child) {
        final clients = clientProvider.clients;

        return Scaffold(
          appBar: AppBar(
            title: Consumer<ClientProvider>(
              builder: (context, clientProvider, child) {
                return Text('${clientProvider.clientCount} Clients');
              },
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await clientProvider.deleteAllClients();
                },
                icon: Icon(Icons.clear_all_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Couleur de fond grise
                  foregroundColor: Colors.grey[300], // Couleur du texte grise
                  disabledBackgroundColor: Colors.grey[
                      300], // Assure que la couleur reste grise même désactivé
                  disabledForegroundColor: Colors.grey[
                      600], // Assure que la couleur du texte reste grise même désactivé
                ),
              ),
              SizedBox(
                width: 50,
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              //final client = clients[index];
              if (index != 0 &&
                  index % 5 == 0 &&
                  _nativeAd != null &&
                  _nativeAdIsLoaded) {
                return Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      minHeight: 350,
                      maxHeight: 400,
                      maxWidth: 450,
                    ),
                    child: AdWidget(ad: _nativeAd!),
                  ),
                );
              }

              final client = clients[clients.length - 1 - index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(client.factures.length.toString()),
                    ),
                  ),
                  onLongPress: () {
                    _deleteClient(context, client);
                  },
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => ClientDetailsPage(
                        client: client,
                      ),
                    ));
                  },
                  title: Text(client.id.toString() +
                      ' ' +
                      client.nom +
                      ' ' +
                      client.phone.toString()),
                  subtitle: Text(client.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () =>
                            _showEditDialog(context, client, clientProvider),
                      ),
                      // IconButton(
                      //   icon: Icon(Icons.delete),
                      //   onPressed: () => clientProvider.deleteClient(client),
                      // ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled:
                    true, // Permet de redimensionner en fonction de la hauteur du contenu
                builder: (context) => AddClientForm(),
              );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, Client client,
      ClientProvider clientProvider) async {
    final TextEditingController nameController =
        TextEditingController(text: client.nom);
    final TextEditingController phoneController =
        TextEditingController(text: client.phone);
    final TextEditingController addressController =
        TextEditingController(text: client.adresse);
    final TextEditingController descriptionController =
        TextEditingController(text: client.description);

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier le client'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Téléphone'),
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Adresse'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                client.nom = nameController.text;
                client.phone = phoneController.text;
                client.adresse = addressController.text;
                client.description = descriptionController.text;

                await clientProvider.updateClient(client);
                Navigator.of(context).pop();
              },
              child: Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }
}

class ClientDetailsPage extends StatelessWidget {
  final Client client;

  ClientDetailsPage({required this.client});

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);
    List<Document> factures = clientProvider.getFacturesForClient(client);
    final cartProvider = Provider.of<CartProvider>(context);
    final commercProvider = Provider.of<CommerceProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nom: ${client.nom}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Téléphone: ${client.phone}'),
            Text('Adresse: ${client.adresse}'),
            Text('Description: ${client.description}'),
            // Text('Impayer: ${client.impayer!.toStringAsFixed(2)} DZD'),
            SizedBox(height: 20),
            Text(
              'Factures:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: factures.length,
                itemBuilder: (context, index) {
                  final facture = factures[index];
                  final totalAmount = facture.lignesDocument.fold(
                      0.0,
                      (sum, ligne) =>
                          sum + (ligne.prixUnitaire * ligne.quantite));

                  return ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FactureDetailPage(
                            facture: facture,
                            cartProvider: cartProvider,
                            commerceProvider: commercProvider,
                          ),
                        ),
                      );
                    },
                    title: Text('Facture ID: ${facture.id}'),
                    subtitle: Text(
                        'Date: ${facture.date.toLocal().toString().split(' ')[0]}\nMontant: ${totalAmount.toStringAsFixed(2)} DZD'),
                    trailing: Icon(Icons.receipt),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddClientForm extends StatefulWidget {
  @override
  _AddClientFormState createState() => _AddClientFormState();
}

class _AddClientFormState extends State<AddClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _impayerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            'Ajouter un Nouveau Client',
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
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une Description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _impayerController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Impayer'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une Impayer';
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
                    final client = Client(
                      qr: '',
                      nom: _nomController.text,
                      phone: _phoneController.text,
                      adresse: _adresseController.text,
                      derniereModification: DateTime.now(),
                    )..crud.target = Crud(
                        createdBy: 1,
                        updatedBy: 1,
                        deletedBy: 1,
                        dateCreation: DateTime.now(),
                        derniereModification: DateTime.now(),
                        dateDeleting: null,
                      );
                    context.read<ClientProvider>().addClient(client);
                    Navigator.of(context).pop(client);
                  }
                },
                child: Text('Ajouter'),
              ),
            ],
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _phoneController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    _impayerController.dispose();
    super.dispose();
  }
}

void _editClient(BuildContext context, Client client) {
  final _nomController = TextEditingController(text: client.nom);
  final _phoneController = TextEditingController(text: client.phone);
  final _adresseController = TextEditingController(text: client.adresse);
  final _descriptionController =
      TextEditingController(text: client.description);
  // final _impayerController =
  //     TextEditingController(text: client.impayer.toString());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Modifier un Client',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Form(
            child: Column(
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: 'Nom'),
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _adresseController,
                  decoration: InputDecoration(labelText: 'Adresse'),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                // TextFormField(
                //   controller: _impayerController,
                //   decoration: InputDecoration(labelText: 'Impayer'),
                // ),
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
                  if (_nomController.text.isNotEmpty &&
                      _phoneController.text.isNotEmpty &&
                      _adresseController.text.isNotEmpty) {
                    final updatedClient = Client(
                      qr: '',
                      nom: _nomController.text,
                      phone: _phoneController.text,
                      adresse: _adresseController.text,
                      description: _descriptionController.text,
                      derniereModification: DateTime.now(),
                    )..crud.target = Crud(
                        createdBy: 1,
                        updatedBy: 1,
                        deletedBy: 1,
                        dateCreation: DateTime.now(),
                        derniereModification: DateTime.now(),
                        dateDeleting: null,
                      );
                    context.read<ClientProvider>().updateClient(updatedClient);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Modifier'),
              ),
            ],
          ),
          SizedBox(height: 50),
        ],
      ),
    ),
  );
}

void _deleteClient(BuildContext context, Client client) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'Confirmer la suppression',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            FittedBox(
                child: Text('Êtes-vous sûr de vouloir supprimer ce Client ?')),
            SizedBox(
              height: 15,
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  label: Text('Annuler'),
                  icon: Icon(Icons.cancel),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                      context.read<ClientProvider>().deleteClient(client);
                      Navigator.of(context).pop();
                    },
                    label: Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(Icons.delete),
                    style: ButtonStyle(
                      iconColor: WidgetStateProperty.all<Color>(Colors.white),
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.red),
                    ))
              ],
            ),
            SizedBox(
              height: 60,
            )
          ],
        ),
      );
    },
  );
}
