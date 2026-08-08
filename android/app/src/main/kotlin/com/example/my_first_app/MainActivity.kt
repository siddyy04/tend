package com.example.my_first_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Keep the Activity intent current for singleTask warm-start shares.
        setIntent(intent)
    }
}
