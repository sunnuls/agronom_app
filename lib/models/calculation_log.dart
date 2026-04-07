class CalculationLog {
  final int? id;
  final int profileId;
  final String profileNameSnapshot;
  final double tankVolumeSnapshot;
  final double waterRateSnapshot;
  final double remainderLiters;
  final double refillVolumeLiters;
  final double coveredAreaHa;
  final DateTime createdAt;
  List<CalculationLogChemical> chemicals;

  CalculationLog({
    this.id,
    required this.profileId,
    required this.profileNameSnapshot,
    required this.tankVolumeSnapshot,
    required this.waterRateSnapshot,
    required this.remainderLiters,
    required this.refillVolumeLiters,
    required this.coveredAreaHa,
    DateTime? createdAt,
    this.chemicals = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'profile_name_snapshot': profileNameSnapshot,
      'tank_volume_snapshot': tankVolumeSnapshot,
      'water_rate_snapshot': waterRateSnapshot,
      'remainder_liters': remainderLiters,
      'refill_volume_liters': refillVolumeLiters,
      'covered_area_ha': coveredAreaHa,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CalculationLog.fromMap(Map<String, dynamic> map) {
    return CalculationLog(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      profileNameSnapshot: map['profile_name_snapshot'] as String,
      tankVolumeSnapshot: (map['tank_volume_snapshot'] as num).toDouble(),
      waterRateSnapshot: (map['water_rate_snapshot'] as num).toDouble(),
      remainderLiters: (map['remainder_liters'] as num).toDouble(),
      refillVolumeLiters: (map['refill_volume_liters'] as num).toDouble(),
      coveredAreaHa: (map['covered_area_ha'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Экспорт для обмена (файл .agronom).
  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'type': 'agronom_calculation',
      'profileId': profileId,
      'profileName': profileNameSnapshot,
      'tankVolumeLiters': tankVolumeSnapshot,
      'waterRateLitersPerHa': waterRateSnapshot,
      'remainderLiters': remainderLiters,
      'refillVolumeLiters': refillVolumeLiters,
      'coveredAreaHa': coveredAreaHa,
      'createdAt': createdAt.toIso8601String(),
      'chemicals': chemicals.map((c) => c.toJson()).toList(),
    };
  }
}

class CalculationLogChemical {
  final int? id;
  final int calculationLogId;
  final String nameSnapshot;
  final double rateValueSnapshot;
  final String rateUnitSnapshot;
  final double amountToAdd;

  CalculationLogChemical({
    this.id,
    required this.calculationLogId,
    required this.nameSnapshot,
    required this.rateValueSnapshot,
    required this.rateUnitSnapshot,
    required this.amountToAdd,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'calculation_log_id': calculationLogId,
      'name_snapshot': nameSnapshot,
      'rate_value_snapshot': rateValueSnapshot,
      'rate_unit_snapshot': rateUnitSnapshot,
      'amount_to_add': amountToAdd,
    };
  }

  factory CalculationLogChemical.fromMap(Map<String, dynamic> map) {
    return CalculationLogChemical(
      id: map['id'] as int?,
      calculationLogId: map['calculation_log_id'] as int,
      nameSnapshot: map['name_snapshot'] as String,
      rateValueSnapshot: (map['rate_value_snapshot'] as num).toDouble(),
      rateUnitSnapshot: map['rate_unit_snapshot'] as String,
      amountToAdd: (map['amount_to_add'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameSnapshot,
      'rateValue': rateValueSnapshot,
      'rateUnit': rateUnitSnapshot,
      'amountToAdd': amountToAdd,
    };
  }
}
