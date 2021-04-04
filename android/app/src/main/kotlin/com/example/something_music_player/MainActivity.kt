package com.example.something_music_player

import android.media.MediaScannerConnection
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "temposcape.flutter/refresh"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "refreshMediaStore") {
                val refresh = refreshMediaStore(call.argument<List<String>>("path"))
                result.success(refresh)
            } else {
                result.notImplemented()
            }
        }
    }


    private fun refreshMediaStore(fileDir: List<String>?): List<String>? {
        MediaScannerConnection.scanFile(context, fileDir?.toTypedArray(), null, null)

        return fileDir
    }
}