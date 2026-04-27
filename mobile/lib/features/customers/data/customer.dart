class Customer {
  const Customer({required this.id, required this.name, this.phone, this.address});
  final String id;
  final String name;
  final String? phone;
  final String? address;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
}
