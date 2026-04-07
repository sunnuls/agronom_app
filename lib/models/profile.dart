class Profile {
  final int? id;
  final String name;
  final double tankVolumeLiters;
  final double waterRateLitersPerHa;
  final bool isFavorite;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<ProfileChemical> chemicals;

  Profile({
    this.id,
    required this.name,
    required this.tankVolumeLiters,
    required this.waterRateLitersPerHa,
    this.isFavorite = false,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.chemicals = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'tank_volume_liters': tankVolumeLiters,
      'water_rate_liters_per_ha': waterRateLitersPerHa,
      'is_favorite': isFavorite ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      tankVolumeLiters: (map['tank_volume_liters'] as num).toDouble(),
      waterRateLitersPerHa: (map['water_rate_liters_per_ha'] as num).toDouble(),
      isFavorite: (map['is_favorite'] as int) == 1,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'type': 'agronom_profile',
      'name': name,
      'tankVolumeLiters': tankVolumeLiters,
      'waterRateLitersPerHa': waterRateLitersPerHa,
      'isFavorite': isFavorite,
      'notes': notes,
      'chemicals': chemicals.map((c) => c.toJson()).toList(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final chemicals = (json['chemicals'] as List<dynamic>? ?? [])
        .map((c) => ProfileChemical.fromJson(c as Map<String, dynamic>))
        .toList();
    return Profile(
      name: json['name'] as String,
      tankVolumeLiters: (json['tankVolumeLiters'] as num).toDouble(),
      waterRateLitersPerHa: (json['waterRateLitersPerHa'] as num).toDouble(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      chemicals: chemicals,
    );
  }

  Profile copyWith({
    int? id,
    String? name,
    double? tankVolumeLiters,
    double? waterRateLitersPerHa,
    bool? isFavorite,
    String? notes,
    List<ProfileChemical>? chemicals,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      tankVolumeLiters: tankVolumeLiters ?? this.tankVolumeLiters,
      waterRateLitersPerHa: waterRateLitersPerHa ?? this.waterRateLitersPerHa,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      chemicals: chemicals ?? this.chemicals,
    );
  }
}

class ProfileChemical {
  final int? id;
  final int profileId;
  final String name;
  final double rateValue;
  final String rateUnit;
  final int sortOrder;
  final bool isEnabled;

  ProfileChemical({
    this.id,
    required this.profileId,
    required this.name,
    required this.rateValue,
    this.rateUnit = 'л/га',
    this.sortOrder = 0,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'name': name,
      'rate_value': rateValue,
      'rate_unit': rateUnit,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rateValue': rateValue,
      'rateUnit': rateUnit,
      'isEnabled': isEnabled,
    };
  }

  factory ProfileChemical.fromJson(Map<String, dynamic> json) {
    return ProfileChemical(
      profileId: 0,
      name: json['name'] as String,
      rateValue: (json['rateValue'] as num).toDouble(),
      rateUnit: json['rateUnit'] as String? ?? 'л/га',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  factory ProfileChemical.fromMap(Map<String, dynamic> map) {
    return ProfileChemical(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      name: map['name'] as String,
      rateValue: (map['rate_value'] as num).toDouble(),
      rateUnit: map['rate_unit'] as String? ?? 'л/га',
      sortOrder: map['sort_order'] as int? ?? 0,
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
    );
  }

  ProfileChemical copyWith({
    int? id,
    int? profileId,
    String? name,
    double? rateValue,
    String? rateUnit,
    int? sortOrder,
    bool? isEnabled,
  }) {
    return ProfileChemical(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      rateValue: rateValue ?? this.rateValue,
      rateUnit: rateUnit ?? this.rateUnit,
      sortOrder: sortOrder ?? this.sortOrder,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
