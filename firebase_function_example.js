// Firebase Cloud Function for DoodleMate Session Cleanup
// This file should be deployed to Firebase Functions for automatic cleanup

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Runs every day at midnight UTC
exports.cleanupOldSessions = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.database();
    const now = Date.now();
    const sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000); // 7 days in milliseconds
    
    console.log('Starting cleanup of sessions older than', new Date(sevenDaysAgo));
    
    try {
      const snapshot = await db.ref('sessions').once('value');
      const sessions = snapshot.val();
      
      if (!sessions) {
        console.log('No sessions found');
        return null;
      }
      
      const deletions = [];
      let cleanupCount = 0;
      
      for (const [sessionId, sessionData] of Object.entries(sessions)) {
        if (sessionData && sessionData.lastActivity && sessionData.lastActivity < sevenDaysAgo) {
          console.log(`Marking session ${sessionId} for cleanup (last activity: ${new Date(sessionData.lastActivity)})`);
          deletions.push(db.ref(`sessions/${sessionId}`).remove());
          cleanupCount++;
        }
      }
      
      if (deletions.length > 0) {
        await Promise.all(deletions);
        console.log(`Successfully cleaned up ${cleanupCount} old sessions`);
      } else {
        console.log('No old sessions found for cleanup');
      }
      
      return null;
    } catch (error) {
      console.error('Error cleaning up sessions:', error);
      return null;
    }
  });

// Optional: Manual cleanup function (can be called via HTTP)
exports.manualCleanup = functions.https.onRequest(async (req, res) => {
  const db = admin.database();
  const now = Date.now();
  const sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
  
  try {
    const snapshot = await db.ref('sessions').once('value');
    const sessions = snapshot.val();
    
    if (!sessions) {
      res.json({ message: 'No sessions found', cleanedUp: 0 });
      return;
    }
    
    const deletions = [];
    let cleanupCount = 0;
    
    for (const [sessionId, sessionData] of Object.entries(sessions)) {
      if (sessionData && sessionData.lastActivity && sessionData.lastActivity < sevenDaysAgo) {
        deletions.push(db.ref(`sessions/${sessionId}`).remove());
        cleanupCount++;
      }
    }
    
    if (deletions.length > 0) {
      await Promise.all(deletions);
    }
    
    res.json({ 
      message: `Cleanup completed successfully`, 
      cleanedUp: cleanupCount,
      totalSessions: Object.keys(sessions).length
    });
  } catch (error) {
    console.error('Error in manual cleanup:', error);
    res.status(500).json({ error: 'Cleanup failed', details: error.message });
  }
});

// Health check function
exports.healthCheck = functions.https.onRequest((req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'DoodleMate Cleanup Service'
  });
});