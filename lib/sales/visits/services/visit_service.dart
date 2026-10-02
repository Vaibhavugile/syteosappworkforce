import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/visit.dart';

class VisitService {
  VisitService._();

  static final VisitService instance = VisitService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _visitsCollection =>
      _firestore.collection('visits');

  CollectionReference<Map<String, dynamic>> get _leadsCollection =>
      _firestore.collection('leads');

  // ============================================================
  // CURRENT USER
  // ============================================================

  String get currentUserUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to perform this action.',
      );
    }

    return user.uid;
  }

  User get currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to perform this action.',
      );
    }

    return user;
  }

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  void _validateVisitId(String visitId) {
    if (visitId.trim().isEmpty) {
      throw Exception('Visit ID is required.');
    }
  }

  void _validateCustomerUid(String customerUid) {
    if (customerUid.trim().isEmpty) {
      throw Exception('Customer ID is required.');
    }
  }

  void _validateLeadId(String leadId) {
    if (leadId.trim().isEmpty) {
      throw Exception('Lead ID is required.');
    }
  }

  Visit _parseVisit(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return Visit.fromMap(
      document.id,
      document.data(),
    );
  }

  Visit _parseVisitDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return Visit.fromMap(
      document.id,
      document.data() ?? <String, dynamic>{},
    );
  }

  List<Visit> _parseVisits(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_parseVisit).toList();
  }

  // ============================================================
  // CREATE VISIT
  // ============================================================

  Future<String> createVisit({
    required Visit visit,
  }) async {
    final userUid = currentUserUid;

    if (visit.customerUid.trim().isEmpty) {
      throw Exception(
        'Customer is required before creating a visit.',
      );
    }

    final document = _visitsCollection.doc();

    final now = DateTime.now();

    final visitToSave = visit.copyWith(
      visitId: document.id,
      createdBy: visit.createdBy.trim().isEmpty
          ? userUid
          : visit.createdBy.trim(),
      assignedTo: visit.assignedTo.trim().isEmpty
          ? userUid
          : visit.assignedTo.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final data = visitToSave.toMap();

    // Use Firestore server timestamps for consistency.
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await document.set(data);

    return document.id;
  }

  // ============================================================
  // GET SINGLE VISIT
  // ============================================================

  Future<Visit?> getVisit(
    String visitId,
  ) async {
    _validateVisitId(visitId);

    final document = await _visitsCollection
        .doc(visitId.trim())
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return _parseVisitDocument(document);
  }

  // ============================================================
  // UPDATE VISIT
  // ============================================================

  Future<void> updateVisit(
    Visit visit,
  ) async {
    _validateVisitId(visit.visitId);

    if (visit.customerUid.trim().isEmpty) {
      throw Exception(
        'Customer is required.',
      );
    }

    final data = visit.toMap();

    // Never allow the document ID to be accidentally changed.
    data['visitId'] = visit.visitId;

    // Always update modification time on the server.
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _visitsCollection
        .doc(visit.visitId.trim())
        .update(data);
  }

  // ============================================================
  // START VISIT
  // ============================================================

  Future<void> startVisit(
    String visitId,
  ) async {
    _validateVisitId(visitId);

    final document = _visitsCollection.doc(visitId.trim());

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Visit not found.',
      );
    }

    final data = snapshot.data();

    final currentStatus = data?['status']?.toString();

    if (currentStatus == 'COMPLETED') {
      throw Exception(
        'Completed visits cannot be started again.',
      );
    }

    if (currentStatus == 'CANCELLED') {
      throw Exception(
        'Cancelled visits cannot be started.',
      );
    }

    if (currentStatus == 'MISSED') {
      throw Exception(
        'Missed visits cannot be started.',
      );
    }

    await document.update({
      'status': visitStatusToString(
        VisitStatus.inProgress,
      ),
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // COMPLETE VISIT
  // ============================================================

  Future<void> completeVisit({
    required String visitId,
    required VisitOutcome outcome,
    String? notes,
    DateTime? nextFollowUpAt,
  }) async {
    _validateVisitId(visitId);

    final document = _visitsCollection.doc(visitId.trim());

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Visit not found.',
      );
    }

    final data = snapshot.data();

    final currentStatus = data?['status']?.toString();

    if (currentStatus == 'COMPLETED') {
      throw Exception(
        'This visit is already completed.',
      );
    }

    if (currentStatus == 'CANCELLED') {
      throw Exception(
        'Cancelled visits cannot be completed.',
      );
    }

    if (currentStatus == 'MISSED') {
      throw Exception(
        'Missed visits cannot be completed.',
      );
    }

    final updateData = <String, dynamic>{
      'status': visitStatusToString(
        VisitStatus.completed,
      ),
      'outcome': visitOutcomeToString(outcome),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (notes != null) {
      updateData['notes'] = notes.trim();
    }

    if (nextFollowUpAt != null) {
      updateData['nextFollowUpAt'] =
          Timestamp.fromDate(nextFollowUpAt);
    } else {
      updateData['nextFollowUpAt'] = null;
    }

    await document.update(updateData);
  }

  // ============================================================
  // CANCEL VISIT
  // ============================================================

  Future<void> cancelVisit(
    String visitId,
  ) async {
    _validateVisitId(visitId);

    final document = _visitsCollection.doc(visitId.trim());

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Visit not found.',
      );
    }

    final data = snapshot.data();

    final currentStatus = data?['status']?.toString();

    if (currentStatus == 'COMPLETED') {
      throw Exception(
        'Completed visits cannot be cancelled.',
      );
    }

    if (currentStatus == 'CANCELLED') {
      return;
    }

    await document.update({
      'status': visitStatusToString(
        VisitStatus.cancelled,
      ),
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK VISIT AS MISSED
  // ============================================================

  Future<void> markVisitAsMissed(
    String visitId,
  ) async {
    _validateVisitId(visitId);

    final document = _visitsCollection.doc(visitId.trim());

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Visit not found.',
      );
    }

    final data = snapshot.data();

    final currentStatus = data?['status']?.toString();

    if (currentStatus == 'COMPLETED') {
      throw Exception(
        'Completed visits cannot be marked as missed.',
      );
    }

    if (currentStatus == 'CANCELLED') {
      throw Exception(
        'Cancelled visits cannot be marked as missed.',
      );
    }

    if (currentStatus == 'MISSED') {
      return;
    }

    await document.update({
      'status': visitStatusToString(
        VisitStatus.missed,
      ),
      'missedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ATTACH EXISTING LEAD
  // ============================================================

  Future<void> attachLeadToVisit({
    required String visitId,
    required String leadId,
    required String customerUid,
  }) async {
    _validateVisitId(visitId);
    _validateLeadId(leadId);
    _validateCustomerUid(customerUid);

    final visitDocument =
        _visitsCollection.doc(visitId.trim());

    final visitSnapshot =
        await visitDocument.get();

    if (!visitSnapshot.exists) {
      throw Exception(
        'Visit not found.',
      );
    }

    final leadDocument =
        _leadsCollection.doc(leadId.trim());

    final leadSnapshot =
        await leadDocument.get();

    if (!leadSnapshot.exists) {
      throw Exception(
        'Lead not found.',
      );
    }

    await visitDocument.update({
      'leadId': leadId.trim(),
      'customerUid': customerUid.trim(),
      'leadCreated': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET CURRENT USER'S VISITS
  // ============================================================

  Stream<List<Visit>> watchMyVisits() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET TODAY'S VISITS
  // ============================================================

  Stream<List<Visit>> watchTodayVisits() {
    final userUid = currentUserUid;

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    );

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .where(
          'scheduledAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(startOfDay),
        )
        .where(
          'scheduledAt',
          isLessThanOrEqualTo:
              Timestamp.fromDate(endOfDay),
        )
        .orderBy(
          'scheduledAt',
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET UPCOMING VISITS
  // ============================================================

  Stream<List<Visit>> watchUpcomingVisits() {
    final userUid = currentUserUid;

    final now = DateTime.now();

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .where(
          'status',
          whereIn: [
            visitStatusToString(
              VisitStatus.planned,
            ),
            visitStatusToString(
              VisitStatus.inProgress,
            ),
          ],
        )
        .where(
          'scheduledAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(now),
        )
        .orderBy(
          'scheduledAt',
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET COMPLETED VISITS
  // ============================================================

  Stream<List<Visit>> watchCompletedVisits() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .where(
          'status',
          isEqualTo: visitStatusToString(
            VisitStatus.completed,
          ),
        )
        .orderBy(
          'completedAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET SELF-ADDED VISITS
  // ============================================================

  Stream<List<Visit>> watchSelfAddedVisits() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'createdBy',
          isEqualTo: userUid,
        )
        .where(
          'visitType',
          isEqualTo: visitTypeToString(
            VisitType.selfAdded,
          ),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // DELETE VISIT
  // ============================================================

  Future<void> deleteVisit(
    String visitId,
  ) async {
    _validateVisitId(visitId);

    final document =
        _visitsCollection.doc(visitId.trim());

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw Exception(
        'Visit not found.',
      );
    }

    await document.delete();
  }

  // ============================================================
  // CHECK WHETHER A LEAD EXISTS FOR CUSTOMER
  // ============================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      findLeadByCustomerUid(
    String customerUid,
  ) async {
    _validateCustomerUid(customerUid);

    final snapshot = await _leadsCollection
        .where(
          'customerUid',
          isEqualTo: customerUid.trim(),
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  // ============================================================
  // FIND LEAD BY PHONE
  // ============================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      findLeadByPhone(
    String phone,
  ) async {
    final normalizedPhone = phone.trim();

    if (normalizedPhone.isEmpty) {
      return null;
    }

    final snapshot = await _leadsCollection
        .where(
          'phone',
          isEqualTo: normalizedPhone,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  // ============================================================
  // FIND LEAD BY ID
  // ============================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      findLeadById(
    String leadId,
  ) async {
    _validateLeadId(leadId);

    final document =
        await _leadsCollection.doc(leadId.trim()).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    // QueryDocumentSnapshot is not available from get()
    // on a DocumentReference, so this helper intentionally
    // returns null-safe document data through a query.
    final snapshot = await _leadsCollection
        .where(
          FieldPath.documentId,
          isEqualTo: leadId.trim(),
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  // ============================================================
  // CHECK LEAD BY PHONE
  // ============================================================

  Future<bool> leadExistsByPhone(
    String phone,
  ) async {
    final lead = await findLeadByPhone(phone);
    return lead != null;
  }

  // ============================================================
  // CHECK LEAD BY CUSTOMER UID
  // ============================================================

  Future<bool> leadExistsForCustomer(
    String customerUid,
  ) async {
    final lead =
        await findLeadByCustomerUid(customerUid);

    return lead != null;
  }

  // ============================================================
  // GET VISITS FOR CUSTOMER
  // ============================================================

  Stream<List<Visit>> watchCustomerVisits(
    String customerUid,
  ) {
    _validateCustomerUid(customerUid);

    return _visitsCollection
        .where(
          'customerUid',
          isEqualTo: customerUid.trim(),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET VISITS FOR LEAD
  // ============================================================

  Stream<List<Visit>> watchLeadVisits(
    String leadId,
  ) {
    _validateLeadId(leadId);

    return _visitsCollection
        .where(
          'leadId',
          isEqualTo: leadId.trim(),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET VISITS CREATED BY USER
  // ============================================================

  Stream<List<Visit>> watchCreatedByMe() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'createdBy',
          isEqualTo: userUid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET ACTIVE / PLANNED VISITS
  // ============================================================

  Stream<List<Visit>> watchActiveVisits() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .where(
          'status',
          whereIn: [
            visitStatusToString(
              VisitStatus.planned,
            ),
            visitStatusToString(
              VisitStatus.inProgress,
            ),
          ],
        )
        .orderBy(
          'scheduledAt',
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET MISSED VISITS
  // ============================================================

  Stream<List<Visit>> watchMissedVisits() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .where(
          'status',
          isEqualTo: visitStatusToString(
            VisitStatus.missed,
          ),
        )
        .orderBy(
          'scheduledAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }

  // ============================================================
  // GET CANCELLED VISITS
  // ============================================================

  Stream<List<Visit>> watchCancelledVisits() {
    final userUid = currentUserUid;

    return _visitsCollection
        .where(
          'assignedTo',
          isEqualTo: userUid,
        )
        .where(
          'status',
          isEqualTo: visitStatusToString(
            VisitStatus.cancelled,
          ),
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots()
        .map(_parseVisits);
  }
}