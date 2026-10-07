import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/invitation_model.dart';

/// Handles publishing invitations to the public invitation collection.
///
/// Public invitations are stored as:
///   publishedInvitations/{slug}
///
/// The document id is the public slug, which makes public lookup fast and
/// avoids a Firestore query just to find an invitation by URL.
class InvitationPublishService {
  InvitationPublishService({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  static const String collectionName = 'publishedInvitations';

  /// Change this later when the custom wedding domain is connected.
  static const String publicBaseUrl = 'https://syteos-wedding.web.app';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Publishes an invitation and returns its public URL.
  ///
  /// If the invitation already has a slug, that same public URL is updated.
  /// If it does not have a slug, a unique human-readable slug is generated.
  Future<PublishedInvitationResult> publish(
    InvitationModel invitation,
  ) async {
    if (!invitation.canPublish) {
      throw StateError(
        'Invitation is not ready to publish. '
        'Bride name, groom name, wedding date, venue, template and IDs are required.',
      );
    }

    final String slug = await _resolveSlug(invitation);
    final DocumentReference<Map<String, dynamic>> document =
        _collection.doc(slug);

    final Map<String, dynamic> data = _buildPublicData(
      invitation,
      slug,
    );

    await document.set(data, SetOptions(merge: true));

    final InvitationModel publishedInvitation = invitation.copyWith(
      published: true,
      slug: slug,
      updatedAt: DateTime.now(),
    );

    return PublishedInvitationResult(
      invitation: publishedInvitation,
      slug: slug,
      url: buildPublicUrl(slug),
    );
  }

  /// Makes the invitation unavailable from its public URL.
  Future<void> unpublish(InvitationModel invitation) async {
    final String slug = invitation.slug.trim();

    if (slug.isEmpty) {
      return;
    }

    await _collection.doc(slug).set(
      <String, dynamic>{
        'published': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Checks whether a public slug is already being used.
  Future<bool> isSlugAvailable(String slug) async {
    final String normalizedSlug = _slugify(slug);

    if (normalizedSlug.isEmpty) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(normalizedSlug).get();

    return !snapshot.exists;
  }

  /// Returns the published invitation for a slug.
  ///
  /// Returns null when the document does not exist or is not published.
  Future<InvitationModel?> getPublishedInvitation(String slug) async {
    final String normalizedSlug = _slugify(slug);

    if (normalizedSlug.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(normalizedSlug).get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null || data['published'] != true) {
      return null;
    }

    return InvitationModel.fromMap(data);
  }

  /// Builds the public URL for a slug.
  String buildPublicUrl(String slug) {
    final String normalizedSlug = _slugify(slug);
    return '$publicBaseUrl/invite/$normalizedSlug';
  }

  Future<String> _resolveSlug(InvitationModel invitation) async {
    final String existingSlug = _slugify(invitation.slug);

    if (existingSlug.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await _collection.doc(existingSlug).get();

      if (!existing.exists) {
        return existingSlug;
      }

      final Map<String, dynamic>? data = existing.data();
      final String? ownerId = data?['ownerId'] as String?;

      // The same owner can republish/update the same invitation slug.
      if (ownerId == invitation.userId) {
        return existingSlug;
      }
    }

    return _createUniqueSlug(
      '${invitation.brideName}-${invitation.groomName}',
    );
  }

  Future<String> _createUniqueSlug(String value) async {
    final String base = _slugify(value).isEmpty
        ? 'wedding-invitation'
        : _slugify(value);

    String candidate = base;

    for (int attempt = 0; attempt < 10; attempt++) {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _collection.doc(candidate).get();

      if (!snapshot.exists) {
        return candidate;
      }

      final String suffix = _uuid.v4().replaceAll('-', '').substring(0, 6);
      candidate = '$base-$suffix';
    }

    throw StateError('Could not create a unique invitation slug.');
  }

  Map<String, dynamic> _buildPublicData(
    InvitationModel invitation,
    String slug,
  ) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      invitation.toMap(),
    );

    // Do not expose local device paths in the public Firestore document.
    final dynamic rawPhotos = data['photos'];

    if (rawPhotos is List) {
      data['photos'] = rawPhotos.map((dynamic item) {
        if (item is Map) {
          final Map<String, dynamic> photo =
              Map<String, dynamic>.from(item);
          photo.remove('localPath');
          return photo;
        }
        return item;
      }).toList();
    }

    // Keep ownership information for secure authenticated writes.
    // This is not displayed by the public renderer.
    data['ownerId'] = invitation.userId;
    data['invitationId'] = invitation.id;
    data['published'] = true;
    data['slug'] = slug;
    data['publishedAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    return data;
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class PublishedInvitationResult {
  const PublishedInvitationResult({
    required this.invitation,
    required this.slug,
    required this.url,
  });

  final InvitationModel invitation;
  final String slug;
  final String url;
}
