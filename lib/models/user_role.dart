enum UserRole { student, staff }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.student ? 'Student' : 'Staff';
}
