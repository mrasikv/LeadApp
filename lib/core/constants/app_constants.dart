// Core Constants
class AppConstants {
  // App Info
  static const String appName = 'LeadFlow Pro';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Cache
  static const int cacheValidityHours = 24;

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat = 'hh:mm a';

  // Firebase Collections
  static const String companiesCollection = 'companies';
  static const String usersCollection = 'users';
  static const String userCompaniesCollection = 'user_companies';
  static const String rolesCollection = 'roles';
  static const String permissionsCollection = 'permissions';
  static const String departmentsCollection = 'departments';
  static const String leadsCollection = 'leads';
  static const String leadStatusesCollection = 'lead_statuses';
  static const String dynamicFormsCollection = 'dynamic_forms';
  static const String activitiesCollection = 'activities';
  static const String notesCollection = 'notes';
  static const String targetsCollection = 'targets';
  static const String ticketsCollection = 'tickets';
  static const String callLogsCollection = 'call_logs';
  static const String auditLogsCollection = 'audit_logs';
  static const String projectsCollection = 'projects';
  static const String projectTypesCollection = 'project_types';

  // Default Role IDs
  static const String superAdminRoleId = 'super_admin';
  static const String companyAdminRoleId = 'company_admin';
  static const String salesUserRoleId = 'sales_user';
  static const String callAgentRoleId = 'call_agent';
  static const String managerRoleId = 'manager';
  static const String fieldStaffRoleId = 'field_staff';

  // Lead Status Categories
  static const String statusCategoryToDo = 'to_do';
  static const String statusCategoryInProgress = 'in_progress';
  static const String statusCategoryDone = 'done';

  // Default Lead Statuses (System-wide template)
  static const List<Map<String, dynamic>> defaultLeadStatuses = [
    {
      'name': 'New',
      'category': statusCategoryToDo,
      'color': '#2196F3',
      'order': 1,
      'isSystemDefault': true,
    },
    {
      'name': 'Follow-up',
      'category': statusCategoryInProgress,
      'color': '#FF9800',
      'order': 2,
      'isSystemDefault': true,
    },
    {
      'name': 'Recall',
      'category': statusCategoryInProgress,
      'color': '#9C27B0',
      'order': 3,
      'isSystemDefault': true,
    },
    {
      'name': 'Qualified',
      'category': statusCategoryInProgress,
      'color': '#4CAF50',
      'order': 4,
      'isSystemDefault': true,
    },
    {
      'name': 'Unanswered',
      'category': statusCategoryToDo,
      'color': '#F44336',
      'order': 5,
      'isSystemDefault': true,
    },
    {
      'name': 'Potential',
      'category': statusCategoryInProgress,
      'color': '#00BCD4',
      'order': 6,
      'isSystemDefault': true,
    },
    {
      'name': 'Incoming Call',
      'category': statusCategoryToDo,
      'color': '#FFC107',
      'order': 7,
      'isSystemDefault': true,
    },
    {
      'name': 'Office Visit',
      'category': statusCategoryInProgress,
      'color': '#3F51B5',
      'order': 8,
      'isSystemDefault': true,
    },
    {
      'name': 'Won',
      'category': statusCategoryDone,
      'color': '#4CAF50',
      'order': 9,
      'isSystemDefault': true,
    },
    {
      'name': 'Lost',
      'category': statusCategoryDone,
      'color': '#9E9E9E',
      'order': 10,
      'isSystemDefault': true,
    },
  ];

  // Form Field Types
  static const String fieldTypeText = 'text';
  static const String fieldTypeNumber = 'number';
  static const String fieldTypeDropdown = 'dropdown';
  static const String fieldTypeMultiSelect = 'multi_select';
  static const String fieldTypeDate = 'date';
  static const String fieldTypePhone = 'phone';
  static const String fieldTypePrice = 'price';
  static const String fieldTypeEmail = 'email';
  static const String fieldTypeTextarea = 'textarea';

  // Call Types
  static const String callTypeOutgoing = 'outgoing';
  static const String callTypeIncoming = 'incoming';
  static const String callTypeMissed = 'missed';

  // Activity Types
  static const String activityTypeStatusChange = 'status_change';
  static const String activityTypeCall = 'call';
  static const String activityTypeNote = 'note';
  static const String activityTypeAssignment = 'assignment';
  static const String activityTypeCreated = 'created';
  static const String activityTypeUpdated = 'updated';

  // Target Types
  static const String targetTypePrice = 'price';
  static const String targetTypeQuantity = 'quantity';
  static const String targetTypeHybrid = 'hybrid';

  // Company Types
  static const List<String> companyTypes = [
    'Tour Marketing',
    'Product Sales',
    'Real Estate',
    'Insurance',
    'B2B Services',
    'E-commerce',
    'Education',
    'Healthcare',
    'Other',
  ];

  // Permissions
  static const String permissionViewLeads = 'view_leads';
  static const String permissionCreateLeads = 'create_leads';
  static const String permissionEditLeads = 'edit_leads';
  static const String permissionDeleteLeads = 'delete_leads';
  static const String permissionExportLeads = 'export_leads';
  static const String permissionViewReports = 'view_reports';
  static const String permissionManageUsers = 'manage_users';
  static const String permissionManageDepartments = 'manage_departments';
  static const String permissionManageStatuses = 'manage_statuses';
  static const String permissionManageForms = 'manage_forms';
  static const String permissionManageTargets = 'manage_targets';
  static const String permissionViewAllLeads = 'view_all_leads';
  static const String permissionAssignLeads = 'assign_leads';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyCompanyId = 'company_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxNoteLength = 5000;
}
