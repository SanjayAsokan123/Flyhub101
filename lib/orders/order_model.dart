class OrderModel {
  final String orderId;
  final String status;
  final DateTime createdAt;
  final String buyerName;
  final String buyerPhone;

  OrderModel({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.buyerName,
    required this.buyerPhone,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json["orderId"],
      status: json["status"] ?? "pending",
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json["createdAt"].toString()) ?? 0,
      ),
      buyerName: json["buyer"]?["name"] ?? "Unknown",
      buyerPhone: json["buyer"]?["phone"] ?? "N/A",
    );
  }

}
