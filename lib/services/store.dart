import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Skapa samma id i App Store Connect → Subscriptions.
const kPremiumId = 'pawmatch_premium_month';

class Store {
  static final InAppPurchase iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static ProductDetails? product;
  static String status = '';
  static Future<ProductDetails?>? _loading;

  static Future<void> boot(void Function(bool ok) onOwned) async {
    _sub?.cancel();
    final ok = await iap.isAvailable();
    if (!ok) {
      status = 'Butiken är inte redo än.';
      return;
    }
    await load();
    _sub = iap.purchaseStream.listen((buys) async {
      for (final p in buys) {
        if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
          onOwned(true);
        }
        if (p.pendingCompletePurchase) await iap.completePurchase(p);
      }
    });
  }

  static Future<ProductDetails?> load() {
    if (product != null) return Future.value(product);
    return _loading ??= _fetch();
  }

  static Future<ProductDetails?> _fetch() async {
    try {
      final resp = await iap.queryProductDetails({kPremiumId});
      if (resp.productDetails.isNotEmpty) product = resp.productDetails.first;
      return product;
    } catch (e) {
      debugPrint('IAP load $e');
      return null;
    } finally {
      _loading = null;
    }
  }

  static Future<bool> buy() async {
    try {
      final item = await load();
      if (item == null) {
        status = 'Produkten saknas i App Store Connect.';
        return false;
      }
      return iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: item));
    } catch (e) {
      status = e.toString();
      debugPrint('IAP $e');
      return false;
    }
  }

  static Future<String> restore() async {
    try {
      final ok = await iap.isAvailable();
      if (!ok) return 'App Store svarar inte just nu. Försök igen om en stund.';
      var hit = false;
      final sub = iap.purchaseStream.listen((buys) {
        for (final p in buys) {
          if (p.status == PurchaseStatus.restored || p.status == PurchaseStatus.purchased) hit = true;
          if (p.pendingCompletePurchase) iap.completePurchase(p);
        }
      });
      await iap.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 2));
      await sub.cancel();
      if (hit) return 'Köpet är återställt. Premium gäller på den här telefonen.';
      return 'Inget köp hittades. När appen är publicerad kan du återställa här om du bytt telefon. Abonnemanget sägs upp i App Store, inte i PawMatch.';
    } catch (e) {
      debugPrint('restore $e');
      return 'Kunde inte nå App Store. Försök igen.';
    }
  }
}
