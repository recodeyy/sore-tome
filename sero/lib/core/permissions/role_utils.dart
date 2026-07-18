class RoleUtils {
  const RoleUtils._();

  static String normalize(String role) {
    final cleaned = role.trim().toLowerCase().replaceAll('-', '_');
    switch (cleaned) {
      case 'superadmin':
      case 'super_admin':
        return 'super_admin';
      case 'mainadmin':
      case 'main_admin':
        return 'main_admin';
      case 'resident':
      case 'resident_owner':
      case 'owner':
        return 'resident_owner';
      case 'resident_tenant':
      case 'tenant':
        return 'resident_tenant';
      case 'committee':
      case 'committee_member':
        return 'committee_member';
      case 'facility':
      case 'facility_manager':
        return 'facility_manager';
      case 'security':
      case 'security_manager':
        return 'security_manager';
      default:
        return cleaned.isEmpty ? 'resident_owner' : cleaned;
    }
  }

  static bool isResident(String role) {
    final normalized = normalize(role);
    return normalized == 'resident_owner' || normalized == 'resident_tenant';
  }

  static bool isSuperAdmin(String role) => normalize(role) == 'super_admin';

  /// Gate/operations staff roles that belong in the StaffShell. Mirrors the
  /// allowedRoles list on the '/staff' route in app.dart.
  static bool isStaff(String role) {
    const staffRoles = {
      'guard', 'security_manager', 'facility_manager', 'supervisor',
      'maintenance_staff', 'housekeeping_staff', 'reception_staff',
      'parcel_desk_staff', 'staff',
    };
    return staffRoles.contains(normalize(role));
  }
}
