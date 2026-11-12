import 'package:flutter/material.dart';

class ErpMobileHomeView extends StatelessWidget {
  const ErpMobileHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultoria Bananeira')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
              SizedBox(height: 20),
              Text('Login realizado!', style: TextStyle(fontSize: 24)),
              SizedBox(height: 12),
              Text(
                'Integração com a API Bananeira funcionando.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
