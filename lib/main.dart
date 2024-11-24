import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tspl_label_printer/printer_service/printer_service.dart';

void main() {
  runApp(const MainApp());
}

class OrderEntity {
  final String name;
  final String productName;
  final num price;
  final String date;

  static List<OrderEntity> get orders => [
        OrderEntity(
            name: 'User',
            productName: 'Laptop',
            price: 2399,
            date: '2024-11-24'),
        OrderEntity(
            name: 'User',
            productName: 'Smartphone',
            price: 899,
            date: '2024-11-23'),
        OrderEntity(
            name: 'User',
            productName: 'Tablet',
            price: 1199,
            date: '2024-11-22'),
      ];

  OrderEntity(
      {required this.name,
      required this.productName,
      required this.price,
      required this.date});

  @override
  bool operator ==(covariant OrderEntity other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.productName == productName &&
        other.price == price &&
        other.date == date;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        productName.hashCode ^
        price.hashCode ^
        date.hashCode;
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _printer = PrinterService('10.10.100.1');
  List<OrderEntity> _selectedItems = [];

  Future<void> labelPreparing(List<OrderEntity> orders) async {
    final bool disconnectAfterPrinting = orders.length > 1;
    for (var order in orders) {
      final String tsplCommand = '''
  TEXT 45,50,"TSS24.BF2",0,1,1,"Customer: ${order.name}"
  TEXT 45,90,"TSS24.BF2",0,1,1,"Product Name: ${order.productName}"
  TEXT 45,130,"TSS24.BF2",0,1,1,"Price: ${order.price}"
  TEXT 45,170,"TSS24.BF2",0,1,1,"Date: ${order.date}"
  PRINT 1
  ''';

      await printTicket(tsplCommand,
          disconnectAfterPrinting: disconnectAfterPrinting);
    }
  }

  @override
  void dispose() {
    if (_printer.isConnected) _printer.disconnect();
    super.dispose();
  }

  Future<void> printTicket(String ticket,
      {bool disconnectAfterPrinting = true}) async {
    PrinterStatus connect = await _printer.connect();
    switch (connect) {
      case PrinterStatus.connected:
        connect = await _printer.printTicket(ticket,
            disconnectAfter: disconnectAfterPrinting);
      default:
        log('Error: $connect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton(
            foregroundColor:
                _selectedItems.isNotEmpty ? Colors.green : Colors.grey,
            onPressed: _selectedItems.isNotEmpty
                ? () => labelPreparing(_selectedItems)
                : null,
            child: const Icon(
              Icons.print_rounded,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Product Name')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Date')),
                    ],
                    rows: OrderEntity.orders.map((order) {
                      return DataRow(
                          selected: _selectedItems.contains(order),
                          onSelectChanged: (bool? isSelected) {
                            if (isSelected == true) {
                              _selectedItems.add(order);
                            } else if (isSelected == false) {
                              _selectedItems.remove(order);
                            }
                            setState(() {});
                          },
                          cells: [
                            DataCell(Text(order.name)),
                            DataCell(Text(order.productName)),
                            DataCell(Text('${order.price}\$')),
                            DataCell(Text(order.date)),
                          ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
