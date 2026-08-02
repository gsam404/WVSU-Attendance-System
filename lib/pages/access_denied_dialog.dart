import 'package:flutter/material.dart';

class AccessDeniedDialog {
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text("Access Denied"),
            ],
          ),
          content: const Text(
            "You don't have permission to access this feature.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
