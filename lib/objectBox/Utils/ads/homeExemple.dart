import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../MyProviders.dart';

class MyHomePageAds extends StatefulWidget {
  @override
  _MyHomePageAdsState createState() => _MyHomePageAdsState();
}

class _MyHomePageAdsState extends State<MyHomePageAds> {
  bool _isFirstOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstOpen) {
        _showInterstitialAd();
        setState(() {
          _isFirstOpen = false;
        });
      }
    });
  }

  void _showInterstitialAd() {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    if (adProvider.isInterstitialAdReady) {
      adProvider.showInterstitialAd();
    }
  }

/////////////////////////////////////////////////////////////////////////////
  int _clickCount = 0;

  void _onButtonClick() {
    setState(() {
      _clickCount++;
    });

    if (_clickCount % 3 == 0) {
      _showInterstitialAdClick();
    }
  }

  void _showInterstitialAdClick() {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    if (adProvider.isInterstitialAdReady) {
      adProvider.showInterstitialAd();
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  final List<String> items = List.generate(20, (index) => 'Item $index');

  Widget _buildAdWidget(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);
    if (adProvider.isInterstitialAdReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adProvider.showInterstitialAd();
      });
    }
    return SizedBox.shrink();
  }

  /////////////////////////////////////////////////////////////////////////////
  void _showForcedRewardedAd(BuildContext context) async {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    if (adProvider.isRewardedAdReady) {
      bool rewardEarned = await adProvider.showRewardedAd();
      if (rewardEarned) {
        // L'utilisateur a regardé la vidéo jusqu'à la fin
        _navigateToNextScreen(context);
      } else {
        // L'utilisateur n'a pas terminé la vidéo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please watch the entire ad to continue')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad not ready. Please try again later.')),
      );
    }
  }

  void _navigateToNextScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => NextScreen(),
    ));
  }

  ///////////////////////////////////////////////////////////////////////////////
  int _coins = 0;

  void _showCoinRewardedAd(BuildContext context) async {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    if (adProvider.isRewardedAdReady) {
      bool rewardEarned = await adProvider.showRewardedAd();
      if (rewardEarned) {
        setState(() {
          _coins += 2; // Ajouter 10 pièces pour avoir regardé la vidéo
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Congratulations! You earned 10 coins!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Watch the entire ad to earn coins')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad not ready. Please try again later.')),
      );
    }
  }
  ///////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('My App')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                  child: FittedBox(
                      child: Text(
                'Welcome to My App',
                style: TextStyle(fontSize: 80),
              ))),
              Text('Click count: $_clickCount'),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _onButtonClick,
                child: Text('Click me'),
              ),
              SizedBox(
                height: 15,
              ),
              Expanded(
                child: ListView.builder(
                  // shrinkWrap: true,
                  //   physics: NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    if (index > 0 && index % 5 == 0) {
                      return Column(
                        children: [
                          ListTile(title: Text(items[index])),
                          _buildAdWidget(context),
                        ],
                      );
                    }
                    return ListTile(title: Text(items[index]));
                  },
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showForcedRewardedAd(context),
                  child: Text('Watch Ad to Continue'),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Center(
                child: Container(
                  padding:
                      EdgeInsets.all(10.0), // Espacement à l'intérieur du cadre
                  decoration: BoxDecoration(
                    //      color: Colors.grey, // Couleur de fond
                    borderRadius: BorderRadius.circular(8.0), // Bords arrondis
                    border: Border.all(
                      color: Colors.grey, // Couleur de la bordure
                      width: 1.0, // Épaisseur de la bordure
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Your Coins: $_coins',
                          style: TextStyle(fontSize: 24)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _showCoinRewardedAd(context),
                        child: Text('Watch Ad for Coins'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NextScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Next Screen')),
      body: Center(child: Text('You have successfully watched the ad!')),
    );
  }
}
