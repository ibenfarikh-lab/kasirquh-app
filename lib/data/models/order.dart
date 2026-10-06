/// Status pesanan — selaras dengan skema Firestore yang dikunci.
enum OrderStatus { menunggu, dikemas, dikirim, selesai, dibatalkan }

OrderStatus orderStatusFrom(String s) =>
    OrderStatus.values.firstWhere((e) => e.name == s,
        orElse: () => OrderStatus.menunggu);

/// Model Pesanan — mirror koleksi Firestore `orders`.
class Order {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final String payment; // tunai / transfer / cod
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.payment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'items': items.map((e) => e.toMap()).toList().toString(),
        'total': total,
        'status': status.name,
        'payment': payment,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toFirestore() => {
        'customerId': customerId,
        'customerName': customerName,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'status': status.name,
        'payment': payment,
        'createdAt': createdAt,
      };
}

class OrderItem {
  final String productId;
  final String name;
  final int qty;
  final int price;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'price': price,
      };
}
