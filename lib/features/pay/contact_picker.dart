import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

const _channel = MethodChannel('com.example.genga/contacts');

enum RecipientKind { phone, code }

class PickedRecipient {
  final String name;
  final String phone;
  final RecipientKind kind;
  const PickedRecipient({
    required this.name,
    required this.phone,
    required this.kind,
  });
}

RecipientKind detectRecipientKind(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length == 10 ? RecipientKind.phone : RecipientKind.code;
}

class _Contact {
  final String name;
  final List<String> phones;
  const _Contact({required this.name, required this.phones});
}

Future<PickedRecipient?> showContactPicker(BuildContext context) {
  return showGengaBottomSheet<PickedRecipient>(
    context: context,
    maxHeightFraction: 0.85,
    builder: (ctx) => const _ContactPickerContent(),
  );
}

class _ContactPickerContent extends StatefulWidget {
  const _ContactPickerContent();

  @override
  State<_ContactPickerContent> createState() => _ContactPickerContentState();
}

class _ContactPickerContentState extends State<_ContactPickerContent> {
  final _searchController = TextEditingController();
  final _focus = FocusNode()..addListener(() {});
  List<_Contact>? _contacts;
  bool _loading = true;
  bool _denied = false;
  String _search = '';
  bool _numberPad = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      if (granted != true) {
        if (mounted) {
          setState(() {
            _denied = true;
            _loading = false;
          });
        }
        return;
      }

      final raw = await _channel.invokeMethod<List<dynamic>>('getContacts');
      if (raw == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final contacts =
          raw.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return _Contact(
              name: map['name'] as String,
              phones: List<String>.from(map['phones'] as List),
            );
          }).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _loading = false;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _denied = true;
          _loading = false;
        });
      }
    }
  }

  List<_Contact> get _filtered {
    final all = _contacts;
    if (all == null) return [];
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    final qDigits = _search.replaceAll(RegExp(r'\D'), '');
    return all.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (qDigits.isEmpty) return false;
      return c.phones.any(
        (p) => p.replaceAll(RegExp(r'\D'), '').contains(qDigits),
      );
    }).toList();
  }

  // The keyboard type only changes when the field regains focus.
  void _toggleNumberPad() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    setState(() => _numberPad = !_numberPad);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  bool get _looksLikeNumber {
    final t = _search.trim();
    return t.length >= 3 && RegExp(r'^[+\d\s\-()]+$').hasMatch(t);
  }

  void _useTyped() {
    final number = _search.trim();
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      PickedRecipient(
        name: number,
        phone: number,
        kind: detectRecipientKind(number),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: SheetTitle('Pay'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: GengaTextField(
                    key: ValueKey(_numberPad),
                    controller: _searchController,
                    focusNode: _focus,
                    icon: AppIcons.search,
                    placeholder: _numberPad
                        ? 'Number or merchant code'
                        : 'Name, number or merchant code',
                    clearable: true,
                    keyboardType: _numberPad ? TextInputType.phone : null,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Pressable(
                  scale: 0.85,
                  onTap: _toggleNumberPad,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: AppIcon(
                      _numberPad ? AppIcons.letters : AppIcons.dial,
                      size: 24,
                      color: GengaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_looksLikeNumber)
            _TypedRow(value: _search.trim(), onTap: _useTyped),
          Expanded(child: _buildContactList()),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Contacts are off. Type a number or merchant code above, or allow access in Settings.',
            textAlign: TextAlign.center,
            style: GengaTypography.subhead,
          ),
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      if (_looksLikeNumber) return const SizedBox.shrink();
      return Center(
        child: Text(
          _search.isNotEmpty && !_looksLikeNumber
              ? 'No matches'
              : 'No contacts',
          style: GengaTypography.subhead,
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final contact = list[index];
        final phone = contact.phones.isNotEmpty ? contact.phones.first : '';
        final initial = contact.name.isNotEmpty
            ? contact.name[0].toUpperCase()
            : '?';
        final showLetter =
            index == 0 ||
            list[index - 1].name.isEmpty ||
            list[index - 1].name[0].toUpperCase() != initial;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLetter && _search.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 2),
                child: Text(initial, style: GengaTypography.caption1),
              ),
            Pressable(
              scale: 0.98,
              onTap: () {
                if (phone.isEmpty) return;
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(
                  PickedRecipient(
                    name: contact.name,
                    phone: phone,
                    kind: detectRecipientKind(phone),
                  ),
                );
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: const Color(0x00000000),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GengaTypography.body.copyWith(
                          color: phone.isEmpty
                              ? GengaColors.textTertiary
                              : GengaColors.textPrimary,
                        ),
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(phone, style: GengaTypography.subhead),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypedRow extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _TypedRow({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);
    final isPhone = detectRecipientKind(value) == RecipientKind.phone;

    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color(0x00000000),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
              ),
              child: Center(
                child: AppIcon(
                  isPhone ? AppIcons.phone : AppIcons.link,
                  size: 15,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay $value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GengaTypography.body.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isPhone ? 'Phone number' : 'Merchant code',
                    style: GengaTypography.caption1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
