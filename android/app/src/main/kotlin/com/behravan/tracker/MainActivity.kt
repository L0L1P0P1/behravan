package com.behravan.tracker
//
// import io.flutter.embedding.android.FlutterActivity
//
// class MainActivity : FlutterActivity()

// KEEP your original package declaration here!
// package com.example.behravan 

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity: FlutterActivity() {
    private val CHANNEL = "behravan/timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getTimeZoneName") {
                // Returns standard IANA format like "America/New_York"
                result.success(TimeZone.getDefault().id)
            } else {
                result.notImplemented()
            }
        }
    }
}
