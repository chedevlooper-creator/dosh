/// Flutter form doğrulama araç takımı.
///
/// Oyun genelinde tutarlı, kullanıcı dostu doğrulama sağlar:
/// - Anında geri bildirim (kullanıcı yazarken)
/// - Net hata mesajları (neyin yanlış olduğunu açıkça belirtir)
/// - Hata önleme (geçersiz karakterleri engelleme)
/// - Başarılı gönderim onayı
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Doğrulama sonucu: geçerli mi, hata mesajı var mı.
typedef ValidationResult = ({bool isValid, String? error});

/// Doğrulama kuralı — bir giriş alanı için kontrol fonksiyonu.
typedef ValidationRule = ValidationResult Function(String value);

/// Doğrulama yardımcıları — oyun genelinde tutarlı kurallar.
abstract final class FormValidators {
  /// Boş geçilemez.
  static ValidationResult required(String value, [String fieldName = 'Bu alan']) {
    if (value.trim().isEmpty) {
      return (isValid: false, error: '$fieldName boş bırakılamaz');
    }
    return (isValid: true, error: null);
  }

  /// Minimum uzunluk.
  static ValidationResult minLength(String value, int min, [String fieldName = 'Bu alan']) {
    if (value.length < min) {
      return (isValid: false, error: '$fieldName en az $min karakter olmalı');
    }
    return (isValid: true, error: null);
  }

  /// Maksimum uzunluk.
  static ValidationResult maxLength(String value, int max, [String fieldName = 'Bu alan']) {
    if (value.length > max) {
      return (isValid: false, error: '$fieldName en fazla $max karakter olabilir');
    }
    return (isValid: true, error: null);
  }

  /// Sadece harf (Türkçe + Çeçen Kiril karakterleri dahil).
  static ValidationResult lettersOnly(String value, [String fieldName = 'Bu alan']) {
    // Türkçe: a-z, ç, ğ, ı, ö, ş, ü (büyük/küçük)
    // Çeçen Kiril: а-я, А-Я, Ӏ, ӏ, palochka varyantları
    // Digraflar da geçerli
    final regex = RegExp(
      r'^[a-zA-ZçğıöşüÇĞİÖŞÜа-яА-ЯӀӏ]+$',
    );
    if (value.isNotEmpty && !regex.hasMatch(value)) {
      return (isValid: false, error: '$fieldName sadece harf içerebilir');
    }
    return (isValid: true, error: null);
  }

  /// Sadece sayılar.
  static ValidationResult digitsOnly(String value, [String fieldName = 'Bu alan']) {
    if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
      return (isValid: false, error: '$fieldName sadece rakam içerebilir');
    }
    return (isValid: true, error: null);
  }

  /// Belirli karakterler (Çeçence arama için).
  static ValidationResult chechenSearch(String value) {
    if (value.isEmpty) return (isValid: true, error: null);

    // Çeçence: Kiril harfleri + palochka + digraflar oluşturan karakterler
    final regex = RegExp(
      r'^[а-яА-ЯёЁӀӏa-zA-Z]+$',
    );
    if (!regex.hasMatch(value)) {
      return (isValid: false, error: 'Aramada sadece harf kullanılabilir');
    }
    if (value.length < 2) {
      return (isValid: false, error: 'En az 2 harf yazın');
    }
    return (isValid: true, error: null);
  }

  /// Kullanıcı adı: harf, rakam, alt çizgi; 3-20 karakter.
  static ValidationResult username(String value) {
    if (value.isEmpty) {
      return (isValid: false, error: 'Kullanıcı adı boş bırakılamaz');
    }
    if (value.length < 3) {
      return (isValid: false, error: 'En az 3 karakter olmalı');
    }
    if (value.length > 20) {
      return (isValid: false, error: 'En fazla 20 karakter olabilir');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return (isValid: false, error: 'Sadece harf, rakam ve _ kullanılabilir');
    }
    return (isValid: true, error: null);
  }

  /// Zincirleme doğrulama: birden fazla kuralı sırayla uygular.
  /// İlk hatada durur.
  static ValidationResult chain(String value, List<ValidationRule> rules) {
    for (final rule in rules) {
      final result = rule(value);
      if (!result.isValid) return result;
    }
    return (isValid: true, error: null);
  }
}

/// Doğrulamalı metin alanı kontrolcüsü.
///
/// Özellikler:
/// - Anlık doğrulama (yazarken veya odak kaybında)
/// - Hata mesajı gösterimi
/// - Geçerli/geçersiz görsel geri bildirimi
class ValidatedTextController extends ChangeNotifier {
  ValidatedTextController({
    required this.rules,
    this.validateOnChange = false,
    this.validateOnBlur = true,
    String? initialValue,
  }) : _text = initialValue ?? '';

  /// Doğrulama kuralları (boşsa doğrulama yok).
  final List<ValidationRule> rules;

  /// Her karakterde doğrula (canlı geri bildirim).
  final bool validateOnChange;

  /// Odak kaybında doğrula.
  final bool validateOnBlur;

  String _text;
  String? _error;
  bool _touched = false;
  bool _focused = false;

  String get text => _text;
  String? get error => _error;
  bool get isValid => _error == null;
  bool get hasError => _error != null;
  bool get touched => _touched;

  /// Hata varsa true, yoksa false döner (UI'da widget kontrolü için).
  bool get showError => _touched && _error != null;

  void setText(String value) {
    if (_text == value) return;
    _text = value;
    _touched = true;
    if (validateOnChange) {
      _validate();
    }
    notifyListeners();
  }

  void onFocusChange(bool hasFocus) {
    _focused = hasFocus;
    if (!hasFocus && validateOnBlur && _touched) {
      _validate();
      notifyListeners();
    }
  }

  void _validate() {
    if (rules.isEmpty) {
      _error = null;
      return;
    }
    final result = FormValidators.chain(_text, rules);
    _error = result.error;
  }

  /// Doğrulamayı manuel tetikle (form gönderimi öncesi).
  bool validate() {
    _touched = true;
    _validate();
    notifyListeners();
    return isValid;
  }

  /// Hata mesajını temizle (form sıfırlama için).
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Tamamen sıfırla.
  void reset() {
    _text = '';
    _error = null;
    _touched = false;
    notifyListeners();
  }

  void dispose() {
    // ChangeNotifier base class'dan geliyor
  }
}

/// Doğrulamalı metin alanı widget'ı.
///
/// Kullanım:
/// ```dart
/// ValidatedTextField(
///   controller: myController,
///   label: 'Kullanıcı Adı',
///   prefixIcon: Icons.person,
/// )
/// ```
class ValidatedTextField extends StatefulWidget {
  const ValidatedTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.onSubmitted,
    this.filled = true,
    this.fillColor,
  });

  final ValidatedTextController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final bool filled;
  final Color? fillColor;

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(covariant ValidatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    widget.controller.onFocusChange(_focusNode.hasFocus);
  }

  void _onControllerChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showError = widget.controller.showError;
    final error = widget.controller.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          focusNode: _focusNode,
          controller: TextEditingController(text: widget.controller.text)
            ..selection = TextSelection.collapsed(
              offset: widget.controller.text.length,
            ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: widget.suffixIcon,
            filled: widget.filled,
            fillColor: widget.fillColor ?? theme.inputDecorationTheme.fillColor,
            errorText: null, // Hata mesajını aşağıda ayrı göster
            enabled: widget.enabled,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError
                    ? theme.colorScheme.error
                    : theme.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
          ),
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.controller.setText,
          onSubmitted: widget.onSubmitted,
        ),
        // Hata mesajı (alan altında, canlı)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: showError && error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Form gönderimi için onay butonu.
///
/// Yükleme durumu, devre dışı bırakma, başarı animasyonu.
class SubmitButton extends StatefulWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.success = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final bool success;
  final IconData? icon;

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton>
    with TickerProviderStateMixin {
  late final AnimationController _successCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didUpdateWidget(covariant SubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.success && !oldWidget.success) {
      _successCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.enabled && !widget.loading;
    final showSuccess = widget.success && !widget.loading;

    return AnimatedBuilder(
      animation: _successCtrl,
      builder: (context, _) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: showSuccess
                  ? Colors.green.shade600
                  : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
              disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: enabled ? 2 : 0,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : showSuccess
                      ? ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _successCtrl,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 28,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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

/// Başarı bildirimi (snackBar alternatifi).
void showSuccessMessage(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _SuccessOverlay(
      message: message,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);

  // 2.5 saniye sonra otomatik kapat
  Future.delayed(const Duration(milliseconds: 2500), () {
    if (entry.mounted) entry.remove();
  });
}

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: _ctrl,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Doğrulama özet durumu — birden fazla alanı kontrol et.
class FormValidationSummary extends ChangeNotifier {
  final List<ValidatedTextController> _controllers = [];

  void addController(ValidatedTextController controller) {
    _controllers.add(controller);
    controller.addListener(_onControllerChange);
  }

  void removeController(ValidatedTextController controller) {
    controller.removeListener(_onControllerChange);
    _controllers.remove(controller);
  }

  void _onControllerChange() {
    notifyListeners();
  }

  bool get isValid => _controllers.every((c) => c.isValid);
  bool get hasErrors => _controllers.any((c) => c.hasError);

  List<String> get errors => _controllers
      .where((c) => c.error != null)
      .map((c) => c.error!)
      .toList();

  /// Tüm alanları doğrula ve geçerliyse true döndür.
  bool validateAll() {
    bool allValid = true;
    for (final controller in _controllers) {
      if (!controller.validate()) {
        allValid = false;
      }
    }
    return allValid;
  }

  /// Tüm hataları temizle.
  void clearAllErrors() {
    for (final controller in _controllers) {
      controller.clearError();
    }
  }

  /// Tümünü sıfırla.
  void resetAll() {
    for (final controller in _controllers) {
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onControllerChange);
    }
    _controllers.clear();
    super.dispose();
  }
}
