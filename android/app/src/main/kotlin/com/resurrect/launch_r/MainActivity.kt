package com.resurrect.launch_r

import android.app.ActivityOptions
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.AdaptiveIconDrawable
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sign
import kotlin.math.sin

class MainActivity : FlutterActivity() {

    private val channelName = "com.resurrect.launch_r/launcher"
    private var channel: MethodChannel? = null
    private var receiverRegistered = false
    private val io = Executors.newFixedThreadPool(3)

    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            channel?.invokeMethod("onPackagesChanged", null)
        }
    }

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result -> handle(call, result) }

        if (!receiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_PACKAGE_ADDED)
                addAction(Intent.ACTION_PACKAGE_REMOVED)
                addAction(Intent.ACTION_PACKAGE_REPLACED)
                addAction(Intent.ACTION_PACKAGE_CHANGED)
                addDataScheme("package")
            }
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(packageReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(packageReceiver, filter)
            }
            receiverRegistered = true
        }

        LaunchRNotificationListener.onChange = {
            runOnUiThread { ch.invokeMethod("onBadges", LaunchRNotificationListener.counts) }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            channel?.invokeMethod("onHome", null)
        }
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            try { unregisterReceiver(packageReceiver) } catch (_: Exception) {}
            receiverRegistered = false
        }
        LaunchRNotificationListener.onChange = null
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "getApps" -> io.execute {
                val pm = packageManager
                val query = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                val seen = HashSet<String>()
                val out = ArrayList<Map<String, String>>()
                for (ri in pm.queryIntentActivities(query, 0)) {
                    val pkg = ri.activityInfo.packageName
                    if (pkg == packageName || !seen.add(pkg)) continue
                    out.add(mapOf("package" to pkg, "label" to ri.loadLabel(pm).toString()))
                }
                runOnUiThread { result.success(out) }
            }

            "getIcon" -> {
                val pkg = call.argument<String>("package")
                val size = call.argument<Int>("size") ?: 192
                val shape = call.argument<String>("shape") ?: "squircle"
                if (pkg == null) { result.success(null); return }
                io.execute {
                    val bytes = try { renderIcon(pkg, size, shape) } catch (_: Throwable) { null }
                    runOnUiThread { result.success(bytes) }
                }
            }

            "launchApp" -> {
                val pkg = call.argument<String>("package")
                val intent = pkg?.let { packageManager.getLaunchIntentForPackage(it) }
                if (intent == null) { result.success(false); return }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                try {
                    val l = call.argument<Int>("left")
                    val t = call.argument<Int>("top")
                    val w = call.argument<Int>("width")
                    val h = call.argument<Int>("height")
                    if (l != null && t != null && w != null && h != null) {
                        val opts = ActivityOptions.makeScaleUpAnimation(window.decorView, l, t, w, h)
                        startActivity(intent, opts.toBundle())
                    } else {
                        startActivity(intent)
                    }
                    result.success(true)
                } catch (_: Exception) {
                    result.success(false)
                }
            }

            "openAppInfo" -> {
                val pkg = call.argument<String>("package")
                if (pkg != null) {
                    startActivity(
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                }
                result.success(null)
            }

            "uninstallApp" -> {
                val pkg = call.argument<String>("package")
                if (pkg != null) {
                    startActivity(
                        Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                }
                result.success(null)
            }

            "getDefaultDock" -> {
                val intents = listOf(
                    Intent(Intent.ACTION_DIAL),
                    Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")),
                    Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")),
                    Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                )
                val out = ArrayList<String>()
                for (i in intents) {
                    val pkg = packageManager.resolveActivity(i, 0)?.activityInfo?.packageName
                    if (pkg != null && pkg != "android" && pkg != packageName && !out.contains(pkg)) out.add(pkg)
                }
                result.success(out)
            }

            "getBadges" -> result.success(LaunchRNotificationListener.counts)

            "hasNotificationAccess" -> {
                val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                result.success(flat?.contains(packageName) == true)
            }

            "openNotificationAccessSettings" -> {
                startActivity(
                    Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(null)
            }

            "openHomeSettings" -> {
                try {
                    startActivity(Intent(Settings.ACTION_HOME_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                } catch (_: Exception) {
                    startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
                result.success(null)
            }

            "openWallpaperPicker" -> {
                try {
                    startActivity(
                        Intent.createChooser(Intent(Intent.ACTION_SET_WALLPAPER), "Wallpaper")
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                } catch (_: Exception) {
                }
                result.success(null)
            }

            "expandNotifications" -> {
                try {
                    val sbm = getSystemService("statusbar")
                    Class.forName("android.app.StatusBarManager")
                        .getMethod("expandNotificationsPanel")
                        .invoke(sbm)
                } catch (_: Exception) {
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun renderIcon(pkg: String, size: Int, shape: String): ByteArray {
        val drawable = packageManager.getApplicationIcon(pkg)
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = size.toFloat()
        val layer = canvas.saveLayer(0f, 0f, s, s, null)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && drawable is AdaptiveIconDrawable) {
            val pad = (size * 0.25f).toInt()
            val bounds = Rect(-pad, -pad, size + pad, size + pad)
            drawable.background?.let { it.bounds = bounds; it.draw(canvas) }
            drawable.foreground?.let { it.bounds = bounds; it.draw(canvas) }
        } else {
            canvas.drawColor(0xFFF2F2F2.toInt())
            val inset = (size * 0.16f).toInt()
            drawable.setBounds(inset, inset, size - inset, size - inset)
            drawable.draw(canvas)
        }

        val outside = shapePath(shape, s).apply { fillType = Path.FillType.INVERSE_WINDING }
        val eraser = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
        }
        canvas.drawPath(outside, eraser)
        canvas.restoreToCount(layer)

        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun shapePath(shape: String, s: Float): Path = when (shape) {
        "circle" -> Path().apply { addOval(RectF(0f, 0f, s, s), Path.Direction.CW) }
        "rounded" -> roundRectPath(s, s * 0.24f)
        "square" -> roundRectPath(s, s * 0.08f)
        "teardrop" -> Path().apply {
            val big = s / 2f
            val small = s * 0.12f
            addRoundRect(
                RectF(0f, 0f, s, s),
                floatArrayOf(big, big, big, big, small, small, big, big),
                Path.Direction.CW,
            )
        }
        else -> squirclePath(s)
    }

    private fun roundRectPath(s: Float, r: Float): Path =
        Path().apply { addRoundRect(RectF(0f, 0f, s, s), r, r, Path.Direction.CW) }

    private fun squirclePath(size: Float): Path {
        val r = size / 2f
        val n = 4.6
        val steps = 160
        val path = Path()
        for (i in 0..steps) {
            val t = 2.0 * Math.PI * i / steps
            val c = cos(t)
            val sn = sin(t)
            val x = r + r * (sign(c) * abs(c).pow(2.0 / n)).toFloat()
            val y = r + r * (sign(sn) * abs(sn).pow(2.0 / n)).toFloat()
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        return path
    }
}
