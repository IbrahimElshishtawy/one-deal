import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

class SellerCrmTab extends ConsumerWidget {
  const SellerCrmTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final selectedStatus = ref.watch(sellerDealsStatusFilterProvider);
    final dealsAsync = ref.watch(sellerDealsProvider);

    return Column(
      children: [
        // V1 CRM Disclaimer Banner (No fake payment/order transactions)
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: AppRadii.md,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? 'سجل المبيعات (CRM) يُدار يدوياً بواسطة البائع ولا يُعد معاملة مالية موثقة عبر المنصة.'
                      : 'Sales CRM records are seller-managed and are not independently verified platform payment transactions.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status Filter + Add Deal button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: Text(isArabic ? 'الكل' : 'All'),
                        selected: selectedStatus == null,
                        onSelected: (_) => ref
                            .read(sellerDealsStatusFilterProvider.notifier)
                            .state = null,
                      ),
                      const SizedBox(width: 6),
                      ...SellerDealStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: ChoiceChip(
                            label: Text(s.label(isArabic: isArabic)),
                            selected: selectedStatus == s,
                            onSelected: (_) => ref
                                .read(sellerDealsStatusFilterProvider.notifier)
                                .state = s,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _openCreateDealSheet(context, ref, isArabic),
                icon: const Icon(Icons.add_rounded),
                tooltip: isArabic ? 'إضافة سجل بيع' : 'Add CRM Deal',
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: DealOneTokens.navy,
            onRefresh: () async => ref.invalidate(sellerDealsProvider),
            child: dealsAsync.when(
              loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
              error: (err, _) => DealOneErrorStateView(
                error: err,
                onRetry: () => ref.invalidate(sellerDealsProvider),
              ),
              data: (deals) {
                if (deals.isEmpty) {
                  return DealOneEmptyStateView(
                    icon: Icons.handshake_outlined,
                    title: isArabic ? 'لا توجد سجلات مبيعات' : 'No CRM Deals Yet',
                    description: isArabic
                        ? 'تتبع استفسارات العملاء ومراحل التفاوض والصفقات المكتملة هنا.'
                        : 'Track customer leads, negotiations, and seller-reported completed deals here.',
                    actionLabel: isArabic ? 'إضافة سجل جديد' : 'Add Sales Deal',
                    actionIcon: Icons.add_rounded,
                    onAction: () =>
                        _openCreateDealSheet(context, ref, isArabic),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: deals.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: DealOneTokens.cardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  deal.listingTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: DealOneTokens.navy
                                      .withValues(alpha: 0.1),
                                  borderRadius: AppRadii.full,
                                ),
                                child: Text(
                                  deal.status.label(isArabic: isArabic),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${isArabic ? 'العميل:' : 'Customer:'} ${deal.customerName}${deal.customerReference != null ? ' (${deal.customerReference})' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isArabic ? 'السعر المعلن:' : 'Initial:'} ${deal.initialPrice.toStringAsFixed(0)} ${deal.currency}'
                            '${deal.agreedPrice != null ? ' • ${isArabic ? 'المتفق عليه:' : 'Agreed:'} ${deal.agreedPrice!.toStringAsFixed(0)} ${deal.currency}' : ''}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          if (deal.notes != null && deal.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              deal.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openUpdateDealSheet(
                                    context,
                                    ref,
                                    deal,
                                    isArabic,
                                  ),
                                  child: Text(
                                    isArabic ? 'تحديث الحالة' : 'Update Status',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _confirmDeleteDeal(
                                  context,
                                  ref,
                                  deal,
                                  isArabic,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: DealOneTokens.dangerRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateDealSheet(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
  ) async {
    final listings =
        (await ref.read(sellerCenterListingsProvider.future)).items;
    if (!context.mounted) return;
    if (listings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'أضف إعلاناً أولاً لإنشاء سجل بيع مرتبط به.'
                : 'Create an advertisement first before logging a CRM deal.',
          ),
        ),
      );
      return;
    }

    String selectedListingId = listings.first.id;
    SellerDealStatus selectedStatus = SellerDealStatus.newInquiry;
    final customerCtrl = TextEditingController();
    final agreedPriceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isArabic ? 'إضافة سجل بيع (CRM)' : 'New Sales CRM Deal',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedListingId,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الإعلان المرتبط' : 'Advertisement',
                  ),
                  items: listings
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.title, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedListingId = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: customerCtrl,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم العميل *' : 'Customer Name *',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<SellerDealStatus>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الحالة' : 'Status',
                  ),
                  items: SellerDealStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label(isArabic: isArabic)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedStatus = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: agreedPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'السعر المتفق عليه (اختياري)'
                        : 'Agreed Price (Optional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'ملاحظات البائع' : 'Seller Notes',
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DealOneTokens.navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (customerCtrl.text.trim().isEmpty) return;
                    await ref.read(sellerCenterRepositoryProvider).createDeal(
                          listingId: selectedListingId,
                          customerName: customerCtrl.text.trim(),
                          agreedPrice:
                              double.tryParse(agreedPriceCtrl.text.trim()),
                          status: selectedStatus,
                          notes: notesCtrl.text.trim(),
                        );
                    ref.invalidate(sellerDealsProvider);
                    ref.invalidate(sellerDashboardProvider);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(isArabic ? 'حفظ السجل' : 'Save Deal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUpdateDealSheet(
    BuildContext context,
    WidgetRef ref,
    SellerDealEntity deal,
    bool isArabic,
  ) async {
    SellerDealStatus status = deal.status;
    final priceCtrl = TextEditingController(
      text: deal.agreedPrice?.toStringAsFixed(0) ?? '',
    );
    final notesCtrl = TextEditingController(text: deal.notes ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic ? 'تحديث سجل البيع' : 'Update Sales Record',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SellerDealStatus>(
                initialValue: status,
                items: SellerDealStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label(isArabic: isArabic)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => status = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      isArabic ? 'السعر المتفق عليه' : 'Agreed Price',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isArabic ? 'ملاحظات' : 'Notes',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await ref.read(sellerCenterRepositoryProvider).updateDeal(
                        deal.id,
                        status: status,
                        agreedPrice: double.tryParse(priceCtrl.text.trim()),
                        notes: notesCtrl.text.trim(),
                      );
                  ref.invalidate(sellerDealsProvider);
                  ref.invalidate(sellerDashboardProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(isArabic ? 'حفظ التحديث' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDeal(
    BuildContext context,
    WidgetRef ref,
    SellerDealEntity deal,
    bool isArabic,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'حذف سجل البيع' : 'Delete Sales Record'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف سجل "${deal.customerName}"؟'
              : 'Delete CRM record for "${deal.customerName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sellerCenterRepositoryProvider).deleteDeal(deal.id);
      ref.invalidate(sellerDealsProvider);
      ref.invalidate(sellerDashboardProvider);
    }
  }
}
