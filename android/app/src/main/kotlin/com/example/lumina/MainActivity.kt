package com.example.lumina

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.DisplayMetrics

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val metrics: DisplayMetrics = resources.displayMetrics
        metrics.density = 280f / 160f
        metrics.scaledDensity = 28f / 160f
        metrics.densityDpi = 280
    }
}
