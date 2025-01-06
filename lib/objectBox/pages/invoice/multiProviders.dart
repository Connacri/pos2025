import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../MyProviders.dart';
import '../../classeObjectBox.dart';
import '../facturation/FacturesListPage.dart';
import 'UIforAddingtoCart.dart';

class start extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          children: [
            Expanded(
              child: FacturesListPage(
                onFactureSelected: (facture) {
                  // Handle facture selection
                },
              ),
            ),
            Expanded(
              child: HomeScreen(),
            ),
          ],
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commerce App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddToCartPage()),
                );
              },
              child: Text('Add to Cart'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FacturesListPage(
                            onFactureSelected: (facture) {
                              // Handle facture selection
                            },
                          )),
                );
              },
              child: Text('View Invoices'),
            ),
          ],
        ),
      ),
    );
  }
}
