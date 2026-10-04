package com.linxphotos.photo_finder

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val photoFinderChannel = PhotoFinderChannel(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        photoFinderChannel.attachToActivity(this)
        photoFinderChannel.ingestShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        photoFinderChannel.ingestShareIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        photoFinderChannel.attachToActivity(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PhotoFinderChannel.CHANNEL)
            .setMethodCallHandler(photoFinderChannel)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!photoFinderChannel.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
