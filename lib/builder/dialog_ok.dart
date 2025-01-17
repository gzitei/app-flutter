import 'package:flutter/material.dart';

Future<dynamic> dialog_ok(contexto, title, msg) {
  if (msg.runtimeType.toString().toLowerCase() == "string") {
    return showDialog(
      context: contexto,
      builder: (BuildContext contexto) {
        return AlertDialog(
          title: Text(title),
          content: Text(msg),
          actionsPadding: const EdgeInsets.all(10),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => {Navigator.pop(contexto)},
            ),
          ],
        );
      },
    );
  } else {
    return showDialog(
      context: contexto,
      builder: (BuildContext contexto) {
        return AlertDialog(
          title: Text(title),
          content: msg,
          actionsPadding: const EdgeInsets.all(10),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => {Navigator.pop(contexto)},
            ),
          ],
        );
      },
    );
  }
}
