/// How a form field is rendered.
enum FormFieldType {
  text,
  email,
  multiline,
  number,
  decimal,
  dropdown,
  bool,
  multiSelect,
}

/// A single selectable choice for [FormFieldType.dropdown]/[multiSelect].
class FormOption {
  const FormOption(this.value, this.label);

  final dynamic value;
  final String label;
}

/// Declarative definition of one field shown in a CRUD form.
class FormFieldSpec {
  const FormFieldSpec({
    required this.key,
    required this.label,
    this.type = FormFieldType.text,
    this.required = false,
    this.options,
    this.hint,
    this.suffix,
    this.emptyLabel = '– Pilih –',
  });

  /// Request-body field name.
  final String key;

  final String label;
  final FormFieldType type;
  final bool required;

  /// Choices for [FormFieldType.dropdown] and [FormFieldType.multiSelect].
  final List<FormOption>? options;

  final String? hint;
  final String? suffix;
  final String emptyLabel;

  String? validateInput(String? value) {
    if (required && (value == null || value.trim().isEmpty)) {
      return '$label wajib diisi';
    }
    if ((value == null || value.trim().isEmpty)) return null;
    switch (type) {
      case FormFieldType.email:
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
          return 'Format email tidak valid';
        }
        return null;
      case FormFieldType.number:
        if (int.tryParse(value.trim()) == null) return 'Harus berupa angka';
        return null;
      case FormFieldType.decimal:
        if (double.tryParse(value.trim()) == null) return 'Harus berupa angka';
        return null;
      default:
        return null;
    }
  }
}
