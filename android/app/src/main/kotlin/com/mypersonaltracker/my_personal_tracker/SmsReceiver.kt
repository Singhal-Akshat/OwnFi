package com.mypersonaltracker.my_personal_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class SmsReceiver : BroadcastReceiver() {
    private val financialKeywords = Regex("\\b(debited|spent|charged|withdrawn|sent|paid|payment|credited|received|deposited|added)\\b|(?:txn\\s+of)", RegexOption.IGNORE_CASE)
    private val otpOrPromotionalKeywords = Regex("(otp|one-time password|one time password|verification code|verify|security code|auth code|passcode|pre-approved|pre approved|apply now|win|offer|eligible|rate of interest|subscrib|bonus|upgrade|recharge)", RegexOption.IGNORE_CASE)
    private val amountReg = Regex("(?:rs\\.?|inr|₹)\\s*([0-9,]+(?:\\.[0-9]{2})?)", RegexOption.IGNORE_CASE)

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (message in messages) {
                val body = message.messageBody ?: continue
                if (isTransactional(body)) {
                    val amount = extractAmount(body)
                    showNotification(context, amount, body)
                }
            }
        }
    }

    private fun isTransactional(body: String): Boolean {
        if (!financialKeywords.containsMatchIn(body)) return false
        if (otpOrPromotionalKeywords.containsMatchIn(body)) return false
        return amountReg.containsMatchIn(body)
    }

    private fun extractAmount(body: String): String {
        val match = amountReg.find(body)
        return match?.groupValues?.get(1) ?: ""
    }

    private fun showNotification(context: Context, amount: String, body: String) {
        val channelId = "transaction_alerts"
        val notificationId = System.currentTimeMillis().toInt()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Transaction Alerts"
            val descriptionText = "Notifications for detected transaction SMS"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val displayAmount = if (amount.isNotEmpty()) "₹$amount" else "a transaction"
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("New Transaction Detected")
            .setContentText("Tap to review and log: $displayAmount")
            .setStyle(NotificationCompat.BigTextStyle().bigText("Parsed amount: $displayAmount\n$body"))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        with(NotificationManagerCompat.from(context)) {
            try {
                notify(notificationId, builder.build())
            } catch (e: SecurityException) {
                // Ignore missing notification permission runtime error
            }
        }
    }
}
