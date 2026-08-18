import 'package:flutter_test/flutter_test.dart';
import 'package:lupinusbuild/features/company/models/company_context.dart';

CompanyContext contextFor(String role) {
  return CompanyContext(
    companyId: 'company-1',
    companyName: 'MaxShade',
    userId: 'user-1',
    userEmail: 'user@example.com',
    role: role,
    status: 'active',
  );
}

void main() {
  const managementRoles = [
    'primary_admin',
    'cfo',
    'admin',
    'manager',
  ];

  const readOnlyRoles = [
    'field_user',
    'viewer',
  ];

  const allRoles = [
    ...managementRoles,
    ...readOnlyRoles,
  ];

  group('CompanyContext quote permissions', () {
    test('all active company roles can view quotes', () {
      for (final role in allRoles) {
        expect(
          contextFor(role).canViewQuotes,
          isTrue,
          reason: '$role should be able to view quotes',
        );
      }
    });

    test('management roles can create and edit quotes', () {
      for (final role in managementRoles) {
        final context = contextFor(role);

        expect(
          context.canCreateQuotes,
          isTrue,
          reason: '$role should be able to create quotes',
        );
        expect(
          context.canEditQuotes,
          isTrue,
          reason: '$role should be able to edit quotes',
        );
      }
    });

    test('field users and viewers cannot create or edit quotes', () {
      for (final role in readOnlyRoles) {
        final context = contextFor(role);

        expect(
          context.canCreateQuotes,
          isFalse,
          reason: '$role should not be able to create quotes',
        );
        expect(
          context.canEditQuotes,
          isFalse,
          reason: '$role should not be able to edit quotes',
        );
      }
    });

    test('only executive and admin roles can delete quotes', () {
      for (final role in ['primary_admin', 'cfo', 'admin']) {
        expect(
          contextFor(role).canDeleteQuotes,
          isTrue,
          reason: '$role should be able to delete quotes',
        );
      }

      for (final role in ['manager', ...readOnlyRoles]) {
        expect(
          contextFor(role).canDeleteQuotes,
          isFalse,
          reason: '$role should not be able to delete quotes',
        );
      }
    });

    test('status updates and project conversion follow edit permissions', () {
      for (final role in managementRoles) {
        final context = contextFor(role);

        expect(context.canUpdateQuoteStatus, isTrue);
        expect(context.canConvertQuoteToProject, isTrue);
      }

      for (final role in readOnlyRoles) {
        final context = contextFor(role);

        expect(context.canUpdateQuoteStatus, isFalse);
        expect(context.canConvertQuoteToProject, isFalse);
      }
    });
  });
}
