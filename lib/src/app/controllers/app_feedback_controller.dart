import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/snackbar_message_gate.dart';

class AppFeedbackController {
  AppFeedbackController({required this.context, required this.snackbarMessageGate});

  final BuildContext Function() context;
  final SnackbarMessageGate snackbarMessageGate;

  void showAboutSerenity() {
    showAboutDialog(
      context: context(),
      applicationName: 'Serenity',
      applicationVersion: 'Desktop workspace viewer',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1D4B0), Color(0xFFD39B73), Color(0xFF8DA7D0)],
            ),
          ),
          child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
        ),
      ),
      children: const [
        SizedBox(height: 8),
        Text('Serenity is a desktop-style image and video workspace for arranging, reviewing, and revisiting media.'),
      ],
    );
  }

  void showMessage(String message) {
    if (!snackbarMessageGate.shouldShow(message)) {
      return;
    }
    ScaffoldMessenger.of(context()).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
