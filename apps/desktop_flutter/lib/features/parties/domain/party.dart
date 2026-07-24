enum PartyType {
  customer('زبون'),
  supplier('مجهز'),
  employee('موظف'),
  customerAndSupplier('زبون ومجهز');

  const PartyType(this.label);

  final String label;
}

class Party {
  const Party({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.name,
    required this.type,
    required this.workplace,
    required this.branch,
    required this.phone,
    required this.alternatePhone,
    required this.city,
    required this.address,
    required this.notes,
    required this.balanceIqd,
    required this.balanceUsd,
  });

  final String id;
  final int number;
  final DateTime createdAt;
  final String name;
  final PartyType type;
  final String workplace;
  final String branch;
  final String phone;
  final String alternatePhone;
  final String city;
  final String address;
  final String notes;
  final int balanceIqd;
  final int balanceUsd;

  String get searchText => [
        number,
        name,
        type.label,
        workplace,
        branch,
        phone,
        alternatePhone,
        city,
        address,
        balanceIqd,
        balanceUsd,
      ].join(' ').toLowerCase();

  Party copyWith({
    DateTime? createdAt,
    String? name,
    PartyType? type,
    String? workplace,
    String? branch,
    String? phone,
    String? alternatePhone,
    String? city,
    String? address,
    String? notes,
    int? balanceIqd,
    int? balanceUsd,
  }) {
    return Party(
      id: id,
      number: number,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      type: type ?? this.type,
      workplace: workplace ?? this.workplace,
      branch: branch ?? this.branch,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      city: city ?? this.city,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      balanceIqd: balanceIqd ?? this.balanceIqd,
      balanceUsd: balanceUsd ?? this.balanceUsd,
    );
  }
}
