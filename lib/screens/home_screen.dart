import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../core/app_theme.dart';
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: colors.primary, borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.receipt_long_rounded,
                color: colors.onPrimary, size: 21),
          ),
          const SizedBox(width: 11),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tab == 0 ? 'Sổ chi tiêu' : 'Báo cáo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            Text('RECEIPTLY · VKU',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant)),
          ]),
        ]),
        actions: [
          if (_tab == 0)
            IconButton.filledTonal(
              tooltip: 'Thêm chi tiêu',
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add_rounded),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Đổi giao diện sáng/tối',
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
          const SizedBox(width: 10),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Chi tiêu'),
          NavigationDestination(
              icon: Icon(Icons.donut_small_outlined),
              selectedIcon: Icon(Icons.donut_large_rounded),
              label: 'Báo cáo'),
        ],
      ),
    );
  }

  Widget _expensesBody(List<Expense> items) {
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryCard(now, monthlyTotal, items.length),
                      const SizedBox(height: 27),
                      _sectionHeading('Thêm nhanh', 'Lưu một khoản chi mới'),
                      const SizedBox(height: 13),
                      Row(children: [
                        Expanded(
                          child: _quickAction(
                            icon: Icons.document_scanner_outlined,
                            label: 'Quét hóa đơn',
                            color: AppPalette.forest,
                            onTap: _scanning ? null : _openCamera,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.photo_library_outlined,
                            label: 'Thư viện',
                            color: const Color(0xFF6D65A7),
                            onTap: _scanning ? null : _scanGallery,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.edit_note_rounded,
                            label: 'Nhập tay',
                            color: const Color(0xFFB77838),
                            onTap: _scanning
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) => const ReviewScreen()),
                                    ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 29),
                      _sectionHeading('Giao dịch gần đây',
                          '${items.length} khoản chi đã lưu'),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _emptyState(),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ExpenseCard(
                    expense: items[index],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ReviewScreen(expense: items[index]),
                        )),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );

  Widget _summaryCard(DateTime now, int total, int count) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppPalette.deepForest, AppPalette.forest],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepForest.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(children: [
          Positioned(
            right: -48,
            top: -56,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 32),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppPalette.mint, size: 19),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('TỔNG CHI THÁNG NÀY',
                        style: TextStyle(
                            color: AppPalette.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('${now.month}/${now.year}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 22),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatDong(total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5)),
                ),
                const SizedBox(height: 17),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 15),
                Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppPalette.lime, size: 17),
                  const SizedBox(width: 8),
                  Text('$count giao dịch đã lưu',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ]),
      );

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final visibleColor = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, 0.42)!
        : color;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
          child: Column(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: visibleColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: visibleColor, size: 22),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(children: [
            const Icon(Icons.receipt_long_outlined,
                size: 42, color: AppPalette.forest),
            const SizedBox(height: 10),
            Text('Chưa có giao dịch',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Quét hóa đơn hoặc nhập khoản chi đầu tiên.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}
