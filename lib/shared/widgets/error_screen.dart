import 'package:flutter/cupertino.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Error"),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
