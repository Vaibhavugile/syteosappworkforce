import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_record.dart';
import '../models/attendance_break.dart';
import '../models/office_location.dart';
import '../models/office_presence.dart';

class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  static const String defaultOfficeId = 'main';
  static const double defaultRadiusMeters = 100.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _attendanceCollection =>
      _firestore.collection('attendance');

  CollectionReference<Map<String, dynamic>> get _breakCollection =>
      _firestore.collection('attendanceBreaks');

  CollectionReference<Map<String, dynamic>> get _officeCollection =>
      _firestore.collection('officeLocations');

  CollectionReference<Map<String, dynamic>> get _presenceCollection =>
      _firestore.collection('officePresence');

  String get currentUserUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No authenticated user found.');
    }
    return uid;
  }

  // ---------------------------------------------------------------------------
  // OFFICE
  // ---------------------------------------------------------------------------

  Future<OfficeLocation> getOfficeLocation({
    String officeId = defaultOfficeId,
  }) async {
    final snapshot = await _officeCollection.doc(officeId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError(
        'Office location is not configured. '
        'Create officeLocations/$officeId in Firestore first.',
      );
    }

    final office = OfficeLocation.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    if (!office.isActive) {
      throw StateError('The selected office is currently inactive.');
    }

    if (office.latitude == 0 && office.longitude == 0) {
      throw StateError('Office coordinates are not configured correctly.');
    }

    return office;
  }

  Future<void> saveOfficeLocation(OfficeLocation office) async {
    await _officeCollection.doc(office.officeId).set({
      ...office.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': office.createdAt == null
          ? FieldValue.serverTimestamp()
          : office.toMap()['createdAt'],
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled. Please enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError(
        'Location permission is required for attendance.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. '
        'Please enable it from app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistanceMeters({
    required double latitude,
    required double longitude,
    required OfficeLocation office,
  }) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      office.latitude,
      office.longitude,
    );
  }

  Future<LocationValidationResult> validateOfficeDistance({
    required Position position,
    String officeId = defaultOfficeId,
  }) async {
    final office = await getOfficeLocation(officeId: officeId);

    final distance = calculateDistanceMeters(
      latitude: position.latitude,
      longitude: position.longitude,
      office: office,
    );

    return LocationValidationResult(
      office: office,
      position: position,
      distanceMeters: distance,
      allowed: distance <= office.radiusMeters,
    );
  }

  // ---------------------------------------------------------------------------
  // TODAY
  // ---------------------------------------------------------------------------

  String dateKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    final local = DateTime(value.year, value.month, value.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  String attendanceIdFor({
    required String userId,
    DateTime? date,
  }) {
    return '${userId}_${dateKey(date)}';
  }

  Future<AttendanceRecord?> getTodayAttendance() async {
    return getAttendanceForDate(DateTime.now());
  }

  Future<AttendanceRecord?> getAttendanceForDate(DateTime date) async {
    final uid = currentUserUid;
    final id = attendanceIdFor(userId: uid, date: date);

    final snapshot = await _attendanceCollection.doc(id).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AttendanceRecord.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  Stream<AttendanceRecord?> watchTodayAttendance() {
    final uid = currentUserUid;
    final id = attendanceIdFor(userId: uid);

    return _attendanceCollection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return AttendanceRecord.fromMap(
        snapshot.id,
        snapshot.data()!,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // CHECK IN
  // ---------------------------------------------------------------------------

  Future<AttendanceRecord> checkIn({
    required File photoFile,
    String officeId = defaultOfficeId,
    String? address,
  }) async {
    final uid = currentUserUid;
    final today = dateKey();

    final existing = await getTodayAttendance();

    if (existing != null && existing.checkInAt != null) {
      throw StateError('You are already checked in for today.');
    }

    final validation = await validateOfficeDistance(
      position: await getCurrentPosition(),
      officeId: officeId,
    );

    if (!validation.allowed) {
      throw OutsideOfficeRadiusException(
        distanceMeters: validation.distanceMeters,
        radiusMeters: validation.office.radiusMeters,
        action: 'check in',
      );
    }

    final attendanceId = attendanceIdFor(
      userId: uid,
      date: DateTime.now(),
    );

    final photo = await _uploadAttendancePhoto(
      file: photoFile,
      userId: uid,
      date: today,
      type: 'checkin',
    );

    final ref = _attendanceCollection.doc(attendanceId);

    await ref.set({
      'userId': uid,
      'date': today,
      'officeId': validation.office.officeId,
      'status': AttendanceStatus.present.value,

      'checkInAt': FieldValue.serverTimestamp(),
      'checkInLatitude': validation.position.latitude,
      'checkInLongitude': validation.position.longitude,
      'checkInAccuracy': validation.position.accuracy,
      'checkInDistanceMeters': validation.distanceMeters,
      'checkInAddress': address,
      'checkInPhotoUrl': photo.downloadUrl,
      'checkInPhotoPath': photo.storagePath,

      'checkOutAt': null,
      'checkOutLatitude': null,
      'checkOutLongitude': null,
      'checkOutAccuracy': null,
      'checkOutDistanceMeters': null,
      'checkOutAddress': null,
      'checkOutPhotoUrl': null,
      'checkOutPhotoPath': null,

      'totalMinutes': 0,
      'totalBreakMinutes': 0,
      'breakCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _presenceCollection.doc(uid).set({
      'attendanceId': attendanceId,
      'officeId': validation.office.officeId,
      'status': OfficePresenceStatus.atOffice.value,
      'lastAction': 'checkIn',
      'lastActionAt': FieldValue.serverTimestamp(),
      'latitude': validation.position.latitude,
      'longitude': validation.position.longitude,
      'accuracy': validation.position.accuracy,
      'distanceFromOffice': validation.distanceMeters,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final saved = await ref.get();

    return AttendanceRecord.fromMap(
      saved.id,
      saved.data()!,
    );
  }

  // ---------------------------------------------------------------------------
  // CHECK OUT
  // ---------------------------------------------------------------------------

  Future<AttendanceRecord> checkOut({
    required File photoFile,
    String officeId = defaultOfficeId,
    String? address,
  }) async {
    final uid = currentUserUid;

    final existing = await getTodayAttendance();

    if (existing == null || existing.checkInAt == null) {
      throw StateError('You must check in before checking out.');
    }

    if (existing.checkOutAt != null) {
      throw StateError('You have already checked out for today.');
    }

    final activeBreak = await getActiveBreak();
    if (activeBreak != null) {
      throw StateError(
        'Please end your ${activeBreak.displayLabel.toLowerCase()} before checking out.',
      );
    }

    final validation = await validateOfficeDistance(
      position: await getCurrentPosition(),
      officeId: officeId,
    );

    if (!validation.allowed) {
      throw OutsideOfficeRadiusException(
        distanceMeters: validation.distanceMeters,
        radiusMeters: validation.office.radiusMeters,
        action: 'check out',
      );
    }

    final today = dateKey();
    final photo = await _uploadAttendancePhoto(
      file: photoFile,
      userId: uid,
      date: today,
      type: 'checkout',
    );

    final now = DateTime.now();
    final checkIn = existing.checkInAt!;
    final grossMinutes = now.difference(checkIn).inMinutes.clamp(0, 24 * 60);
    final totalBreakMinutes =
        await getTotalBreakMinutesForAttendance(existing.attendanceId);
    final breakSnapshot = await _breakCollection
        .where('attendanceId', isEqualTo: existing.attendanceId)
        .get();
    final completedBreakCount = breakSnapshot.docs
        .map((doc) => AttendanceBreak.fromMap(doc.id, doc.data()))
        .where((item) => !item.isActive)
        .length;
    final totalMinutes =
        (grossMinutes - totalBreakMinutes).clamp(0, 24 * 60);

    final ref = _attendanceCollection.doc(existing.attendanceId);

    await ref.update({
      'status': AttendanceStatus.checkedOut.value,
      'checkOutAt': FieldValue.serverTimestamp(),
      'checkOutLatitude': validation.position.latitude,
      'checkOutLongitude': validation.position.longitude,
      'checkOutAccuracy': validation.position.accuracy,
      'checkOutDistanceMeters': validation.distanceMeters,
      'checkOutAddress': address,
      'checkOutPhotoUrl': photo.downloadUrl,
      'checkOutPhotoPath': photo.storagePath,
      'totalMinutes': totalMinutes,
      'totalBreakMinutes': totalBreakMinutes,
      'breakCount': completedBreakCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _presenceCollection.doc(uid).set({
      'attendanceId': existing.attendanceId,
      'officeId': validation.office.officeId,
      'status': OfficePresenceStatus.checkedOut.value,
      'lastAction': 'checkOut',
      'lastActionAt': FieldValue.serverTimestamp(),
      'latitude': validation.position.latitude,
      'longitude': validation.position.longitude,
      'accuracy': validation.position.accuracy,
      'distanceFromOffice': validation.distanceMeters,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final saved = await ref.get();

    return AttendanceRecord.fromMap(
      saved.id,
      saved.data()!,
    );
  }

  // ---------------------------------------------------------------------------
  // BREAKS
  // ---------------------------------------------------------------------------

  Future<List<AttendanceBreak>> getTodayBreaks() async {
    return getBreaksForDate(DateTime.now());
  }

  Future<List<AttendanceBreak>> getBreaksForAttendance(
    String attendanceId,
  ) async {
    if (attendanceId.trim().isEmpty) {
      throw ArgumentError('Attendance ID is required.');
    }

    final snapshot = await _breakCollection
        .where('attendanceId', isEqualTo: attendanceId)
        .get();

    final items = snapshot.docs
        .map((doc) => AttendanceBreak.fromMap(doc.id, doc.data()))
        .toList();

    items.sort((a, b) {
      final aDate = a.startedAt ?? DateTime(2000);
      final bDate = b.startedAt ?? DateTime(2000);
      return aDate.compareTo(bDate);
    });

    return items;
  }

  Future<List<AttendanceBreak>> getBreaksForDate(DateTime date) async {
    final uid = currentUserUid;
    final attendanceId = attendanceIdFor(userId: uid, date: date);
    final snapshot = await _breakCollection
        .where('attendanceId', isEqualTo: attendanceId)
        .get();

    final items = snapshot.docs
        .map((doc) => AttendanceBreak.fromMap(doc.id, doc.data()))
        .toList();

    items.sort((a, b) {
      final aDate = a.startedAt ?? DateTime(2000);
      final bDate = b.startedAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return items;
  }

  Stream<List<AttendanceBreak>> watchTodayBreaks() {
    final uid = currentUserUid;
    final attendanceId = attendanceIdFor(userId: uid);

    return _breakCollection
        .where('attendanceId', isEqualTo: attendanceId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AttendanceBreak.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final aDate = a.startedAt ?? DateTime(2000);
        final bDate = b.startedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  Future<AttendanceBreak?> getActiveBreak() async {
    final breaks = await getTodayBreaks();
    for (final item in breaks) {
      if (item.isActive) return item;
    }
    return null;
  }

  Stream<AttendanceBreak?> watchActiveBreak() {
    return watchTodayBreaks().map((items) {
      for (final item in items) {
        if (item.isActive) return item;
      }
      return null;
    });
  }

  Future<AttendanceBreak> startBreak({
    required AttendanceBreakType type,
    String? customLabel,
    String? note,
  }) async {
    final uid = currentUserUid;
    final attendance = await getTodayAttendance();

    if (attendance == null || !attendance.isCheckedIn) {
      throw StateError('You must check in before starting a break.');
    }

    if (attendance.isCheckedOut) {
      throw StateError('You cannot start a break after checking out.');
    }

    final active = await getActiveBreak();
    if (active != null) {
      throw StateError('${active.displayLabel} is already running.');
    }

    final now = DateTime.now();
    final breakId = _uuid.v4();

    final ref = _breakCollection.doc(breakId);
    await ref.set({
      'attendanceId': attendance.attendanceId,
      'userId': uid,
      'date': attendance.date,
      'type': type.value,
      'customLabel': customLabel?.trim(),
      'startedAt': Timestamp.fromDate(now),
      'endedAt': null,
      'durationMinutes': 0,
      'note': note?.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final saved = await ref.get();
    return AttendanceBreak.fromMap(saved.id, saved.data()!);
  }

  Future<AttendanceBreak> endBreak(String breakId) async {
    final uid = currentUserUid;
    final ref = _breakCollection.doc(breakId);
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('Break not found.');
    }

    final existing = AttendanceBreak.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    if (existing.userId != uid) {
      throw StateError('You can only end your own break.');
    }

    if (!existing.isActive || existing.startedAt == null) {
      throw StateError('This break is already completed.');
    }

    final now = DateTime.now();
    final duration = now.difference(existing.startedAt!).inMinutes.clamp(0, 24 * 60);

    await ref.update({
      'endedAt': Timestamp.fromDate(now),
      'durationMinutes': duration,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Keep the attendance document's break totals current.
    await _syncBreakTotals(existing.attendanceId);

    final saved = await ref.get();
    return AttendanceBreak.fromMap(saved.id, saved.data()!);
  }

  Future<int> getTotalBreakMinutesForAttendance(String attendanceId) async {
    final snapshot = await _breakCollection
        .where('attendanceId', isEqualTo: attendanceId)
        .get();

    var total = 0;
    for (final doc in snapshot.docs) {
      final item = AttendanceBreak.fromMap(doc.id, doc.data());
      if (!item.isActive) {
        total += item.durationMinutes;
      }
    }
    return total;
  }

  Future<void> _syncBreakTotals(String attendanceId) async {
    final snapshot = await _breakCollection
        .where('attendanceId', isEqualTo: attendanceId)
        .get();

    var totalBreakMinutes = 0;
    var breakCount = 0;

    for (final doc in snapshot.docs) {
      final item = AttendanceBreak.fromMap(doc.id, doc.data());
      if (!item.isActive) {
        totalBreakMinutes += item.durationMinutes;
        breakCount++;
      }
    }

    await _attendanceCollection.doc(attendanceId).set({
      'totalBreakMinutes': totalBreakMinutes,
      'breakCount': breakCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // PHOTO UPLOAD
  // ---------------------------------------------------------------------------

  Future<_UploadedAttendancePhoto> _uploadAttendancePhoto({
    required File file,
    required String userId,
    required String date,
    required String type,
  }) async {
    if (!file.existsSync()) {
      throw StateError('Attendance photo was not found.');
    }

    final extension = _fileExtension(file.path);
    final fileId = _uuid.v4();

    final storagePath =
        'attendance/$userId/$date/${type}_$fileId.$extension';

    final reference = _storage.ref(storagePath);

    await reference.putFile(
      file,
      SettableMetadata(
        contentType: _contentType(extension),
        customMetadata: {
          'userId': userId,
          'attendanceDate': date,
          'attendanceType': type,
        },
      ),
    );

    final downloadUrl = await reference.getDownloadURL();

    return _UploadedAttendancePhoto(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
    );
  }

  String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return 'jpg';
    }

    return path.substring(dot + 1).toLowerCase();
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // ---------------------------------------------------------------------------
  // MANAGEMENT
  // ---------------------------------------------------------------------------

  Future<OfficePresence?> getEmployeePresence(String userId) async {
    final snapshot = await _presenceCollection.doc(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return OfficePresence.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  Stream<OfficePresence?> watchEmployeePresence(String userId) {
    return _presenceCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return OfficePresence.fromMap(
        snapshot.id,
        snapshot.data()!,
      );
    });
  }

  Stream<List<OfficePresence>> watchOfficePresence() {
    return _presenceCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => OfficePresence.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE HISTORY
  // ---------------------------------------------------------------------------

  Future<List<AttendanceRecord>> getMyAttendanceHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = currentUserUid;
    final start = dateKey(startDate);
    final end = dateKey(endDate);

    final snapshot = await _attendanceCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    final records = snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
        .toList();

    records.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return (b.checkInAt ?? DateTime(2000))
          .compareTo(a.checkInAt ?? DateTime(2000));
    });

    return records;
  }

  Future<List<AttendanceRecord>> getAttendanceHistoryForManagement({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = dateKey(startDate);
    final end = dateKey(endDate);

    final snapshot = await _attendanceCollection
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    final records = snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
        .toList();

    records.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return (b.checkInAt ?? DateTime(2000))
          .compareTo(a.checkInAt ?? DateTime(2000));
    });

    return records;
  }

  Future<List<AttendanceRecord>> getAttendanceForDateForManagement(
    DateTime date,
  ) async {
    final snapshot = await _attendanceCollection
        .where('date', isEqualTo: dateKey(date))
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceRecord.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }
}

class LocationValidationResult {
  final OfficeLocation office;
  final Position position;
  final double distanceMeters;
  final bool allowed;

  const LocationValidationResult({
    required this.office,
    required this.position,
    required this.distanceMeters,
    required this.allowed,
  });
}

class OutsideOfficeRadiusException implements Exception {
  final double distanceMeters;
  final double radiusMeters;
  final String action;

  const OutsideOfficeRadiusException({
    required this.distanceMeters,
    required this.radiusMeters,
    required this.action,
  });

  @override
  String toString() {
    return 'You are ${distanceMeters.toStringAsFixed(0)}m '
        'from the office. You must be within '
        '${radiusMeters.toStringAsFixed(0)}m to $action.';
  }
}

class _UploadedAttendancePhoto {
  final String storagePath;
  final String downloadUrl;

  const _UploadedAttendancePhoto({
    required this.storagePath,
    required this.downloadUrl,
  });
}
