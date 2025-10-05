import 'package:firebase_database/firebase_database.dart';

class CleanupService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // This method would ideally be called by a Firebase Cloud Function
  // For demonstration, it shows how to clean up old sessions
  static Future<void> cleanupOldSessions() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final threshold = sevenDaysAgo.millisecondsSinceEpoch;

      final snapshot = await _database.ref('sessions').get();
      
      if (!snapshot.exists) return;

      final sessions = Map<String, dynamic>.from(snapshot.value as Map);
      final batch = <String, dynamic>{};

      sessions.forEach((sessionId, sessionData) {
        if (sessionData is Map) {
          final lastActivity = sessionData['lastActivity'];
          if (lastActivity != null && lastActivity < threshold) {
            // Mark session for deletion
            batch['sessions/$sessionId'] = null;
            print('Marking session $sessionId for cleanup');
          }
        }
      });

      if (batch.isNotEmpty) {
        await _database.ref().update(batch);
        print('Cleaned up ${batch.length} old sessions');
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  // Set up database rules for automatic cleanup
  // This is example Firebase Realtime Database rules that would go in Firebase Console
  static String get databaseRules => '''
{
  "rules": {
    "sessions": {
      "\$sessionId": {
        ".read": true,
        ".write": true,
        "strokes": {
          "\$strokeId": {
            ".validate": "newData.hasChildren(['id', 'userId', 'color', 'width', 'points', 'timestamp'])"
          }
        },
        ".indexOn": ["lastActivity", "createdAt"]
      }
    }
  }
}
''';

  // Firebase Cloud Function code (would be deployed separately)
  static String get cloudFunctionCode => '''
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Runs every day at midnight
exports.cleanupOldSessions = functions.pubsub.schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.database();
    const now = Date.now();
    const sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
    
    try {
      const snapshot = await db.ref('sessions').once('value');
      const sessions = snapshot.val();
      
      if (!sessions) return null;
      
      const deletions = [];
      
      for (const [sessionId, sessionData] of Object.entries(sessions)) {
        if (sessionData.lastActivity < sevenDaysAgo) {
          deletions.push(db.ref(`sessions/\${sessionId}`).remove());
        }
      }
      
      if (deletions.length > 0) {
        await Promise.all(deletions);
        console.log(`Cleaned up \${deletions.length} old sessions`);
      }
      
      return null;
    } catch (error) {
      console.error('Error cleaning up sessions:', error);
      return null;
    }
  });
''';
}