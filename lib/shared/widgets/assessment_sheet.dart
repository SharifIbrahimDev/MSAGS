// lib/shared/widgets/assessment_sheet.dart
//
// One-page "ASSESSMENT OF STUDENTS" table that mirrors the KASU SIWES
// logbook (page 64): S/No | Description/Item Reference | Max. Score |
// Actual Score | Remarks. Each row is either editable (for the current
// role) or locked (belongs to the other role).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AssessmentRow {
  final String description;
  final double max;

  /// Current value. `null` = not available / hidden from this role.
  final double? value;

  /// Whether the current user may type into this row.
  final bool editable;

  /// Label shown in locked rows, e.g. "Assessor" / "Supervisor".
  final String? ownerLabel;

  final ValueChanged<double>? onChanged;

  const AssessmentRow({
    required this.description,
    required this.max,
    this.value,
    this.editable = false,
    this.ownerLabel,
    this.onChanged,
  });
}

class AssessmentSheet extends StatelessWidget {
  final List<AssessmentRow> rows;
  final Color accent;
  final bool locked;

  const AssessmentSheet({
    super.key,
    required this.rows,
    required this.accent,
    this.locked = false,
  });

  static const _border = BorderSide(color: Color(0xFF374151), width: 1);

  static String remarkFor(double value, double max) {
    if (max <= 0) return '';
    final p = value / max * 100;
    if (p >= 70) return 'Excellent';
    if (p >= 60) return 'Very Good';
    if (p >= 50) return 'Good';
    if (p >= 45) return 'Fair';
    if (p >= 40) return 'Pass';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF111827));
    final cellStyle =
        GoogleFonts.inter(fontSize: 12, color: const Color(0xFF111827));

    final known = rows.where((r) => r.value != null);
    final totalKnown = known.fold<double>(0, (s, r) => s + r.value!);
    final allKnown = known.length == rows.length;

    Widget cell(Widget child, {Alignment align = Alignment.centerLeft, Color? bg}) =>
        Container(
          color: bg,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          alignment: align,
          child: child,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ASSESSMENT OF STUDENTS',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Table(
            border: const TableBorder(
              top: _border,
              bottom: _border,
              left: _border,
              right: _border,
              horizontalInside: _border,
              verticalInside: _border,
            ),
            columnWidths: const {
              0: FixedColumnWidth(34),
              1: FlexColumnWidth(3.2),
              2: FlexColumnWidth(1.4),
              3: FlexColumnWidth(1.9),
              4: FlexColumnWidth(2.0),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.08)),
                children: [
                  cell(Text('S/No.', style: headerStyle), align: Alignment.center),
                  cell(Text('Description/Item Reference', style: headerStyle)),
                  cell(Text('Max. Score', style: headerStyle),
                      align: Alignment.center),
                  cell(Text('Actual Score', style: headerStyle),
                      align: Alignment.center),
                  cell(Text('Remarks', style: headerStyle),
                      align: Alignment.center),
                ],
              ),
              for (var i = 0; i < rows.length; i++)
                _buildRow(i, rows[i], cell, cellStyle),
              TableRow(
                children: [
                  cell(const SizedBox()),
                  cell(Text('TOTAL', style: headerStyle)),
                  cell(Text('100%', style: headerStyle),
                      align: Alignment.center),
                  cell(
                    Text(
                      known.isEmpty ? '' : _fmt(totalKnown),
                      style: headerStyle.copyWith(fontSize: 14, color: accent),
                    ),
                    align: Alignment.center,
                  ),
                  cell(
                    Text(allKnown ? remarkFor(totalKnown, 100) : '',
                        style: cellStyle),
                    align: Alignment.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildRow(int i, AssessmentRow r,
      Widget Function(Widget, {Alignment align, Color? bg}) cell, TextStyle style) {
    final canEdit = r.editable && !locked;
    final bg = r.editable ? null : const Color(0xFFF3F4F6);

    Widget actual;
    if (r.editable) {
      actual = _ScoreInput(
        value: r.value ?? 0,
        max: r.max,
        enabled: canEdit,
        accent: accent,
        onChanged: r.onChanged,
      );
    } else if (r.value != null) {
      actual = Text(_fmt(r.value!), style: style.copyWith(fontWeight: FontWeight.w600));
    } else {
      actual = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 2),
          Flexible(
            child: Text(r.ownerLabel ?? '',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
          ),
        ],
      );
    }

    return TableRow(
      children: [
        cell(Text('${i + 1}', style: style), align: Alignment.center, bg: bg),
        cell(
          Text(r.description,
              style: style.copyWith(
                  color: r.editable ? const Color(0xFF111827) : Colors.grey[600])),
          bg: bg,
        ),
        cell(Text(_fmt(r.max), style: style), align: Alignment.center, bg: bg),
        cell(actual, align: Alignment.center, bg: bg),
        cell(
          Text(
            r.value != null && (r.value! > 0 || !r.editable)
                ? remarkFor(r.value!, r.max)
                : '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700]),
          ),
          align: Alignment.center,
          bg: bg,
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// Numeric input that never accepts a value above [max].
class _ScoreInput extends StatefulWidget {
  final double value;
  final double max;
  final bool enabled;
  final Color accent;
  final ValueChanged<double>? onChanged;

  const _ScoreInput({
    required this.value,
    required this.max,
    required this.enabled,
    required this.accent,
    this.onChanged,
  });

  @override
  State<_ScoreInput> createState() => _ScoreInputState();
}

class _ScoreInputState extends State<_ScoreInput> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _text(widget.value));
  }

  @override
  void didUpdateWidget(covariant _ScoreInput old) {
    super.didUpdateWidget(old);
    // Sync when the value is changed externally (e.g. pre-populated from DB).
    if (!_focus.hasFocus) {
      final parsed = double.tryParse(_ctrl.text) ?? 0;
      if (parsed != widget.value) _ctrl.text = _text(widget.value);
    }
  }

  String _text(double v) => v == 0
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?')),
          TextInputFormatter.withFunction((oldV, newV) {
            if (newV.text.isEmpty) return newV;
            final v = double.tryParse(newV.text);
            if (v == null || v > widget.max) return oldV;
            return newV;
          }),
        ],
        style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: widget.accent),
        decoration: InputDecoration(
          hintText: '0',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          filled: true,
          fillColor: widget.enabled
              ? widget.accent.withValues(alpha: 0.06)
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: widget.accent.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: widget.accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: widget.accent, width: 2),
          ),
        ),
        onChanged: (t) => widget.onChanged?.call(double.tryParse(t) ?? 0),
      ),
    );
  }
}
