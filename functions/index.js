const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const language = require("@google-cloud/language");

// Initialize Firebase Admin SDK to interact with Firestore
admin.initializeApp();

// Initialize the Google Cloud Natural Language client
const languageClient = new language.LanguageServiceClient();

/**
 * Cloud Function triggered automatically whenever a new document is created
 * in the 'mood_logs' collection.
 * 
 * Analyzes the 'note' field for emotional sentiment and writes the result
 * back to the same document under the 'sentiment_result' field.
 */
exports.analyzeMoodSentiment = onDocumentCreated({
  document: "mood_logs/{docId}",
  region: "us-central1" // You can change this to your preferred Firebase region (e.g., 'asia-east2')
}, async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.warn("No snapshot data found in the trigger event.");
    return null;
  }

  const docId = event.params.docId;
  const data = snapshot.data();
  const note = data.note;

  // 1. Production Optimization: Skip analysis if the note is empty or missing
  if (!note || typeof note !== "string" || note.trim() === "") {
    logger.info(`Document ${docId} has no journal note. Skipping sentiment analysis.`);
    
    // Set placeholder sentiment results
    await snapshot.ref.update({
      sentiment_result: {
        score: 0.0,
        magnitude: 0.0,
        label: "neutral",
        error: "No note provided for analysis.",
        analyzedAt: admin.firestore.FieldValue.serverTimestamp()
      }
    });
    return null;
  }

  logger.info(`Analyzing sentiment for document ID: ${docId}, note length: ${note.length}`);

  try {
    // 2. Prepare the document for the Natural Language API
    const document = {
      content: note,
      type: "PLAIN_TEXT",
    };

    // 3. Request sentiment analysis from Google Natural Language API
    const [result] = await languageClient.analyzeSentiment({ document });
    const sentiment = result.documentSentiment;

    if (!sentiment) {
      throw new Error("Natural Language API did not return document sentiment.");
    }

    // 4. Map the numeric score (-1.0 to 1.0) to a clear categorical label
    // Google API definition:
    // - Positive: score >= 0.25
    // - Negative: score <= -0.25
    // - Neutral: score in between
    let label = "neutral";
    if (sentiment.score >= 0.25) {
      label = "positive";
    } else if (sentiment.score <= -0.25) {
      label = "negative";
    }

    const sentimentResult = {
      score: parseFloat(sentiment.score.toFixed(3)),       // e.g. 0.850
      magnitude: parseFloat(sentiment.magnitude.toFixed(3)), // e.g. 1.200
      label: label,                                        // 'positive', 'negative', 'neutral'
      analyzedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    logger.info(`Analysis succeeded for ${docId}: Score=${sentimentResult.score}, Label=${label}`);

    // 5. Write the sentiment results back to the Firestore document
    await snapshot.ref.update({
      sentiment_result: sentimentResult
    });

    return null;
  } catch (error) {
    logger.error(`Error performing sentiment analysis for document ${docId}:`, error);

    // Save error information in the document to prevent infinite retry loops
    // and notify the front-end that analysis failed.
    await snapshot.ref.update({
      sentiment_result: {
        score: 0.0,
        magnitude: 0.0,
        label: "unknown",
        error: error.message || "Unknown error during sentiment analysis.",
        analyzedAt: admin.firestore.FieldValue.serverTimestamp()
      }
    });

    return null;
  }
});
