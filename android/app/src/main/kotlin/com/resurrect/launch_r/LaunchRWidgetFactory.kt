package com.resurrect.launch_r

import android.app.Activity
import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class LaunchRWidgetFactory(
    private val activity: Activity,
    private val host: AppWidgetHost,
    private val manager: AppWidgetManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val id = ((args as? Map<*, *>)?.get("id") as? Number)?.toInt() ?: -1
        val info = if (id >= 0) manager.getAppWidgetInfo(id) else null

        val view: View = if (info == null) {
            TextView(activity).apply {
                text = "Widget unavailable"
                gravity = Gravity.CENTER
                setTextColor(0xCCFFFFFF.toInt())
                setBackgroundColor(0x33000000)
            }
        } else {
            host.createView(activity, id, info).also { hv ->
                hv.addOnLayoutChangeListener { v, l, t, r, b, oldL, oldT, oldR, oldB ->
                    val w = r - l
                    val h = b - t
                    if (w == oldR - oldL && h == oldB - oldT) return@addOnLayoutChangeListener
                    val d = v.resources.displayMetrics.density
                    val wd = (w / d).toInt()
                    val hd = (h / d).toInt()
                    (v as? AppWidgetHostView)?.updateAppWidgetSize(Bundle(), wd, hd, wd, hd)
                }
            }
        }

        return object : PlatformView {
            override fun getView(): View = view
            override fun dispose() {}
        }
    }
}
