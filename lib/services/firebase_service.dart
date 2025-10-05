import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/drawing_stroke.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription? _strokesSubscription;
  StreamSubscription? _undoSubscription;

  // Listen to strokes in a session
  Stream<List<DrawingStroke>> getStrokesStream(String sessionId) {
    return _database
        .ref('sessions/$sessionId/strokes')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <DrawingStroke>[];
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final strokes = <DrawingStroke>[];
      
      data.forEach((key, value) {
        if (value is Map) {
          try {
            final stroke = DrawingStroke.fromJson(Map<String, dynamic>.from(value));
            if (!stroke.deleted) {
              strokes.add(stroke);
            }
          } catch (e) {
            print('Error parsing stroke: $e');
          }
        }
      });
      
      // Sort by timestamp
      strokes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return strokes;
    });
  }

  // Add a stroke to a session
  Future<void> addStroke(String sessionId, DrawingStroke stroke) async {
    try {
      await _database
          .ref('sessions/$sessionId/strokes/${stroke.id}')
          .set(stroke.toJson());
      
      // Update session timestamp
      await _updateSessionTimestamp(sessionId);
    } catch (e) {
      print('Error adding stroke: $e');
      rethrow;
    }
  }

  // Mark a stroke as deleted (undo)
  Future<void> deleteStroke(String sessionId, String strokeId) async {
    try {
      await _database
          .ref('sessions/$sessionId/strokes/$strokeId/deleted')
          .set(true);
      
      await _updateSessionTimestamp(sessionId);
    } catch (e) {
      print('Error deleting stroke: $e');
      rethrow;
    }
  }

  // Clear all strokes in a session
  Future<void> clearSession(String sessionId) async {
    try {
      // Mark all strokes as deleted instead of removing them
      final snapshot = await _database
          .ref('sessions/$sessionId/strokes')
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final batch = <String, dynamic>{};
        
        data.forEach((key, value) {
          batch['sessions/$sessionId/strokes/$key/deleted'] = true;
        });
        
        await _database.ref().update(batch);
      }
      
      await _updateSessionTimestamp(sessionId);
    } catch (e) {
      print('Error clearing session: $e');
      rethrow;
    }
  }

  // Create a new session
  Future<void> createSession(String sessionId, String userId) async {
    try {
      await _database.ref('sessions/$sessionId').set({
        'createdBy': userId,
        'createdAt': ServerValue.timestamp,
        'lastActivity': ServerValue.timestamp,
        'strokes': {},
      });
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  // Check if session exists
  Future<bool> sessionExists(String sessionId) async {
    try {
      final snapshot = await _database.ref('sessions/$sessionId').get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }

  // Update session timestamp for cleanup purposes
  Future<void> _updateSessionTimestamp(String sessionId) async {
    try {
      await _database
          .ref('sessions/$sessionId/lastActivity')
          .set(ServerValue.timestamp);
    } catch (e) {
      print('Error updating session timestamp: $e');
    }
  }

  // Get the last stroke ID for undo functionality
  Future<String?> getLastStrokeId(String sessionId, String userId) async {
    try {
      final snapshot = await _database
          .ref('sessions/$sessionId/strokes')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(1)
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final strokeData = data.values.first;
        if (strokeData['deleted'] != true) {
          return data.keys.first;
        }
      }
      return null;
    } catch (e) {
      print('Error getting last stroke: $e');
      return null;
    }
  }

  void dispose() {
    _strokesSubscription?.cancel();
    _undoSubscription?.cancel();
  }
}