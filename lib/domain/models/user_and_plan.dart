import 'package:equatable/equatable.dart';

import 'meal.dart';

class AppUser extends Equatable {
  const AppUser({required this.uid, this.displayName = '', this.email = ''});

  final String uid;
  final String displayName;
  final String email;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String,
    displayName: (json['displayName'] ?? '') as String,
    email: (json['email'] ?? '') as String,
  );

  @override
  List<Object?> get props => [uid, displayName, email];
}

enum AuthStatus { unknown, authenticated, guest, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.guest() : this._(AuthStatus.guest, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(AppUser user)
    : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// The uid favorites/plans are scoped by; `null` for guests.
  String? get uid => user?.uid;

  @override
  List<Object?> get props => [status, user];
}

/// A meal planned for a calendar day (stored as a local day, not a timestamp).
class PlannedMeal extends Equatable {
  const PlannedMeal({
    required this.id,
    required this.meal,
    required this.day,
    this.reminderAt,
  });

  final int id;
  final Meal meal;

  /// Local calendar day at 00:00 (no timezone maths).
  final DateTime day;
  final DateTime? reminderAt;

  @override
  List<Object?> get props => [id, meal, day, reminderAt];
}

/// Formats a calendar day as `yyyy-MM-dd`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
