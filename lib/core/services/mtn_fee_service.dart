import 'package:genga/features/pay/contact_picker.dart';

class MtnFee {
  final int onNet;
  final int offNet;
  const MtnFee({required this.onNet, required this.offNet});
}

const _feeTiers = [
  (max: 1000, onNet: 20, offNet: 100),
  (max: 10000, onNet: 100, offNet: 200),
  (max: 150000, onNet: 250, offNet: 350),
  (max: 2000000, onNet: 1500, offNet: 1600),
  (max: 5000000, onNet: 3000, offNet: 3000),
];

MtnFee? getMtnFee(double amount) {
  if (amount <= 0) return null;
  for (final tier in _feeTiers) {
    if (amount <= tier.max) {
      return MtnFee(onNet: tier.onNet, offNet: tier.offNet);
    }
  }
  return null;
}

bool isPhoneRecipient(PickedRecipient? recipient) {
  return recipient != null && recipient.kind == RecipientKind.phone;
}
