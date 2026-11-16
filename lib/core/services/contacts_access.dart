import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('com.example.genga/contacts');

enum ContactsAccess { allowed, notAsked, denied, unsupported }

Future<ContactsAccess> readContactsAccess() async {
  try {
    final raw = await _channel.invokeMethod<String>('status');
    return ContactsAccess.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => ContactsAccess.unsupported,
    );
  } on MissingPluginException {
    return ContactsAccess.unsupported;
  }
}

Future<bool> requestContactsAccess() async {
  try {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  } on MissingPluginException {
    return false;
  }
}

final contactsAccessProvider = FutureProvider.autoDispose<ContactsAccess>(
  (ref) => readContactsAccess(),
);
