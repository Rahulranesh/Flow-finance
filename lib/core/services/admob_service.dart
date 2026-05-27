import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('AdMob init error: $e');
    }
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-1969259760721536/2606891773';
    if (Platform.isIOS) return 'ca-app-pub-1969259760721536/XXXXXXXXXX';
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-1969259760721536/7476075073';
    if (Platform.isIOS) return 'ca-app-pub-1969259760721536/XXXXXXXXXX';
    return '';
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-1969259760721536/XXXXXXXXXX';
    if (Platform.isIOS) return 'ca-app-pub-1969259760721536/XXXXXXXXXX';
    return '';
  }

  BannerAd createBannerAd({
    required AdSize adSize,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    required void Function(Ad) onAdLoaded,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  Future<InterstitialAd?> loadInterstitialAd() async {
    InterstitialAd? ad;
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (a) => ad = a,
        onAdFailedToLoad: (e) => debugPrint('Interstitial failed: $e'),
      ),
    );
    return ad;
  }

  Future<RewardedAd?> loadRewardedAd() async {
    RewardedAd? ad;
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (a) => ad = a,
        onAdFailedToLoad: (e) => debugPrint('Rewarded failed: $e'),
      ),
    );
    return ad;
  }

  void dispose() {
    _isInitialized = false;
  }
}
