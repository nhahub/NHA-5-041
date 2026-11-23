class Validators {
  const Validators._();

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRe.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? name(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'Enter your name';
    return null;
  }

  static String? Function(String?) confirm(String Function() original) =>
      (value) {
        if ((value ?? '').isEmpty) return 'Confirm your password';
        if (value != original()) return 'Passwords do not match';
        return null;
      };
}
