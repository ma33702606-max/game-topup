import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─── Firestore-backed models ─────────────────────────────────────────────────

class GameModel {
  final String id;
  final String name;
  final String shortName;
  final String currency;
  final String gradientKey;
  final int sortOrder;
  final bool isActive;

  const GameModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.currency,
    required this.gradientKey,
    required this.sortOrder,
    required this.isActive,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GameModel(
      id: doc.id,
      name: d['name'] ?? '',
      shortName: d['shortName'] ?? '',
      currency: d['currency'] ?? '',
      gradientKey: d['gradientKey'] ?? 'primary',
      sortOrder: (d['sortOrder'] ?? 0) as int,
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'shortName': shortName,
        'currency': currency,
        'gradientKey': gradientKey,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  LinearGradient get gradient {
    switch (gradientKey) {
      case 'pubg':
        return AppColors.pubgGradient;
      case 'freeFire':
        return AppColors.freeFireGradient;
      case 'efootball':
        return AppColors.efootballGradient;
      case 'eafc':
        return AppColors.eafcGradient;
      default:
        return AppColors.primaryGradient;
    }
  }

  Color get accentColor {
    switch (gradientKey) {
      case 'pubg':
        return AppColors.pubgColor;
      case 'freeFire':
        return AppColors.freeFireColor;
      case 'efootball':
        return AppColors.efootballColor;
      case 'eafc':
        return AppColors.eafcColor;
      default:
        return AppColors.primary;
    }
  }
}

class PackageModel {
  final String id;
  final String name;
  final double price;
  final int amount;
  final bool isPopular;
  final bool isActive;

  const PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.amount,
    required this.isPopular,
    required this.isActive,
  });

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: d['name'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      amount: (d['amount'] ?? 0) as int,
      isPopular: d['isPopular'] ?? false,
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'price': price,
        'amount': amount,
        'isPopular': isPopular,
        'isActive': isActive,
      };
}

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String gradientKey;
  final int sortOrder;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.gradientKey,
    required this.sortOrder,
    required this.isActive,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      gradientKey: d['gradientKey'] ?? 'primary',
      sortOrder: (d['sortOrder'] ?? 0) as int,
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'subtitle': subtitle,
        'gradientKey': gradientKey,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  LinearGradient get gradient {
    switch (gradientKey) {
      case 'pubg':
        return AppColors.pubgGradient;
      case 'freeFire':
        return AppColors.freeFireGradient;
      case 'efootball':
        return AppColors.efootballGradient;
      case 'eafc':
        return AppColors.eafcGradient;
      default:
        return AppColors.primaryGradient;
    }
  }
}
