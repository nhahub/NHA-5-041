import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/prefs/preference_manager.dart';

import '../../domain/models/user_and_plan.dart';
import '../../domain/repositories/repositories.dart';

/// Where a user's avatar path is remembered.
abstract class AvatarStore {
  Future<String?> load(String uid);

  /// Copies the picked image into app storage and remembers its path.
  Future<String> save(String uid, String pickedPath);
  Future<void> clear(String uid);
}

class FileAvatarStore implements AvatarStore {
  FileAvatarStore(this._prefManager);

  final PreferenceManager _prefManager;

  String _key(String uid) => 'avatar_path_$uid';

  @override
  Future<String?> load(String uid) async {
    final path = _prefManager.getString(_key(uid));
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  @override
  Future<String> save(String uid, String pickedPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = p.join(
      dir.path,
      'avatar_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(pickedPath).copy(target);
    final old = _prefManager.getString(_key(uid));
    await _prefManager.setString(_key(uid), target);
    if (old != null && old != target) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    return target;
  }

  @override
  Future<void> clear(String uid) => _prefManager.remove(_key(uid));
}

typedef ImagePickerFn = Future<String?> Function();

/// Picks from the system photo picker, already resized to <= 512 px.
Future<String?> pickAvatarFromGallery() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );
  return file?.path;
}

/// State = path of the current user's profile image (null = default avatar).
/// Used by Profile and the Home header.
class AvatarCubit extends Cubit<String?> {
  AvatarCubit(
    this._auth,
    this._store, {
    ImagePickerFn picker = pickAvatarFromGallery,
  }) : _picker = picker,
       super(null) {
    _sub = _auth.authStateChanges.listen(_onAuth);
  }

  final AuthRepository _auth;
  final AvatarStore _store;
  final ImagePickerFn _picker;
  late final StreamSubscription<AuthState> _sub;

  Future<void> _onAuth(AuthState s) async {
    final uid = s.uid;
    final path = uid == null ? null : await _store.load(uid);
    if (!isClosed) emit(path);
  }

  /// Returns false when cancelled or when there is no signed-in user.
  Future<bool> pick() async {
    final uid = _auth.currentState.uid;
    if (uid == null) return false;
    final picked = await _picker();
    if (picked == null) return false;
    final saved = await _store.save(uid, picked);
    if (!isClosed) emit(saved);
    return true;
  }

  Future<void> reset() async {
    final uid = _auth.currentState.uid;
    if (uid != null) await _store.clear(uid);
    if (!isClosed) emit(null);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
