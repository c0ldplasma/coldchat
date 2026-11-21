package com.plasmari.coldchat

import android.content.ComponentName
import android.net.Uri
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsServiceConnection
import androidx.browser.customtabs.CustomTabsSession
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var connection: CustomTabsServiceConnection? = null
    private var session: CustomTabsSession? = null

    /** The URL the next [warmUp] should announce; also used once the service connects. */
    private var pendingUrl: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "coldchat/browser").setMethodCallHandler { call, result ->
            when (call.method) {
                "warmUp" -> {
                    warmUp(call.argument<String>("url")?.let(Uri::parse))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Starts the default browser's engine in the background and tells it [url] is likely opened next, so the login
     * Custom Tab opens faster. Binding to the browser's Custom Tabs service is all it takes; nothing is shown.
     */
    private fun warmUp(url: Uri?) {
        pendingUrl = url
        val current = session
        if (current != null) {
            current.mayLaunchUrl(url, null, null)
            return
        }
        if (connection != null) return // Still connecting; the URL is announced once connected.

        // The default browser if it supports Custom Tabs, which is the one the login opens in.
        val browser = CustomTabsClient.getPackageName(this, null) ?: return
        val newConnection = object : CustomTabsServiceConnection() {
            override fun onCustomTabsServiceConnected(name: ComponentName, client: CustomTabsClient) {
                client.warmup(0)
                session = client.newSession(null)?.also { it.mayLaunchUrl(pendingUrl, null, null) }
            }

            override fun onServiceDisconnected(name: ComponentName) {
                // The browser was stopped or updated; bind again on the next warm-up.
                session = null
                connection = null
            }
        }
        try {
            if (CustomTabsClient.bindCustomTabsService(this, browser, newConnection)) connection = newConnection
        } catch (e: SecurityException) {
            // A browser that doesn't export its service; the login still works, just without the head start.
        }
    }

    override fun onDestroy() {
        connection?.let {
            try {
                unbindService(it)
            } catch (e: IllegalArgumentException) {
                // Already unbound by the system.
            }
        }
        connection = null
        session = null
        super.onDestroy()
    }
}
