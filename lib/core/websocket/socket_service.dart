import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:chatbond/core/network/api_client.dart';

class SocketService {
  io.Socket? _socket;

  Future<void> connect(String accessToken) async {
    if (_socket?.connected == true) return;
    _socket = io.io(
      '${ApiClient.baseUrl.replaceFirst('/api/v1', '')}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  void joinChat(String chatId) => _socket?.emit('joinChat', chatId);
  void leaveChat(String chatId) => _socket?.emit('leaveChat', chatId);

  void sendMessage(Map<String, dynamic> payload) =>
      _socket?.emit('sendMessage', payload);

  void onNewMessage(void Function(dynamic data) callback) =>
      _socket?.on('newMessage', callback);
  void offNewMessage() => _socket?.off('newMessage');

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
