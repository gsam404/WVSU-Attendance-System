import 'package:flutter/material.dart';

class PortalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const PortalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 25, offset: Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: const Color(0xFF1A237E)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 51, 133, 210),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
