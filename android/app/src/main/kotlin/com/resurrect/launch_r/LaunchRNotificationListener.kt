package com.resurrect.launch_r

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class LaunchRNotificationListener : NotificationListenerService() {

    companion object {
        @Volatile var counts: Map<String, Int> = emptyMap()
        @Volatile var onChange: (() -> Unit)? = null
    }

    override fun onListenerConnected() = refresh()

    override fun onNotificationPosted(sbn: StatusBarNotification?) = refresh()

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = refresh()

    private fun refresh() {
        val next = HashMap<String, Int>()
        try {
            activeNotifications?.forEach { n ->
                if (n.isOngoing) return@forEach
                if ((n.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return@forEach
                next[n.packageName] = (next[n.packageName] ?: 0) + 1
            }
        } catch (_: Exception) {
        }
        counts = next
        onChange?.invoke()
    }
}
