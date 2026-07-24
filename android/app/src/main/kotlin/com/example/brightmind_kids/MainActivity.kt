package com.example.brightmind_kids

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        applyTransparentNavBar()
        // On cold start, Flutter's own Dart-side SystemChrome edge-to-edge call
        // lands after this and re-triggers a window-insets pass that can repaint
        // the nav bar black on some OEM skins. Reapply every time insets change
        // (not just once here or on onPostResume) so we always win, regardless
        // of whether Flutter's call happens before or after ours.
        window.decorView.setOnApplyWindowInsetsListener { view, insets ->
            applyTransparentNavBar()
            view.onApplyWindowInsets(insets)
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        applyTransparentNavBar()
    }

    private fun applyTransparentNavBar() {
        window.navigationBarColor = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }
}
