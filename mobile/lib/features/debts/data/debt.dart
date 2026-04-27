import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum DebtStatus { yesil, sari, kirmizi, gecikti, odendi }

extension DebtStatusX on DebtStatus {
  Color get color => switch (this) {
        DebtStatus.yesil => AppTheme.debtGreen,
        DebtStatus.sari => AppTheme.debtYellow,
        DebtStatus.kirmizi => AppTheme.debtRed,
        DebtStatus.gecikti => AppTheme.debtOverdue,
        DebtStatus.odendi => AppTheme.debtPaid,
      };

  String get label => switch (this) {
        DebtStatus.yesil => 'Güvenli',
        DebtStatus.sari => 'Yaklaşıyor',
        DebtStatus.kirmizi => 'Acil',
        DebtStatus.gecikti => 'Gecikti',
        DebtStatus.odendi => 'Ödendi',
      };
}

DebtStatus _parse(String v) => DebtStatus.values.firstWhere((e) => e.name == v);

class Debt {
  Debt({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.paidAmount,
    required this.remaining,
    required this.issuedOn,
    required this.dueOn,
    required this.daysLeft,
    required this.status,
  });

  final String id;
  final String customerId;
  final double totalAmount;
  final double paidAmount;
  final double remaining;
  final DateTime issuedOn;
  final DateTime dueOn;
  final int daysLeft;
  final DebtStatus status;

  String get overdueLabel {
    if (status != DebtStatus.gecikti) return '';
    final d = -daysLeft;
    return '$d gün gecikti';
  }

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        paidAmount: (json['paid_amount'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
        issuedOn: DateTime.parse(json['issued_on'] as String),
        dueOn: DateTime.parse(json['due_on'] as String),
        daysLeft: json['days_left'] as int,
        status: _parse(json['status'] as String),
      );
}

class CustomerDebtSummary {
  CustomerDebtSummary({
    required this.customerId,
    required this.customerName,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.debtsCount,
  });

  final String customerId;
  final String customerName;
  final double total;
  final double paid;
  final double remaining;
  final int debtsCount;

  factory CustomerDebtSummary.fromJson(Map<String, dynamic> json) {
    final c = json['customer'] as Map<String, dynamic>;
    return CustomerDebtSummary(
      customerId: c['id'] as String,
      customerName: c['name'] as String,
      total: (json['total_debt'] as num).toDouble(),
      paid: (json['total_paid'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      debtsCount: json['debts_count'] as int,
    );
  }
}
