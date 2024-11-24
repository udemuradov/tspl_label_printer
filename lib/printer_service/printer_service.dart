import 'dart:io';

enum PrinterStatus {
  success,
  timeout,
  error,
  notConnected,
  connected,
}

class PrinterService {
  final String host;
  final int port;
  final Duration timeout;
  final double paperWidth;
  final double paperHeight;

  PrinterService(
    this.host, {
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
    this.paperWidth = 60,
    this.paperHeight = 40,
  });

  Socket? _socket;

  bool get isConnected => _socket != null;

  String get paperSettings => '''
  SIZE $paperWidth mm, $paperHeight mm
  GAP 2 mm, 0
  CLS
''';

  Future<PrinterStatus> connect() async {
    if (isConnected) return PrinterStatus.connected;
    try {
      _socket = await Socket.connect(host, port, timeout: timeout);
      return PrinterStatus.connected;
    } catch (e) {
      return PrinterStatus.timeout;
    }
  }

  Future<PrinterStatus> printTicket(String data,
      {bool disconnectAfter = true}) async {
    final List<int> ticket = (paperSettings + data).codeUnits;
    if (!isConnected) {
      final status = await connect();
      if (status != PrinterStatus.connected) return status;
    }
    try {
      _socket?.add(ticket);
      if (disconnectAfter) return await disconnect();
      return PrinterStatus.success;
    } catch (e) {
      return PrinterStatus.error;
    }
  }

  Future<PrinterStatus> disconnect() async {
    if (!isConnected) return PrinterStatus.notConnected;

    try {
      await _socket?.flush();
      await _socket?.close();
      _socket = null;
      return PrinterStatus.success;
    } catch (e) {
      return PrinterStatus.error;
    }
  }
}
