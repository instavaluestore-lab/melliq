import 'package:flutter_test/flutter_test.dart';
import 'package:lupinusbuild/features/company/models/company_context.dart';
import 'package:lupinusbuild/features/projects/models/company_task.dart';

CompanyContext contextForRole(String role) {
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
  group('Company Task Center permissions', () {
    test('primary admin CFO and admin can view all company tasks', () {
      expect(contextForRole('primary_admin').canViewCompanyTasks, isTrue);
      expect(contextForRole('cfo').canViewCompanyTasks, isTrue);
      expect(contextForRole('admin').canViewCompanyTasks, isTrue);
    });

    test('manager field user and viewer cannot view all company tasks', () {
      expect(contextForRole('manager').canViewCompanyTasks, isFalse);
      expect(contextForRole('field_user').canViewCompanyTasks, isFalse);
      expect(contextForRole('viewer').canViewCompanyTasks, isFalse);
    });
  });

  group('CompanyTask', () {
    test('parses project and assignee information', () {
      final task = CompanyTask.fromMap({
        'id': 'task-1',
        'company_id': 'company-1',
        'project_id': 'project-1',
        'title': 'Confirm site measurements',
        'description': 'Verify project dimensions.',
        'status': 'todo',
        'priority': 'high',
        'assigned_to': 'user-1',
        'created_by': 'admin-1',
        'due_date': '2026-08-20',
        'completed_at': null,
        'created_at': '2026-08-18T01:00:00.000000+00:00',
        'updated_at': '2026-08-18T02:00:00.000000+00:00',
        'projects': {
          'project_number': 'P-TEST-001',
          'name': 'Test Shade Project',
        },
        'profiles': {
          'full_name': 'Field User',
          'email': 'field@test.maxshade.com',
        },
      });

      expect(task.task.title, 'Confirm site measurements');
      expect(task.projectNumber, 'P-TEST-001');
      expect(task.projectName, 'Test Shade Project');
      expect(task.assigneeLabel, 'Field User');
    });

    test('uses Unassigned when no assignee profile exists', () {
      final task = CompanyTask.fromMap({
        'id': 'task-2',
        'company_id': 'company-1',
        'project_id': 'project-1',
        'title': 'Order materials',
        'status': 'todo',
        'priority': 'normal',
        'assigned_to': null,
        'created_by': 'admin-1',
        'due_date': null,
        'completed_at': null,
        'created_at': '2026-08-18T01:00:00.000000+00:00',
        'updated_at': '2026-08-18T02:00:00.000000+00:00',
        'projects': {
          'project_number': 'P-TEST-001',
          'name': 'Test Shade Project',
        },
        'profiles': null,
      });

      expect(task.assigneeLabel, 'Unassigned');
    });
  });
}
