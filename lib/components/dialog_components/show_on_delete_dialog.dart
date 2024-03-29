import 'package:flutter/material.dart';

Future<bool?> showDeleteDialog(BuildContext context, String text) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Are you sure you want to delete $text"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Delete')),
          ],
        );
      });
}
