package com.resurrect.launch_r

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Resources
import android.graphics.drawable.Drawable
import android.util.Xml
import org.xmlpull.v1.XmlPullParser

class IconPack private constructor(
    val pkg: String,
    private val res: Resources,
) {
    private val byComponent = HashMap<String, String>()
    private val byPackage = HashMap<String, String>()
    private val backs = ArrayList<String>()
    private var maskName: String? = null
    private var uponName: String? = null

    var scale = 0.7f
        private set

    val hasBacks: Boolean get() = backs.isNotEmpty()

    fun iconFor(component: String?, appPkg: String): Drawable? {
        val name = (component?.let { byComponent[it] }) ?: byPackage[appPkg] ?: return null
        return drawable(name)
    }

    fun back(appPkg: String): Drawable? {
        if (backs.isEmpty()) return null
        val i = (appPkg.hashCode() and Int.MAX_VALUE) % backs.size
        return drawable(backs[i])
    }

    fun mask(): Drawable? = maskName?.let { drawable(it) }

    fun upon(): Drawable? = uponName?.let { drawable(it) }

    private fun drawable(name: String): Drawable? {
        var id = res.getIdentifier(name, "drawable", pkg)
        if (id == 0) id = res.getIdentifier(name, "mipmap", pkg)
        if (id == 0) return null
        return try {
            res.getDrawable(id, null)
        } catch (_: Throwable) {
            null
        }
    }

    private fun parseAll() {
        val id = res.getIdentifier("appfilter", "xml", pkg)
        if (id != 0) {
            try {
                val xml = res.getXml(id)
                try { parse(xml) } finally { xml.close() }
            } catch (_: Throwable) {}
        }
        if (byComponent.isEmpty() && byPackage.isEmpty()) {
            try {
                res.assets.open("appfilter.xml").use { stream ->
                    val p = Xml.newPullParser()
                    p.setInput(stream, null)
                    parse(p)
                }
            } catch (_: Throwable) {}
        }
    }

    private fun parse(p: XmlPullParser) {
        try {
            var ev = p.eventType
            while (ev != XmlPullParser.END_DOCUMENT) {
                if (ev == XmlPullParser.START_TAG) {
                    when (p.name) {
                        "item" -> {
                            val comp = p.getAttributeValue(null, "component")
                            val dr = p.getAttributeValue(null, "drawable")
                            if (comp != null && dr != null) addItem(comp, dr)
                        }
                        "iconback" -> backs.addAll(imgs(p))
                        "iconmask" -> imgs(p).firstOrNull()?.let { maskName = it }
                        "iconupon" -> imgs(p).firstOrNull()?.let { uponName = it }
                        "scale" -> {
                            val f = p.getAttributeValue(null, "factor")?.toFloatOrNull()
                            if (f != null && f > 0f) scale = f.coerceAtMost(1f)
                        }
                    }
                }
                ev = p.next()
            }
        } catch (_: Throwable) {
        }
    }

    private fun addItem(component: String, drawable: String) {
        val name = clean(drawable) ?: return
        val m = COMPONENT.find(component) ?: return
        val p = m.groupValues[1]
        var cls = m.groupValues[2]
        if (cls.startsWith(".")) cls = p + cls
        byComponent.putIfAbsent("$p/$cls", name)
        byPackage.putIfAbsent(p, name)
    }

    private fun imgs(p: XmlPullParser): List<String> {
        val out = ArrayList<String>()
        for (i in 0 until p.attributeCount) {
            if (p.getAttributeName(i).startsWith("img")) {
                clean(p.getAttributeValue(i))?.let { out.add(it) }
            }
        }
        return out
    }

    private fun clean(value: String?): String? {
        if (value.isNullOrBlank()) return null
        var s = value.trim().substringAfterLast('/')
        for (ext in EXTENSIONS) {
            if (s.endsWith(ext, ignoreCase = true)) s = s.dropLast(ext.length)
        }
        return s.ifEmpty { null }
    }

    companion object {
        private val COMPONENT = Regex("""ComponentInfo\{([^/}]+)/([^}]*)\}""")
        private val EXTENSIONS = arrayOf(".png", ".webp", ".jpg", ".jpeg", ".xml")

        private val ACTIONS = arrayOf(
            "org.adw.launcher.THEMES",
            "com.novalauncher.THEME",
            "com.anddoes.launcher.THEME",
            "org.adw.launcher.icons.ACTION_PICK_ICON",
        )

        @Suppress("DEPRECATION")
        fun list(ctx: Context): List<Map<String, String>> {
            val pm = ctx.packageManager
            val seen = HashSet<String>()
            val out = ArrayList<Map<String, String>>()
            for (action in ACTIONS) {
                for (ri in pm.queryIntentActivities(Intent(action), 0)) {
                    val p = ri.activityInfo.packageName
                    if (p == ctx.packageName || !seen.add(p)) continue
                    out.add(mapOf("package" to p, "label" to ri.loadLabel(pm).toString()))
                }
            }
            out.sortBy { it["label"]?.lowercase() }
            return out
        }

        fun load(ctx: Context, pkg: String): IconPack? {
            return try {
                val res = ctx.packageManager.getResourcesForApplication(pkg)
                val pack = IconPack(pkg, res)
                pack.parseAll()
                val usable = pack.byComponent.isNotEmpty() ||
                    pack.byPackage.isNotEmpty() ||
                    pack.backs.isNotEmpty()
                if (usable) pack else null
            } catch (_: Throwable) {
                null
            }
        }
    }
}
