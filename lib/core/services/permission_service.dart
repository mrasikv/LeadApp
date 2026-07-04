import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class PermissionService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  User? _currentUser;

  PermissionService(this._firebaseAuth);

  // Set current user (called after login)
  void setCurrentUser(User user) {
    _currentUser = user;
  }

  // Clear current user (called after logout)
  void clearCurrentUser() {
    _currentUser = null;
  }

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user has specific permission
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    // Super Admin has all permissions
    if (_currentUser!.isSuperAdmin) return true;

    return _currentUser!.currentPermissions.contains(permission);
  }

  // Check if user has any of the permissions
  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser == null) return false;
    if (_currentUser!.isSuperAdmin) return true;

    return permissions.any((p) => _currentUser!.currentPermissions.contains(p));
  }

  // Check if user has all permissions
  bool hasAllPermissions(List<String> permissions) {
    if (_currentUser == null) return false;
    if (_currentUser!.isSuperAdmin) return true;

    return permissions
        .every((p) => _currentUser!.currentPermissions.contains(p));
  }

  // Check if user is Super Admin
  bool isSuperAdmin() {
    return _currentUser?.isSuperAdmin ?? false;
  }

  // Check if user is Company Admin
  bool isCompanyAdmin() {
    return _currentUser?.currentRoleId == 'company_admin';
  }

  // Check if user belongs to specific company
  bool belongsToCompany(String companyId) {
    return _currentUser?.currentCompanyId == companyId;
  }

  // Check if user belongs to specific department
  bool belongsToDepartment(String departmentId) {
    return _currentUser?.currentDepartmentId == departmentId;
  }

  // Check if user can view all company leads
  bool canViewAllLeads() {
    return hasPermission('view_all_leads') ||
        isSuperAdmin() ||
        isCompanyAdmin();
  }

  // Check if user can manage users
  bool canManageUsers() {
    return hasPermission('manage_users') || isSuperAdmin() || isCompanyAdmin();
  }

  // Check if user can manage departments
  bool canManageDepartments() {
    return hasPermission('manage_departments') ||
        isSuperAdmin() ||
        isCompanyAdmin();
  }

  // Check if user can manage lead statuses
  bool canManageStatuses() {
    return hasPermission('manage_statuses') ||
        isSuperAdmin() ||
        isCompanyAdmin();
  }

  // Check if user can manage forms
  bool canManageForms() {
    return hasPermission('manage_forms') || isSuperAdmin() || isCompanyAdmin();
  }

  // Check if user can manage targets
  bool canManageTargets() {
    return hasPermission('manage_targets') ||
        isSuperAdmin() ||
        isCompanyAdmin();
  }

  // Check if user can export data
  bool canExportData() {
    return hasPermission('export_leads') || isSuperAdmin() || isCompanyAdmin();
  }

  // Log permission check
  void logPermissionCheck(String permission, bool granted) {
    debugPrint(
      'Permission check: $permission - ${granted ? "GRANTED" : "DENIED"}',
    );
  }
}
