package com.resurrect.launch_r

import android.app.ActivityOptions
import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.Drawable
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

    private val widgetHost by lazy { AppWidgetHost(this, WIDGET_HOST_ID) }
    private val widgetManager by lazy { AppWidgetManager.getInstance(this) }
    private var pendingWidget: PendingWidget? = null

    @Volatile private var iconPack: IconPack? = null
    @Volatile private var iconPackPkg: String? = null

    private class PendingWidget(
        val id: Int,
        val info: AppWidgetProviderInfo,
        val result: MethodChannel.Result,
    )

    companion object {
        private const val WIDGET_HOST_ID = 1024
        private const val WIDGET_VIEW_TYPE = "com.resurrect.launch_r/widget"
        private const val REQ_BIND_WIDGET = 7001
        private const val REQ_CONFIGURE_WIDGET = 7002
    }

    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action
            val changed = intent?.data?.schemeSpecificPart
            val active = iconPackPkg
            if (active != null && changed == active) {
                if (action == Intent.ACTION_PACKAGE_REMOVED) {
                    if (intent?.getBooleanExtra(Intent.EXTRA_REPLACING, false) == true) return
                    iconPack = null
                    channel?.invokeMethod("onPackagesChanged", null)
                } else {
                    io.execute {
                        iconPack = IconPack.load(this@MainActivity, active)
                        runOnUiThread { channel?.invokeMethod("onPackagesChanged", null) }
                    }
                }
                return
            }
            channel?.invokeMethod("onPackagesChanged", null)
        }
    }

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result -> handle(call, result) }

        flutterEngine.platformViewsController.registry.registerViewFactory(
            WIDGET_VIEW_TYPE,
            LaunchRWidgetFactory(this, widgetHost, widgetManager),
        )

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

    override fun onStart() {
        super.onStart()
        try { widgetHost.startListening() } catch (_: Exception) {}
    }

    override fun onStop() {
        try { widgetHost.stopListening() } catch (_: Exception) {}
        super.onStop()
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            REQ_BIND_WIDGET -> {
                if (resultCode == RESULT_OK) continueWidgetAfterBind() else finishPendingWidget(false)
                return
            }
            REQ_CONFIGURE_WIDGET -> {
                finishPendingWidget(resultCode == RESULT_OK)
                return
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
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
        pendingWidget?.let {
            try { widgetHost.deleteAppWidgetId(it.id) } catch (_: Exception) {}
            pendingWidget = null
        }
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

            "getIconPacks" -> io.execute {
                val packs = try { IconPack.list(this) } catch (_: Throwable) { emptyList() }
                runOnUiThread { result.success(packs) }
            }

            "setIconPack" -> {
                val pkg = call.argument<String>("package")
                io.execute {
                    val ok: Boolean
                    if (pkg == null) {
                        iconPack = null
                        iconPackPkg = null
                        ok = true
                    } else {
                        val loaded = IconPack.load(this, pkg)
                        iconPack = loaded
                        iconPackPkg = if (loaded != null) pkg else null
                        ok = loaded != null
                    }
                    runOnUiThread { result.success(ok) }
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

            "getWidgetProviders" -> io.execute {
                val out = ArrayList<Map<String, Any?>>()
                try {
                    for (info in widgetManager.installedProviders) {
                        if (info.provider.packageName == packageName) continue
                        if (info.widgetCategory and AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN == 0) continue
                        out.add(providerMap(info))
                    }
                } catch (_: Throwable) {
                }
                runOnUiThread { result.success(out) }
            }

            "getWidgetPreview" -> {
                val comp = call.argument<String>("component")
                val size = call.argument<Int>("size") ?: 256
                io.execute {
                    val bytes = try { renderWidgetPreview(comp, size) } catch (_: Throwable) { null }
                    runOnUiThread { result.success(bytes) }
                }
            }

            "addWidget" -> addWidget(call.argument<String>("component"), result)

            "deleteWidget" -> {
                val id = call.argument<Int>("id")
                if (id != null) {
                    try { widgetHost.deleteAppWidgetId(id) } catch (_: Exception) {}
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun providerMap(info: AppWidgetProviderInfo): Map<String, Any?> {
        val pm = packageManager
        val density = resources.displayMetrics.density
        fun dp(px: Int): Int = (px / density).toInt()
        val pkg = info.provider.packageName
        val appLabel = try {
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
        } catch (_: Exception) {
            pkg
        }
        val map = hashMapOf<String, Any?>(
            "component" to info.provider.flattenToString(),
            "package" to pkg,
            "label" to (info.loadLabel(pm) ?: pkg),
            "appLabel" to appLabel,
            "minW" to dp(info.minWidth),
            "minH" to dp(info.minHeight),
            "minResizeW" to dp(info.minResizeWidth),
            "minResizeH" to dp(info.minResizeHeight),
            "resizeMode" to info.resizeMode,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            map["maxResizeW"] = dp(info.maxResizeWidth)
            map["maxResizeH"] = dp(info.maxResizeHeight)
            map["targetCellW"] = info.targetCellWidth
            map["targetCellH"] = info.targetCellHeight
        }
        return map
    }

    private fun renderWidgetPreview(component: String?, maxPx: Int): ByteArray? {
        val cn = ComponentName.unflattenFromString(component ?: return null) ?: return null
        val info = widgetManager.installedProviders.firstOrNull { it.provider == cn } ?: return null
        val dpi = resources.displayMetrics.densityDpi
        val d: Drawable = info.loadPreviewImage(this, dpi) ?: info.loadIcon(this, dpi) ?: return null
        val w = d.intrinsicWidth.takeIf { it > 0 } ?: maxPx
        val h = d.intrinsicHeight.takeIf { it > 0 } ?: maxPx
        val scale = minOf(1f, maxPx.toFloat() / maxOf(w, h))
        val bw = maxOf(1, (w * scale).toInt())
        val bh = maxOf(1, (h * scale).toInt())
        val bmp = Bitmap.createBitmap(bw, bh, Bitmap.Config.ARGB_8888)
        d.setBounds(0, 0, bw, bh)
        d.draw(Canvas(bmp))
        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    @Suppress("DEPRECATION")
    private fun addWidget(component: String?, result: MethodChannel.Result) {
        val cn = component?.let { ComponentName.unflattenFromString(it) }
        val info = cn?.let { c -> widgetManager.installedProviders.firstOrNull { it.provider == c } }
        if (info == null || pendingWidget != null) {
            result.success(null)
            return
        }
        val id = try { widgetHost.allocateAppWidgetId() } catch (_: Exception) {
            result.success(null)
            return
        }
        pendingWidget = PendingWidget(id, info, result)

        if (widgetManager.bindAppWidgetIdIfAllowed(id, info.provider)) {
            continueWidgetAfterBind()
        } else {
            val ask = Intent(AppWidgetManager.ACTION_APPWIDGET_BIND).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER, info.provider)
            }
            try {
                startActivityForResult(ask, REQ_BIND_WIDGET)
            } catch (_: Exception) {
                finishPendingWidget(false)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun continueWidgetAfterBind() {
        val p = pendingWidget ?: return
        if (p.info.configure == null) {
            finishPendingWidget(true)
            return
        }
        try {
            widgetHost.startAppWidgetConfigureActivityForResult(
                this, p.id, 0, REQ_CONFIGURE_WIDGET, null
            )
        } catch (_: Exception) {
            finishPendingWidget(false)
        }
    }

    private fun finishPendingWidget(ok: Boolean) {
        val p = pendingWidget ?: return
        pendingWidget = null
        if (ok) {
            p.result.success(p.id)
        } else {
            try { widgetHost.deleteAppWidgetId(p.id) } catch (_: Exception) {}
            p.result.success(null)
        }
    }

    private fun renderIcon(pkg: String, size: Int, shape: String): ByteArray {
        val drawable = packageManager.getApplicationIcon(pkg)

        val pack = iconPack
        if (pack != null) {
            pack.iconFor(launchComponentKey(pkg), pkg)?.let { return renderThemed(it, size) }
            if (pack.hasBacks) renderOnBack(pack, drawable, pkg, size)?.let { return it }
        }

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

    private fun launchComponentKey(pkg: String): String? =
        packageManager.getLaunchIntentForPackage(pkg)?.component
            ?.let { "${it.packageName}/${it.className}" }

    private fun toBitmap(d: Drawable, size: Int): Bitmap {
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        d.setBounds(0, 0, size, size)
        d.draw(Canvas(bmp))
        return bmp
    }

    private fun encode(bmp: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun renderThemed(d: Drawable, size: Int): ByteArray = encode(toBitmap(d, size))

    private fun renderOnBack(pack: IconPack, app: Drawable, pkg: String, size: Int): ByteArray? {
        val back = pack.back(pkg) ?: return null
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = size.toFloat()
        back.setBounds(0, 0, size, size)
        back.draw(canvas)

        val layer = canvas.saveLayer(0f, 0f, s, s, null)
        val target = s * pack.scale
        val t0 = (s - target) / 2f

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && app is AdaptiveIconDrawable) {
            val box = target / 0.6667f
            val o = ((s - box) / 2f).toInt()
            val bounds = Rect(o, o, o + box.toInt(), o + box.toInt())
            app.background?.let { it.bounds = bounds; it.draw(canvas) }
            app.foreground?.let { it.bounds = bounds; it.draw(canvas) }
            val r = target * 0.22f
            val outside = Path().apply {
                addRoundRect(RectF(t0, t0, t0 + target, t0 + target), r, r, Path.Direction.CW)
                fillType = Path.FillType.INVERSE_WINDING
            }
            val eraser = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
            }
            canvas.drawPath(outside, eraser)
        } else {
            app.setBounds(t0.toInt(), t0.toInt(), (t0 + target).toInt(), (t0 + target).toInt())
            app.draw(canvas)
        }

        pack.mask()?.let { m ->
            val mb = toBitmap(m, size)
            val keepsCenter = Color.alpha(mb.getPixel(size / 2, size / 2)) > 127
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                xfermode = PorterDuffXfermode(
                    if (keepsCenter) PorterDuff.Mode.DST_IN else PorterDuff.Mode.DST_OUT,
                )
            }
            canvas.drawBitmap(mb, 0f, 0f, paint)
        }
        canvas.restoreToCount(layer)

        pack.upon()?.let { u ->
            u.setBounds(0, 0, size, size)
            u.draw(canvas)
        }
        return encode(bmp)
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
