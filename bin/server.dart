import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // 存储所有连接的WebSocket客户端
  final clients = <WebSocketChannel>[];

  // WebSocket处理器
  final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
    clients.add(webSocket);

    webSocket.stream.listen(
      (message) {
        // 广播消息给所有连接的客户端
        for (var client in clients) {
          client.sink.add(message);
        }
      },
      onDone: () => clients.remove(webSocket),
    );
  });

  // HTTP处理器，返回HTML页面
  final httpHandler = (shelf.Request request) {
    if (request.url.path == '') {
      return shelf.Response.ok(
        '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>发送消息</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { padding: 20px; font-family: Arial, sans-serif; }
            input, button { margin: 10px 0; padding: 8px; }
            button { background-color: #4CAF50; color: white; border: none; cursor: pointer; }
          </style>
        </head>
        <body>
          <input type="text" id="messageInput" placeholder="输入消息">
          <button onclick="sendMessage()">发送</button>
          <script>
            const ws = new WebSocket('ws://' + window.location.hostname + ':8080');
            
            function sendMessage() {
              const input = document.getElementById('messageInput');
              ws.send(input.value);
              input.value = '';
            }
          </script>
        </body>
        </html>
        ''',
        headers: {'content-type': 'text/html'},
      );
    }
    return shelf.Response.notFound('Not found');
  };

  // 创建服务器
  final server = await io.serve(
    shelf.Cascade().add(wsHandler).add(httpHandler).handler,
    InternetAddress.anyIPv4,
    8080,
  );

  print('服务器运行在: ${server.address.host}:${server.port}');
}
