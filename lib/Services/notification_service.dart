import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../Models/notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HOW TO SET UP THE SERVICE ACCOUNT
//
//  1. Firebase Console → Project Settings → Service Accounts
//  2. Click "Generate new private key" → download the JSON file
//  3. Copy the JSON content into the _serviceAccountJson string below
//     (replace every field — projectId, privateKeyId, privateKey, clientEmail)
//
//  ⚠️  SECURITY: Never commit the real key to a public repo.
//      For production, load it from a Cloud Function / secure backend
//      so the private key is never shipped inside the app.
// ─────────────────────────────────────────────────────────────────────────────
const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "venuemate-system",
  "private_key_id": "61aaa45604f1896dccc79fb3e0f213d0abba92fc",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDO8Gkvr174KlMt\nuBoSXm2dEVwt8fU54Mft7wY1XG9fbg8clhT6HbQDm5TeP3xo7K5tXNhoYwrVa69k\nXrLC60fXS8dtVLlQoaAyZ8Y4Mw9tU3Y8UiprCUvGTp5a9GLZ14T34tEQV4BBxp4C\nsz29A8rWu0j/ZSC8XE7p8HxhVmnHdUrUH6fg0rKixD7mXI+GR+sIFtSMw69y3VFU\nIZPLTz4OewllBw0udSaZULoncdINu312A/Xp9KppEqyQYor6H59AO3RKY2aFc21q\na/LSfjHPDrbv/oQux8Ob/LzxFjFO8FfXu/w8IRxIVRubzhrcB0VnMjBTcxGrBLpY\nuQKwmH7/AgMBAAECggEANRKjZ39qs+rm+krFJQDiy+2v3ni3k+h6XiN3TCgwyCDJ\n72Lublc/280DGRzfI2nQMmwldGAyXxoHGY7P+f2tpyHgO8IG5Q8Ort6+j5tI0Zke\nMcpA5sKzlGCFbH5Q+92yVIDvbWmDk1sFG1ws8VUPqJLP3fBpvOVPt9/dhnlLF8Qe\nvs4R2x4mCqACQSiCG2r98p6WKUpbmh0M7pEDHCjXCMqH4G7pvYQYPNYIm3BaV1oO\ntmIJhvfp+1AsZ+SzjL2EclT+qblp6ibmLDXRb+hMKIkQgjD2NAWktEfShAXca2cl\nw1xfLGOA8i5SObqNVGf2TIZsUdlz5vBqBQfLZblVgQKBgQD555ixzskhP0BbZujg\np54N3aOQIxpyGCggJbAN/d0FYk4avc1xH6s3F/T4Qsv5GmORL/k1lPdvlE9WUkND\n5jboOzX6SatheUR3sf8jQNEp2euIsmPQaqTPGAao02nREZBNVVMVXBn7jhCC8H/+\n/gII1z98rfs1NRWJ/uHOBcYnKQKBgQDT/ImhvAN1OvhMwXNjwJyP1Ft+x3mlGYKE\ntpPboC5N2VtYfi5d2TWPedSL5ILpSFNSfw4K4wpf8fkyimGhtbSL416nOjq0sj+G\nq7Ez4jCve/E1IuXA+Lc7R3TRSQuIEHsx8xXiuII70Bb1ZM4P8TEPaSD9mmoBQJ8e\n9z0vWAQB5wKBgChX7xqlW2r2nxkiX+4EoUtzwHgAcsCAjdnCu81GcmvwFtPSWFwu\n1KEsSOvbPLqWPASwTfcMeXWV58jzttA7VhnflTM2uWge/6KjJaE3UY0EFTYYNmzr\nCng0VL7kgmyx/S2+3I7SM4+cu6Wn1cIAl6t9tE4YeDl6vGNutl1gKUEhAoGBALRn\nXUWLuLGifr7rfuSsfVCV20uYPLi5be69ZjVpKx7LVEaKE7GAcWlpt+1ZieM3ztkN\nEYlIUIL4bSeKxq2U8lJ+LAZKsr0mWJOmN8a8vswIwWyEB1zjDSRgmlSlQjAIPp9y\njPSGKyb13yP1JrxAeYzw3ceVCpOISCJVK/fHgpmPAoGBAN6CZcjc60uQjeTAxLeG\n1lOMqFgsKRl1qeIijLofhFkBmBSbg3/hfz/z3UyBkrRP1U29x4E/a91OaIxhxons\nNU5VxEd0O4TNIOE54QG3LIT4M+rF/KNQRgh83/L4dq/FYhzDja+mIB4oZKRVbWSI\n2M97W96hVxKhgxABfITHiPUW\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@venuemate-system.iam.gserviceaccount.com",
  "client_id": "111225914749007047570",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40venuemate-system.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

/// Handles all FCM v1 push notifications and Firestore notification documents.
///
/// ## Responsibilities
/// 1. **Token management** – save/refresh/remove FCM tokens in Firestore.
/// 2. **Send push** – call the FCM v1 HTTP API using a service-account OAuth2 token.
/// 3. **Firestore records** – create notification docs in `notifications/{id}`.
/// 4. **Read operations** – stream, mark-read, delete for the notification screens.
///
/// ## Usage (call once after login)
/// ```dart
/// await NotificationService.initAndSaveToken(uid: currentUser.uid);
/// ```
///
/// ## Sending a notification (call from action screens)
/// ```dart
/// await NotificationService.sendBookingConfirmed(
///   recipientUid : booking.customerId,
///   bookingId    : booking.bookingId,
///   hallName     : hall.hallName,
/// );
/// ```
class NotificationService {
  // ── Singletons ─────────────────────────────────────────────────────────────
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  // ── FCM v1 endpoint ────────────────────────────────────────────────────────
  static const String _projectId = 'venuemate-system';
  static const String _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  static const List<String> _fcmScopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  // ════════════════════════════════════════════════════════════════════════════
  //  1. TOKEN MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════

  /// Request permission, get the FCM token, and save it to Firestore.
  ///
  /// Call this right after a successful login (in LoginScreen / GoogleSignIn).
  ///
  /// ```dart
  /// await NotificationService.initAndSaveToken(uid: userModel.uid);
  /// ```
  static Future<void> initAndSaveToken({required String uid}) async {
    try {
      // 1. Request permission (iOS + web; Android grants automatically)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ FCM: Notification permission denied by user.');
        return;
      }

      // 2. Get token
      String? token;
      if (kIsWeb) {
        // Web requires the VAPID key from Firebase Console →
        // Project Settings → Cloud Messaging → Web configuration
        token = await _messaging.getToken(
          vapidKey: 'BAfms5uRGzpVU6lhFeMrLRjfDnJMdyTM3J076hfmzYjmFbAgGz4NZNynzHu47ZAlzEUOxThg2z2ftclxZ6veCrM',
        );
      } else {
        token = await _messaging.getToken();
      }

      if (token == null) {
        print('❌ FCM: Could not retrieve token.');
        return;
      }

      // 3. Save token to Firestore users/{uid}.fcmToken
      await _saveTokenToFirestore(uid: uid, token: token);

      // 4. Listen for token refresh (device re-registration)
      _messaging.onTokenRefresh.listen((newToken) async {
        await _saveTokenToFirestore(uid: uid, token: newToken);
        print('🔄 FCM: Token refreshed and saved.');
      });

      print('✅ FCM: Token saved for uid=$uid');
    } catch (e) {
      print('❌ FCM initAndSaveToken error: $e');
    }
  }

  /// Persist the FCM token in Firestore under `users/{uid}`.
  static Future<void> _saveTokenToFirestore({
    required String uid,
    required String token,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove the FCM token on logout so the user stops receiving pushes.
  ///
  /// Call this inside [AuthService.signOut] (or right before it).
  ///
  /// ```dart
  /// await NotificationService.removeToken(uid: AuthService.currentUid!);
  /// await AuthService.signOut();
  /// ```
  static Future<void> removeToken({required String uid}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      print('✅ FCM: Token removed for uid=$uid');
    } catch (e) {
      print('❌ FCM removeToken error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  2. INTERNAL: GET OAUTH2 ACCESS TOKEN
  // ════════════════════════════════════════════════════════════════════════════

  /// Exchanges the service-account JSON for a short-lived OAuth2 Bearer token
  /// required by the FCM v1 HTTP API.
  static Future<String?> _getAccessToken() async {
    try {
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        json.decode(_serviceAccountJson),
      );
      final client = await auth.clientViaServiceAccount(
        accountCredentials,
        _fcmScopes,
      );
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      print('❌ FCM: Failed to get access token: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  3. INTERNAL: SEND A PUSH NOTIFICATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Fetches the recipient's FCM token from Firestore, then calls the
  /// FCM v1 HTTP API to send the push notification.
  ///
  /// Also creates a Firestore document in `notifications/` so the in-app
  /// notification screen can display it.
  ///
  /// Returns `true` on success, `false` on any failure.
  static Future<bool> _sendNotification({
    required String recipientUid,
    required String title,
    required String body,
    required NotificationType type,
    String referenceId = '',
    String referenceType = '',
  }) async {
    try {
      // ── Step 1: Write to Firestore (in-app notification) ───────────────────
      final docRef = _notificationsRef.doc();
      final notification = NotificationModel(
        notificationId: docRef.id,
        userId: recipientUid,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        referenceType: referenceType,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await docRef.set(notification.toMap());

      // ── Step 2: Fetch recipient's FCM token ────────────────────────────────
      final userDoc =
          await _firestore.collection('users').doc(recipientUid).get();
      if (!userDoc.exists) {
        print('⚠️ FCM: Recipient user doc not found (uid=$recipientUid).');
        return true; // Firestore doc was saved; push is just unavailable
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ FCM: No FCM token for uid=$recipientUid. Push skipped.');
        return true; // in-app notification saved; push skipped gracefully
      }

      // ── Step 3: Get OAuth2 Bearer token ───────────────────────────────────
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      // ── Step 4: POST to FCM v1 API ─────────────────────────────────────────
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'type': type.value,
            'referenceId': referenceId,
            'referenceType': referenceType,
            'notificationId': docRef.id,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'venuemate_channel',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ FCM: Push sent to uid=$recipientUid | type=${type.value}');
        return true;
      } else {
        print('❌ FCM: HTTP ${response.statusCode} – ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ FCM _sendNotification error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  4. PUBLIC SEND METHODS  (one per business event)
  // ════════════════════════════════════════════════════════════════════════════

  // ── Booking ─────────────────────────────────────────────────────────────────

  /// Notify hall admin that a new booking has been received.
  static Future<bool> sendBookingReceived({
    required String hallAdminUid,
    required String bookingId,
    required String customerName,
    required String eventDate,
  }) =>
      _sendNotification(
        recipientUid: hallAdminUid,
        title: 'New Booking Request',
        body: '$customerName has requested a booking for $eventDate.',
        type: NotificationType.bookingReceived,
        referenceId: bookingId,
        referenceType: 'booking',
      );

  /// Notify customer that their booking has been confirmed.
  static Future<bool> sendBookingConfirmed({
    required String customerUid,
    required String bookingId,
    required String hallName,
    required String eventDate,
  }) =>
      _sendNotification(
        recipientUid: customerUid,
        title: 'Booking Confirmed! 🎉',
        body: 'Your booking at $hallName for $eventDate has been confirmed.',
        type: NotificationType.bookingConfirmed,
        referenceId: bookingId,
        referenceType: 'booking',
      );

  /// Notify customer that their booking has been rejected.
  static Future<bool> sendBookingRejected({
    required String customerUid,
    required String bookingId,
    required String hallName,
    String reason = '',
  }) =>
      _sendNotification(
        recipientUid: customerUid,
        title: 'Booking Rejected',
        body: reason.isNotEmpty
            ? 'Your booking at $hallName was rejected. Reason: $reason'
            : 'Your booking at $hallName could not be confirmed.',
        type: NotificationType.bookingRejected,
        referenceId: bookingId,
        referenceType: 'booking',
      );

  /// Notify hall admin that a customer has cancelled their booking.
  static Future<bool> sendBookingCancelled({
    required String hallAdminUid,
    required String bookingId,
    required String customerName,
    required String eventDate,
  }) =>
      _sendNotification(
        recipientUid: hallAdminUid,
        title: 'Booking Cancelled',
        body: '$customerName has cancelled their booking for $eventDate.',
        type: NotificationType.bookingCancelled,
        referenceId: bookingId,
        referenceType: 'booking',
      );

  // ── Payment ─────────────────────────────────────────────────────────────────

  /// Notify hall admin that a customer has uploaded a payment receipt.
  static Future<bool> sendPaymentUploaded({
    required String hallAdminUid,
    required String bookingId,
    required String customerName,
    required String amount,
  }) =>
      _sendNotification(
        recipientUid: hallAdminUid,
        title: 'Payment Receipt Uploaded',
        body: '$customerName uploaded a payment receipt of Rs. $amount.',
        type: NotificationType.paymentUploaded,
        referenceId: bookingId,
        referenceType: 'payment',
      );

  /// Notify customer that their payment has been approved.
  static Future<bool> sendPaymentApproved({
    required String customerUid,
    required String bookingId,
    required String hallName,
  }) =>
      _sendNotification(
        recipientUid: customerUid,
        title: 'Payment Approved',
        body: 'Your payment for the booking at $hallName has been approved.',
        type: NotificationType.paymentApproved,
        referenceId: bookingId,
        referenceType: 'payment',
      );

  /// Notify customer that their payment was rejected.
  static Future<bool> sendPaymentRejected({
    required String customerUid,
    required String bookingId,
    required String hallName,
    String reason = '',
  }) =>
      _sendNotification(
        recipientUid: customerUid,
        title: 'Payment Rejected',
        body: reason.isNotEmpty
            ? 'Your payment at $hallName was rejected. Reason: $reason'
            : 'Your payment for the booking at $hallName was not accepted.',
        type: NotificationType.paymentRejected,
        referenceId: bookingId,
        referenceType: 'payment',
      );

  /// Notify customer that a refund has been processed.
  static Future<bool> sendRefundProcessed({
    required String customerUid,
    required String bookingId,
    required String amount,
  }) =>
      _sendNotification(
        recipientUid: customerUid,
        title: 'Refund Processed',
        body: 'A refund of Rs. $amount has been initiated for your booking.',
        type: NotificationType.refundProcessed,
        referenceId: bookingId,
        referenceType: 'payment',
      );

  // ── Hall Registration ────────────────────────────────────────────────────────

  /// Notify system admin that a new hall registration was submitted.
  static Future<bool> sendRegistrationSubmitted({
    required String systemAdminUid,
    required String hallId,
    required String hallName,
    required String ownerName,
  }) =>
      _sendNotification(
        recipientUid: systemAdminUid,
        title: 'New Hall Registration',
        body: '$ownerName has submitted "$hallName" for review.',
        type: NotificationType.registrationSubmitted,
        referenceId: hallId,
        referenceType: 'hall',
      );

  /// Notify venue owner that their hall has been approved.
  static Future<bool> sendHallApproved({
    required String venueOwnerUid,
    required String hallId,
    required String hallName,
  }) =>
      _sendNotification(
        recipientUid: venueOwnerUid,
        title: 'Hall Approved!',
        body:
            'Congratulations! "$hallName" is now live on VenueMate.',
        type: NotificationType.hallApproved,
        referenceId: hallId,
        referenceType: 'hall',
      );

  /// Notify venue owner that their hall registration was rejected.
  static Future<bool> sendHallRejected({
    required String venueOwnerUid,
    required String hallId,
    required String hallName,
    String reason = '',
  }) =>
      _sendNotification(
        recipientUid: venueOwnerUid,
        title: 'Hall Registration Rejected',
        body: reason.isNotEmpty
            ? '"$hallName" was rejected. Reason: $reason'
            : '"$hallName" did not pass the review. Please check and resubmit.',
        type: NotificationType.hallRejected,
        referenceId: hallId,
        referenceType: 'hall',
      );

  // ── Messaging ───────────────────────────────────────────────────────────────

  /// Notify a user that they have received a new chat message.
  static Future<bool> sendNewMessage({
    required String recipientUid,
    required String conversationId,
    required String senderName,
    required String messagePreview,
  }) =>
      _sendNotification(
        recipientUid: recipientUid,
        title: senderName,
        body: messagePreview.length > 80
            ? '${messagePreview.substring(0, 80)}…'
            : messagePreview,
        type: NotificationType.newMessage,
        referenceId: conversationId,
        referenceType: 'message',
      );

  // ── Complaints ──────────────────────────────────────────────────────────────

  /// Notify system admin that a user filed a complaint.
  static Future<bool> sendComplaintFiled({
    required String systemAdminUid,
    required String complaintId,
    required String filedByName,
    required String subject,
  }) =>
      _sendNotification(
        recipientUid: systemAdminUid,
        title: 'New Complaint Filed',
        body: '$filedByName filed a complaint: "$subject".',
        type: NotificationType.complaintFiled,
        referenceId: complaintId,
        referenceType: 'complaint',
      );

  /// Notify user that their complaint has been resolved.
  static Future<bool> sendComplaintResolved({
    required String userUid,
    required String complaintId,
    required String subject,
  }) =>
      _sendNotification(
        recipientUid: userUid,
        title: 'Complaint Resolved',
        body: 'Your complaint regarding "$subject" has been resolved.',
        type: NotificationType.complaintResolved,
        referenceId: complaintId,
        referenceType: 'complaint',
      );

  // ════════════════════════════════════════════════════════════════════════════
  //  5. FIRESTORE READ OPERATIONS  (used by notification screens)
  // ════════════════════════════════════════════════════════════════════════════

  /// Stream all notifications for a user, newest first.
  ///
  /// ```dart
  /// NotificationService.streamNotifications(uid: currentUser.uid)
  ///   .listen((list) { setState(() => _notifications = list); });
  /// ```
  static Stream<List<NotificationModel>> streamNotifications({
    required String uid,
  }) {
    return _notificationsRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => NotificationModel.fromDoc(doc)).toList());
  }

  /// Stream the count of unread notifications (used for the badge in AppBar).
  static Stream<int> streamUnreadCount({required String uid}) {
    return _notificationsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a single notification as read.
  static Future<void> markAsRead({required String notificationId}) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('FCM markAsRead error: $e');
    }
  }

  /// Mark ALL notifications for a user as read.
  static Future<void> markAllAsRead({required String uid}) async {
    try {
      final snap = await _notificationsRef
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('FCM markAllAsRead error: $e');
    }
  }

  /// Delete a single notification document.
  static Future<void> deleteNotification({
    required String notificationId,
  }) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      print('FCM deleteNotification error: $e');
    }
  }
}