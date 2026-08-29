import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/repositories/resource_api.dart';
import 'form_field_spec.dart';

/// A generic create/edit form driven by [FormFieldSpec] definitions.
///
/// Fields are seeded from [initial], submitted with [api.create]/[api.update],
/// and backend 422 validation errors are shown inline per field.
class ResourceFormScreen<T> extends StatefulWidget {
  const ResourceFormScreen({
    super.key,
    required this.title,
    required this.api,
    required this.fields,
    this.initial,
    this.editId,
  });

  final String title;
  final ResourceApi<T> api;
  final List<FormFieldSpec> fields;
  final Map<String, dynamic>? initial;
  final int? editId;

  @override
  State<ResourceFormScreen<T>> createState() => _ResourceFormScreenState<T>();
}

class _ResourceFormScreenState<T> extends State<ResourceFormScreen<T>> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  final Map<String, dynamic> _selectedValues = {};
  final Map<String, String?> _serverErrors = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final field in widget.fields) {
      final seed = widget.initial?[field.key];
      _controllers[field.key] = TextEditingController(
        text: _seedAsString(field, seed),
      );
      if (field.type == FormFieldType.dropdown ||
          field.type == FormFieldType.multiSelect) {
        _selectedValues[field.key] = seed;
      }
    }
  }

  String _seedAsString(FormFieldSpec field, dynamic seed) {
    if (seed == null) return '';
    switch (field.type) {
      case FormFieldType.number:
      case FormFieldType.decimal:
        return seed.toString();
      case FormFieldType.bool:
        return (seed == true) ? 'true' : '';
      default:
        return seed.toString();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setDropdown(FormFieldSpec field, dynamic value) {
    setState(() => _selectedValues[field.key] = value);
  }

  dynamic _buildValue(FormFieldSpec field) {
    if (field.type == FormFieldType.dropdown ||
        field.type == FormFieldType.multiSelect) {
      final v = _selectedValues[field.key];
      if (v == null || (v is List && v.isEmpty)) {
        return field.required ? null : null;
      }
      return v;
    }
    if (field.type == FormFieldType.bool) {
      final c = _controllers[field.key]!;
      return c.text == 'true';
    }
    final raw = _controllers[field.key]!.text.trim();
    if (raw.isEmpty) return null;
    switch (field.type) {
      case FormFieldType.number:
        return int.tryParse(raw);
      case FormFieldType.decimal:
        return double.tryParse(raw);
      default:
        return raw;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final data = <String, dynamic>{};
    for (final field in widget.fields) {
      final value = _buildValue(field);
      if (value != null || field.required) {
        data[field.key] = value;
      }
    }

    try {
      if (widget.editId == null) {
        await widget.api.create(data);
      } else {
        await widget.api.update(widget.editId!, data);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors.clear();
        e.errors?.forEach((k, v) {
          if (v is List && v.isNotEmpty) _serverErrors[k] = v.first.toString();
        });
      });
      if (_serverErrors.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan jaringan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final field in widget.fields) ...[
                _Field(
                  spec: field,
                  controller: _controllers[field.key]!,
                  serverError: _serverErrors[field.key],
                  onDropdown: (v) => _setDropdown(field, v),
                  selectedValue: _selectedValues[field.key],
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.spec,
    required this.controller,
    required this.onDropdown,
    this.serverError,
    this.selectedValue,
  });

  final FormFieldSpec spec;
  final TextEditingController controller;
  final ValueChanged<dynamic> onDropdown;
  final String? serverError;
  final dynamic selectedValue;

  String? _combinedError(String? client) {
    if (serverError != null && serverError!.isNotEmpty) return serverError;
    return client;
  }

  @override
  Widget build(BuildContext context) {
    final errorText = serverError;

    switch (spec.type) {
      case FormFieldType.dropdown:
      case FormFieldType.multiSelect:
        return _buildDropdown(context, errorText);
      case FormFieldType.bool:
        return _buildSwitch(context);
      case FormFieldType.multiline:
        return TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: spec.label,
            hintText: spec.hint,
            errorText: _combinedError(errorText),
          ),
        );
      default:
        final keyboardType = switch (spec.type) {
          FormFieldType.number => TextInputType.number,
          FormFieldType.decimal => const TextInputType.numberWithOptions(
            decimal: true,
          ),
          FormFieldType.email => TextInputType.emailAddress,
          _ => TextInputType.text,
        };
        return TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: spec.label,
            hintText: spec.hint,
            suffixText: spec.suffix,
            prefixIcon: spec.type == FormFieldType.email
                ? const Icon(Icons.mail_outline)
                : null,
            errorText: _combinedError(errorText),
          ),
          validator: spec.validateInput,
        );
    }
  }

  Widget _buildSwitch(BuildContext context) {
    final on = controller.text == 'true';
    return SwitchListTile(
      title: Text(spec.label),
      value: on,
      onChanged: (v) {
        controller.text = v ? 'true' : '';
        onDropdown(v);
      },
    );
  }

  Widget _buildDropdown(BuildContext context, String? errorText) {
    final options = spec.options ?? const <FormOption>[];
    if (spec.type == FormFieldType.multiSelect) {
      final selected = selectedValue is List
          ? (selectedValue as List).cast<dynamic>()
          : <dynamic>[];
      final label = options
          .where((o) => selected.contains(o.value))
          .map((o) => o.label)
          .join(', ');
      return InputDecorator(
        decoration: InputDecoration(
          labelText: spec.label,
          errorText: _combinedError(errorText),
        ),
        child: InkWell(
          onTap: () => _showMultiSelect(context, options, selected),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label.isEmpty ? spec.emptyLabel : label,
              style: TextStyle(
                color: label.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }
    final current = selectedValue == null
        ? null
        : options.indexWhere((o) => o.value == selectedValue);
    final initial = (current == null || current == -1)
        ? null
        : options[current].value;
    return DropdownButtonFormField<dynamic>(
      initialValue: initial,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: spec.label,
        errorText: _combinedError(errorText),
      ),
      hint: Text(spec.emptyLabel),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o.value, child: Text(o.label)),
      ],
      validator: spec.required
          ? (v) => v == null ? '${spec.label} wajib diisi' : null
          : null,
      onChanged: onDropdown,
    );
  }

  Future<void> _showMultiSelect(
    BuildContext context,
    List<FormOption> options,
    List<dynamic> current,
  ) async {
    final selected = List<dynamic>.of(current);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(spec.label),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final o in options)
                  CheckboxListTile(
                    title: Text(o.label),
                    value: selected.contains(o.value),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        selected.add(o.value);
                      } else {
                        selected.remove(o.value);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      onDropdown(selected);
    }
  }
}
