import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob service for managing ads
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;

  /// Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing AdMob: $e');
    }
  }

  /// Get banner ad unit ID
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Test ID for development
      return 'ca-app-pub-3940256099942544/6300978111';
      // Production: return 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ID';
    } else if (Platform.isIOS) {
      // Test ID for development
      return 'ca-app-pub-3940256099942544/2934735716';
      // Production: return 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ID';
    }
    return '';
  }

  /// Get interstitial ad unit ID
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  /// Get rewarded ad unit ID
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  /// Create banner ad
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
        onAdOpened: (ad) => print('Ad opened'),
        onAdClosed: (ad) => print('Ad closed'),
      ),
    );
  }

  /// Load interstitial ad
  Future<InterstitialAd?> loadInterstitialAd() async {
    InterstitialAd? interstitialAd;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );

    return interstitialAd;
  }

  /// Load rewarded ad
  Future<RewardedAd?> loadRewardedAd() async {
    RewardedAd? rewardedAd;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd failed to load: $error');
        },
      ),
    );

    return rewardedAd;
  }

  /// Dispose
  void dispose() {
    _isInitialized = false;
  }
}
