import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/receipt_service.dart';
import '../services/category_classifier.dart';
import '../state/expenses_controller.dart';
import '../core/formatters.dart';

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
        title:
            Text(widget.expense == null ? 'Kiểm tra hóa đơn' : 'Sửa khoản chi'),
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
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.scan != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                      'OCR có thể đọc sai. Hãy kiểm tra và sửa trước khi lưu.'),
                ),
              if (imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath),
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 100,
                      child: Center(child: Text('Không thể mở ảnh hóa đơn')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _merchant,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cửa hàng / nội dung',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên cửa hàng hoặc nội dung'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VND)',
                  hintText: 'Ví dụ: 65000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  return amount == null || amount <= 0
                      ? 'Nhập số tiền hợp lệ'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Ngày: ${formatDate(_date)}'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                ),
                items: ExpenseCategory.values
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              if (rawText != null && rawText.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Văn bản OCR gốc'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(rawText),
                    )
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu khoản chi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
