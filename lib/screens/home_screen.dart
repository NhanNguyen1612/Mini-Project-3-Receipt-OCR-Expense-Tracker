import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models/expense.dart';
import '../services/receipt_service.dart';
import '../state/expenses_controller.dart';
import '../core/formatters.dart';
import '../widgets/expense_card.dart';
import 'camera_scan_screen.dart';
import 'reports_screen.dart';
import 'review_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  bool _scanning = false;

  Future<void> _scanGallery() async {
    setState(() => _scanning = true);
    try {
      final scan =
          await ref.read(receiptServiceProvider).scan(ImageSource.gallery);
      if (!mounted || scan == null) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(scan: scan),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể nhận dạng ảnh: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _openCamera() async {
    final scan = await Navigator.of(context).push<ReceiptScan>(
      MaterialPageRoute(builder: (_) => const CameraScanScreen()),
    );
    if (!mounted || scan == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReviewScreen(scan: scan),
    ));
  }

  Future<void> _showAddOptions() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp hóa đơn'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Nhập thủ công'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (selected == 'manual') {
      await Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => const ReviewScreen()));
    } else if (selected == 'camera') {
      await _openCamera();
    } else if (selected == 'gallery') {
      await _scanGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Chi tiêu của tôi' : 'Thống kê'),
        actions: [
          IconButton(
            tooltip: 'Đổi giao diện sáng/tối',
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
        ],
      ),
      body: SafeArea(
        child: _tab == 0
            ? expenses.when(
                data: (items) => _expensesBody(items),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Không thể tải dữ liệu: $error'),
                    TextButton(
                      onPressed: () => ref.invalidate(expensesProvider),
                      child: const Text('Thử lại'),
                    ),
                  ]),
                ),
              )
            : const ReportsScreen(),
      ),
      floatingActionButton: _tab == 1
          ? null
          : _scanning
              ? const FloatingActionButton(
                  onPressed: null, child: CircularProgressIndicator())
              : FloatingActionButton.extended(
                  onPressed: _showAddOptions,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Thêm chi tiêu'),
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.receipt_long), label: 'Chi tiêu'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Báo cáo'),
        ],
      ),
    );
  }

  Widget _expensesBody(List<Expense> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined, size: 72),
            SizedBox(height: 16),
            Text('Chưa có khoản chi nào', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('Nhấn “Thêm chi tiêu” để quét hóa đơn hoặc nhập thủ công.',
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    final now = DateTime.now();
    final monthItems = items.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    final monthlyTotal = monthItems.fold<int>(0, (sum, e) => sum + e.amount);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(expensesProvider);
        await ref.read(expensesProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng chi tháng ${now.month}/${now.year}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(formatDong(monthlyTotal),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => ExpenseCard(
              expense: items[index],
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ReviewScreen(expense: items[index]),
                  )),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
