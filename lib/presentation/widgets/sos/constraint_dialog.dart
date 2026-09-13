import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/sos_alert.dart';

/// Result of the "Petugas Terkendala" report dialog.
typedef ConstraintInput = ({String type, String reason});

/// Shows the "Petugas Terkendala" report dialog and returns the selected
/// constraint type plus the mandatory reason, or `null` if dismissed.
Future<ConstraintInput?> showConstraintDialog(
  BuildContext context, {
  String initialType = SosAlert.constraintDelayed,
  String? initialReason,
}) {
  return showDialog<ConstraintInput>(
    context: context,
    builder: (_) => _ConstraintDialog(
      initialType: initialType,
      initialReason: initialReason,
    ),
  );
}

class _ConstraintDialog extends StatefulWidget {
  const _ConstraintDialog({
    this.initialType = SosAlert.constraintDelayed,
    this.initialReason,
  });

  final String initialType;
  final String? initialReason;

  @override
  State<_ConstraintDialog> createState() => _ConstraintDialogState();
}

class _ConstraintDialogState extends State<_ConstraintDialog> {
  late String _type;
  late final TextEditingController _reason;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _reason = TextEditingController(text: widget.initialReason);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Alasan wajib diisi.');
      return;
    }
    Navigator.of(context).pop((type: _type, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Petugas Terkendala'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih alasan mengapa Anda belum bisa tiba di lokasi, '
              'kemudian tuliskan alasannya.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _option(
              SosAlert.constraintCannotReach,
              'Tidak bisa mencapai lokasi',
              Icons.block,
            ),
            _option(
              SosAlert.constraintDelayed,
              'Terlambat / terkendala di perjalanan',
              Icons.schedule_outlined,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Alasan',
                hintText: 'Contoh: jalan tertutup longsor, kendaraan rusak, …',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Laporkan'),
        ),
      ],
    );
  }

  Widget _option(String value, String label, IconData icon) {
    final selected = _type == value;
    final accent = AppColors.amber600;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: selected ? accent : AppColors.gray400,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      trailing: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected ? accent : AppColors.gray400,
      ),
      onTap: () => setState(() => _type = value),
    );
  }
}