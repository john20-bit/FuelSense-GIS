package com.example.fuelsense_mobile

import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "fuelsense/native_speech"
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var speechChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        speechChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        speechChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    startNativeListening()
                    result.success(true)
                }

                "stopListening" -> {
                    stopNativeListening()
                    result.success(true)
                }

                "isAvailable" -> {
                    result.success(
                        SpeechRecognizer.isRecognitionAvailable(this)
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startNativeListening() {
        stopNativeListening()

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            speechChannel?.invokeMethod(
                "onError",
                mapOf(
                    "code" to "NOT_AVAILABLE",
                    "message" to "Speech recognition is not available."
                )
            )
            return
        }

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)

        speechRecognizer?.setRecognitionListener(
            object : RecognitionListener {

                override fun onReadyForSpeech(params: Bundle?) {
                    speechChannel?.invokeMethod("onReady", null)
                }

                override fun onBeginningOfSpeech() {
                    speechChannel?.invokeMethod("onBeginning", null)
                }

                override fun onRmsChanged(rmsdB: Float) {
                    speechChannel?.invokeMethod(
                        "onRms",
                        rmsdB.toDouble()
                    )
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    // Audio buffers are intentionally not exposed to Flutter.
                }

                override fun onEndOfSpeech() {
                    speechChannel?.invokeMethod("onEnd", null)
                }

                override fun onError(error: Int) {
                    speechChannel?.invokeMethod(
                        "onError",
                        mapOf(
                            "code" to error,
                            "message" to speechErrorMessage(error)
                        )
                    )
                }

                override fun onResults(results: Bundle?) {
                    val matches =
                        results?.getStringArrayList(
                            SpeechRecognizer.RESULTS_RECOGNITION
                        )

                    val transcript =
                        matches?.firstOrNull()?.trim().orEmpty()

                    speechChannel?.invokeMethod(
                        "onResults",
                        mapOf(
                            "text" to transcript
                        )
                    )
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches =
                        partialResults?.getStringArrayList(
                            SpeechRecognizer.RESULTS_RECOGNITION
                        )

                    val transcript =
                        matches?.firstOrNull()?.trim().orEmpty()

                    if (transcript.isNotEmpty()) {
                        speechChannel?.invokeMethod(
                            "onPartialResults",
                            mapOf(
                                "text" to transcript
                            )
                        )
                    }
                }

                override fun onEvent(
                    eventType: Int,
                    params: Bundle?
                ) {
                    // Reserved for recognizer-specific events.
                }

                override fun onLanguageDetection(
                    results: Bundle
                ) {
                    val detectedLanguage =
                        results.getString(
                            "android.speech.extra.DETECTED_LANGUAGE"
                        )

                    val confidence =
                        results.getInt(
                            "android.speech.extra.LANGUAGE_DETECTION_CONFIDENCE_LEVEL",
                            0
                        )

                    speechChannel?.invokeMethod(
                        "onLanguageDetected",
                        mapOf(
                            "language" to (detectedLanguage ?: ""),
                            "confidence" to confidence
                        )
                    )
                }
            }
        )

        val intent = Intent(
            RecognizerIntent.ACTION_RECOGNIZE_SPEECH
        ).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )

            putExtra(
                RecognizerIntent.EXTRA_PARTIAL_RESULTS,
                true
            )

            /*
             * Android 14+ language detection.
             */
            if (android.os.Build.VERSION.SDK_INT >= 34) {
                putExtra(
                    RecognizerIntent.EXTRA_ENABLE_LANGUAGE_DETECTION,
                    true
                )

                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_DETECTION_ALLOWED_LANGUAGES,
                    arrayListOf(
                        "en-IN",
                        "hi-IN",
                        "ta-IN",
                        "te-IN",
                        "ml-IN",
                        "kn-IN"
                    )
                )

                /*
                 * Let Android automatically switch between the
                 * allowed languages while the user is speaking.
                 */
                putExtra(
                    RecognizerIntent.EXTRA_ENABLE_LANGUAGE_SWITCH,
                    RecognizerIntent.LANGUAGE_SWITCH_BALANCED
                )

                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_SWITCH_ALLOWED_LANGUAGES,
                    arrayListOf(
                        "en-IN",
                        "hi-IN",
                        "ta-IN",
                        "te-IN",
                        "ml-IN",
                        "kn-IN"
                    )
                )
            } else {
                /*
                 * Older Android fallback.
                 */
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE,
                    "en-IN"
                )
            }
        }

        speechRecognizer?.startListening(intent)
    }

    private fun stopNativeListening() {
        speechRecognizer?.stopListening()
        speechRecognizer?.cancel()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }

    private fun speechErrorMessage(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO ->
                "Audio recording error."

            SpeechRecognizer.ERROR_CLIENT ->
                "Speech recognition client error."

            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
                "Microphone permission is required."

            SpeechRecognizer.ERROR_NETWORK ->
                "Speech recognition network error."

            SpeechRecognizer.ERROR_NETWORK_TIMEOUT ->
                "Speech recognition network timeout."

            SpeechRecognizer.ERROR_NO_MATCH ->
                "No speech was recognized."

            SpeechRecognizer.ERROR_RECOGNIZER_BUSY ->
                "Speech recognizer is busy."

            SpeechRecognizer.ERROR_SERVER ->
                "Speech recognition server error."

            SpeechRecognizer.ERROR_SPEECH_TIMEOUT ->
                "No speech was detected."

            else ->
                "Speech recognition failed."
        }
    }

    override fun onDestroy() {
        stopNativeListening()
        super.onDestroy()
    }
}
