import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';

/// Displays Deal One Terms of Service or Privacy Policy inside the auth flow.
class LegalDocumentPage extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalDocumentPage({super.key, required this.documentType});

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final title = documentType == LegalDocumentType.termsOfService
        ? l10n.legalTermsTitle
        : l10n.legalPrivacyTitle;

    final sections = documentType == LegalDocumentType.termsOfService
        ? [
            _LegalSection(
              heading: l10n.legalTermsSection1Title,
              body: l10n.legalTermsSection1Body,
            ),
            _LegalSection(
              heading: l10n.legalTermsSection2Title,
              body: l10n.legalTermsSection2Body,
            ),
            _LegalSection(
              heading: l10n.legalTermsSection3Title,
              body: l10n.legalTermsSection3Body,
            ),
          ]
        : [
            _LegalSection(
              heading: l10n.legalPrivacySection1Title,
              body: l10n.legalPrivacySection1Body,
            ),
            _LegalSection(
              heading: l10n.legalPrivacySection2Title,
              body: l10n.legalPrivacySection2Body,
            ),
            _LegalSection(
              heading: l10n.legalPrivacySection3Title,
              body: l10n.legalPrivacySection3Body,
            ),
          ];

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
          title,
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
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final section = sections[index];
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
