package flyhub.com

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onStart() {
        super.onStart()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "high_importance_channel",
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for FlyHub notifications"
                setSound(
                    android.net.Uri.parse("android.resource://${packageName}/raw/notify"),
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                )
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
