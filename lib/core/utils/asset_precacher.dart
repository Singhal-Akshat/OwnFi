import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssetPrecacher {
  static final List<String> cardImages = [
    'HDFC_MoneyBack_Vertical_HQ.webp',
    'IDFC_Millennia_HQ.webp',
    'RBL_Bank_Fitted.webp',
    'SBI_SimplySave_Mobile.webp',
    'Scapia_Rupay.webp',
    'Scapia_Visa.webp',
    'Tata_NeuCard_FullFrame.webp',
    'UNI_YesBank_Vertical.webp',
    'hsbc_vertical_card_final.webp',
  ];

  static final List<String> cardSvgs = [
    'LIC_Axis_Cropped_Vector.svg',
  ];

  static final List<String> bankSvgs = [
    'HDB.svg',
    'SBI-logo.svg',
  ];

  static Future<void> precache(BuildContext context) async {
    // Run pre-caching after a delay so it doesn't block transitions
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!context.mounted) return;
      try {
        // Precache raster WebP images
        for (final image in cardImages) {
          if (!context.mounted) return;
          precacheImage(
            AssetImage('assets/credit_card_images/$image'),
            context,
          );
        }

        // Precache SVG vector images using the flutter_svg cache API (version 2.0+)
        for (final svgFile in cardSvgs) {
          final loader = SvgAssetLoader('assets/credit_card_images/$svgFile');
          svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        }

        for (final svgFile in bankSvgs) {
          final loader = SvgAssetLoader('assets/bank_logos/$svgFile');
          svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        }
      } catch (e) {
        debugPrint('Error pre-caching assets: $e');
      }
    });
  }
}
