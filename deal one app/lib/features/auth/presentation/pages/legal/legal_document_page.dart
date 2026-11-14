import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/auth_session.dart';
import '../../theme/auth_design_tokens.dart';

/// Displays Deal One Terms of Service or Privacy Policy inside the auth flow.
class LegalDocumentPage extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalDocumentPage({super.key, required this.documentType});

  String get _title => documentType == LegalDocumentType.termsOfService
      ? 'شروط الاستخدام'
      : 'سياسة الخصوصية';

  List<_LegalSection> get _sections =>
      documentType == LegalDocumentType.termsOfService
      ? const [
          _LegalSection(
            heading: '1. استخدام منصة ديل ون',
            body: 'تلتزم عند استخدام منصة ديل ون بنشر إعلانات حقيقية ومطابقة للقوانين المعمول بها في جمهورية مصر العربية، وعدم انتحال شخصية أو تقديم معلومات مضللة.',
          ),
          _LegalSection(
            heading: '2. الحساب والتحقق برقم الهاتف',
            body: 'يتم توثيق الحسابات برقم موبايل مصري فعّال عبر رمز تحقق لمرة واحدة (OTP). أنت مسؤول عن سرية جلسة الدخول وعدم مشاركة رموز التحقق مع أي طرف.',
          ),
          _LegalSection(
            heading: '3. التعاملات بين المستخدمين',
            body: 'ديل ون منصة وساطة وعرض إعلانات بين البائعين والمشترين. يرجى المعاينة الدقيقة والتأكد من مستندات الملكية قبل إتمام أي معاملة مالية.',
          ),
        ]
      : const [
          _LegalSection(
            heading: '1. البيانات التي نجمعها',
            body: 'نجمع فقط الاسم الكامل ورقم الهاتف المصري وبيانات الإعلانات التي تضيفها لتفعيل حسابك وتمكين التواصل الموثوق داخل التطبيق.',
          ),
          _LegalSection(
            heading: '2. أمان الرموز والجلسات',
            body: 'تُحفظ رموز الجلسة (JWT Access & Refresh Tokens) داخل التخزين المشفر على جهازك ولا تتم مشاركتها مع أي جهات خارجية لأغراض تسويقية.',
          ),
          _LegalSection(
            heading: '3. حقوقك في الحساب',
            body: 'يمكنك تعديل اسمك، تسجيل الخروج من جميع الجلسات، أو طلب حذف حسابك في أي وقت عبر إعدادات الحساب أو بالتواصل مع الدعم الفني.',
          ),
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AuthDesignTokens.backgroundOf(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          _title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AuthDesignTokens.headingOf(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthDesignTokens.maxContentWidth,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(AuthDesignTokens.horizontalPadding),
              itemCount: _sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final section = _sections[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AuthDesignTokens.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AuthDesignTokens.borderOf(context),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.heading,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AuthDesignTokens.headingOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.65,
                          color: AuthDesignTokens.bodyOf(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection({required this.heading, required this.body});
}
