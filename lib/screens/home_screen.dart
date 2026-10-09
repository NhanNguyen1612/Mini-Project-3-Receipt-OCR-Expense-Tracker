import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../core/app_theme.dart';
import '../models/expense.dart';
import '../services/receipt_service.dart';
import '../state/expenses_controller.dart';
import '../core/formatters.dart';
import '../models/time_filter.dart';
import '../state/time_filter_controller.dart';
import '../widgets/expense_card.dart';
import '../widgets/time_filter_bar.dart';
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
        toolbarHeight: 76,
        title: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppPalette.coral,
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 23),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tab == 0 ? 'Sổ chi tiêu' : 'Báo cáo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, letterSpacing: -0.8)),
            Text('VKU  /  EXPENSE STUDIO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
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
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Đổi giao diện sáng/tối',
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
          const SizedBox(width: 6),
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
    final filter = ref.watch(timeFilterProvider);
    final filteredItems = filter.filter(items);
    final total = filter.total(items);
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
                      _summaryCard(filter, total, filteredItems.length),
                      const SizedBox(height: 14),
                      const TimeFilterBar(),
                      const SizedBox(height: 24),
                      _sectionHeading(
                          'Bắt đầu từ hóa đơn', 'Quét nhanh, kiểm tra rồi lưu'),
                      const SizedBox(height: 13),
                      _scanAction(),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: _smallAction(
                            icon: Icons.photo_library_outlined,
                            title: 'Thư viện',
                            subtitle: 'Chọn ảnh có sẵn',
                            accent: AppPalette.violet,
                            onTap: _scanning ? null : _scanGallery,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _smallAction(
                            icon: Icons.edit_note_rounded,
                            title: 'Nhập tay',
                            subtitle: 'Tạo khoản chi mới',
                            accent: AppPalette.teal,
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
                      const SizedBox(height: 28),
                      _sectionHeading(
                        filter.mode == TimeFilterMode.all
                            ? 'Tất cả giao dịch'
                            : 'Giao dịch trong kỳ',
                        '${filteredItems.length} khoản chi · chạm để chỉnh sửa',
                      ),
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
          else if (filteredItems.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 26),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(children: [
                        const Icon(Icons.filter_alt_off_outlined,
                            size: 38, color: AppPalette.coral),
                        const SizedBox(height: 10),
                        Text('Không có giao dịch trong kỳ này',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(
                          'Kỳ ${filter.displayTitle} chưa có khoản chi nào.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (filter.mode != TimeFilterMode.all) ...[
                          const SizedBox(height: 14),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.all_inclusive_rounded,
                                size: 18),
                            label: Text('Xem tất cả ${items.length} giao dịch'),
                            onPressed: () => ref
                                .read(timeFilterProvider.notifier)
                                .setMode(TimeFilterMode.all),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ExpenseCard(
                    expense: filteredItems[index],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ReviewScreen(expense: filteredItems[index]),
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

  Widget _summaryCard(TimeFilterState filter, int total, int count) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppPalette.deepForest, AppPalette.forest],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepForest.withValues(alpha: 0.24),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(children: [
          Positioned(
            right: -30,
            top: -65,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 42),
              ),
            ),
          ),
          const Positioned(
            right: 20,
            bottom: 24,
            child:
                Icon(Icons.auto_graph_rounded, color: Colors.white24, size: 86),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(filter.shortBadge.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 25),
                const Text('Tổng chi của bạn',
                    style: TextStyle(
                        color: Color(0xFFD5DFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatDong(total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2)),
                ),
                const SizedBox(height: 26),
                Row(children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: AppPalette.lime, size: 18),
                  const SizedBox(width: 8),
                  Text('$count giao dịch trong kỳ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
          ]),
        ),
      );

  Widget _scanAction() => Material(
        color: AppPalette.coral,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _scanning ? null : _openCamera,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    color: Colors.white, size: 29),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quét hóa đơn',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Camera + OCR ngay trên máy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ]),
          ),
        ),
      );

  Widget _smallAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback? onTap,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final visibleColor =
        dark ? Color.lerp(accent, Colors.white, 0.32)! : accent;
    return Material(
      color: dark
          ? Theme.of(context).colorScheme.surface
          : accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 16, 12, 15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: visibleColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: visibleColor, size: 21),
            ),
            const SizedBox(height: 13),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
