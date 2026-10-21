enum OrderStatus { menunggu, dikemas, dikirim, selesai, dibatalkan }

OrderStatus orderStatusFrom(String s) =>
    OrderStatus.values.firstWhere((e) => e.name == s,
        orElse: () => OrderStatus.menunggu);

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String code;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final String payment;
  final DateTime createdAt;
  final String transferReference;
  final String transferStatus;
  final String transferRejectReason;
  final int coinUsed;
  final int coinValue;
  final int earnedCoins;
  final String fulfillment;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.code,
    required this.items,
    required this.total,
    required this.status,
    required this.payment,
    required this.createdAt,
    this.transferReference = '',
    this.transferStatus = '',
    this.transferRejectReason = '',
    this.coinUsed = 0,
    this.coinValue = 0,
    this.earnedCoins = 0,
    this.fulfillment = 'pickup',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'code': code,
        'items': items.map((e) => e.toMap()).toList().toString(),
        'total': total,
        'status': status.name,
        'payment': payment,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toFirestore() => {
        'code': code,
        'customerId': customerId,
        'customerName': customerName,
        'items': items
            .map((e) => {
                  'productId': e.productId,
                  'name': e.name,
                  'price': e.price,
                  'qty': e.qty,
                  'subtotal': e.price * e.qty,
                })
            .toList(),
        'total': total,
        'status': status.name,
        'paymentMethod': payment,
        'createdAt': createdAt,
        'updatedAt': createdAt,
      };
}

class OrderItem {
  final String productId;
  final String name;
  final double qty;
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

List<String> topProductsByQty(List<Order> orders, {int limit = 8}) {
  final qtyById = <String, double>{};
  for (final o in orders) {
    if (o.status == OrderStatus.dibatalkan) continue;
    for (final item in o.items) {
      qtyById[item.productId] = (qtyById[item.productId] ?? 0) + item.qty;
    }
  }
  final sorted = qtyById.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(limit).map((e) => e.key).toList();
}
