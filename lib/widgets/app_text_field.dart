import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uygulama genelinde kullanılacak TextField widget'ı
/// Varsayılan olarak cümlelerin ilk harfi büyük olacak şekilde ayarlanmıştır.
/// 
/// Özel durumlar için [textCapitalization] parametresini kullanabilirsiniz:
/// - TextCapitalization.none: Büyük harf zorlaması olmaz (örn: e-posta, şifre)
/// - TextCapitalization.characters: Tüm harfler büyük (örn: plaka, TC kimlik)
/// - TextCapitalization.words: Her kelimenin ilk harfi büyük
/// - TextCapitalization.sentences: Her cümlenin ilk harfi büyük (varsayılan)
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool autocorrect;
  final bool enableSuggestions;
  final EdgeInsets? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.validator,
    this.textCapitalization = TextCapitalization.sentences, // Varsayılan olarak cümle başları büyük
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.decoration,
    this.style,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      style: style,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            labelText: labelText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding,
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
    );
  }
}
