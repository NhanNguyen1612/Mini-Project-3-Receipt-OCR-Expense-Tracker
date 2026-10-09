import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/receipt_service.dart';
import '../services/category_classifier.dart';
import '../state/expenses_controller.dart';
import '../core/formatters.dart';
import '../core/app_theme.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.scan, this.expense});

  final ReceiptScan? scan;
  final Expense? expense;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late DateTime _date;
  late ExpenseCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(
      text: widget.expense?.merchant ?? widget.scan?.parsed.merchant ?? '',
    );
    _amount = TextEditingController(
      text:
          (widget.expense?.amount ?? widget.scan?.parsed.amount)?.toString() ??
              '',
    );
    _date = widget.expense?.date ?? widget.scan?.parsed.date ?? DateTime.now();
    _category = widget.expense?.category ??
        const CategoryClassifier().classify(widget.scan?.parsed.rawText ?? '');
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  int? _parseAmount(String input) {
    final raw =
        input.trim().replaceAll(RegExp(r'[\sđ₫]', caseSensitive: false), '');
    if (RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(raw)) {
      return int.tryParse(raw.replaceAll(RegExp(r'[.,]'), ''));
    }
    return int.tryParse(raw);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    String? newPhoto;
    try {
      if (widget.scan != null) {
        newPhoto = await ref
            .read(receiptServiceProvider)
            .retainPhoto(widget.scan!.image);
      }
      final expense = Expense(
        id: widget.expense?.id,
        merchant: _merchant.text.trim(),
        amount: _parseAmount(_amount.text)!,
        date: _date,
        category: _category,
        photoPath: newPhoto ?? widget.expense?.photoPath,
        rawText: widget.scan?.parsed.rawText ?? widget.expense?.rawText,
      );
      if (widget.expense == null) {
        await ref.read(expensesProvider.notifier).add(expense);
      } else {
        await ref.read(expensesProvider.notifier).edit(expense);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (newPhoto != null) {
        await ref.read(receiptServiceProvider).deletePhoto(newPhoto);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu chi tiêu: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khoản chi?'),
        content: const Text('Khoản chi và ảnh hóa đơn đã lưu sẽ bị xóa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(expensesProvider.notifier).remove(widget.expense!);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.scan?.image.path ?? widget.expense?.photoPath;
    final rawText = widget.scan?.parsed.rawText ?? widget.expense?.rawText;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.expense == null ? 'Xác nhận chi tiêu' : 'Sửa giao dịch'),
        actions: widget.expense == null
            ? null
            : [
                IconButton(
                  tooltip: 'Xóa khoản chi',
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                )
              ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.scan != null
                        ? [AppPalette.coral, const Color(0xFFFF9A73)]
                        : [AppPalette.deepForest, AppPalette.forest],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(children: [
                  Container(
                    width: 51,
                    height: 51,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                        widget.scan != null
                            ? Icons.auto_awesome_rounded
                            : Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 27),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.scan != null
                              ? 'OCR ĐÃ SẴN SÀNG'
                              : widget.expense != null
                                  ? 'CẬP NHẬT GIAO DỊCH'
                                  : 'KHOẢN CHI MỚI',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1)),
                      const SizedBox(height: 5),
                      const Text('Kiểm tra trước khi lưu',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 24),
              if (widget.scan != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.mint.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome_outlined,
                        color: AppPalette.deepForest, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      'OCR cục bộ: ${widget.scan!.recognitionMs} ms. Hãy kiểm tra và sửa trước khi lưu.',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w700),
                    )),
                  ]),
                ),
              if (imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imagePath),
                    height: 178,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 100,
                      child: Center(child: Text('Không thể mở ảnh hóa đơn')),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              Text('01  /  THÔNG TIN GIAO DỊCH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merchant,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cửa hàng / nội dung',
                  prefixIcon: Icon(Icons.storefront),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên cửa hàng hoặc nội dung'
                    : null,
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VND)',
                  hintText: 'Ví dụ: 65000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  return amount == null || amount <= 0
                      ? 'Nhập số tiền hợp lệ'
                      : null;
                },
              ),
              const SizedBox(height: 13),
              Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 17),
                    child: Row(children: [
                      Icon(Icons.calendar_month_outlined,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 13),
                      Expanded(
                          child: Text('Ngày · ${formatDate(_date)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const SizedBox(height: 9),
              Text('02  /  DANH MỤC',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: ExpenseCategory.values
                    .map((category) => ChoiceChip(
                          label: Text(category.label),
                          selected: _category == category,
                          selectedColor: AppPalette.mint,
                          labelStyle: TextStyle(
                            color: _category == category
                                ? AppPalette.ink
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ))
                    .toList(),
              ),
              if (rawText != null && rawText.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  collapsedBackgroundColor:
                      Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  leading: const Icon(Icons.notes_rounded),
                  title: const Text('Văn bản OCR gốc'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(rawText),
                    )
                  ],
                ),
              ],
              const SizedBox(height: 27),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.forest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_saving ? 'Đang lưu...' : 'Xác nhận và lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
