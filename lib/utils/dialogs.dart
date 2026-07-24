import 'package:flutter/material.dart';

class DialogUtils {
  static Future<void> showSuccess(
    BuildContext context,
    String message,
  ) {
    return _showStatusDialog(
      context,
      message,
      true,
    );
  }

  static Future<void> showError(
    BuildContext context,
    String message,
  ) {
    return _showStatusDialog(
      context,
      message,
      false,
    );
  }

  static Future<void> _showStatusDialog(
    BuildContext context,
    String message,
    bool success,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: success ? Colors.green : Colors.red,
                    child: Icon(
                      success ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Click anywhere to close",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
