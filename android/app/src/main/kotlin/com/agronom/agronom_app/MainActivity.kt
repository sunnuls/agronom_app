package com.agronom.agronom_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter

class MainActivity : FlutterActivity() {
    private val channelName = "com.agronom.agronom_app/import"
    private var pendingImportJson: String? = null
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveContent: String? = null
    private val requestPickFile = 0x7010
    private val requestSaveFile = 0x7011

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "takePendingImport" -> {
                    val json = pendingImportJson
                    pendingImportJson = null
                    result.success(json)
                }
                "pickFile" -> {
                    if (pendingPickResult != null) {
                        result.error("BUSY", "Уже открыт выбор файла", null)
                        return@setMethodCallHandler
                    }
                    pendingPickResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    try {
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, requestPickFile)
                    } catch (e: Exception) {
                        pendingPickResult?.error("PICK_FAILED", e.message, null)
                        pendingPickResult = null
                    }
                }
                "saveFile" -> {
                    if (pendingSaveResult != null) {
                        result.error("BUSY", "Уже открыт диалог сохранения", null)
                        return@setMethodCallHandler
                    }
                    val content = call.argument<String>("content")
                    val fileName = call.argument<String>("fileName") ?: "export.agronom"
                    if (content == null) {
                        result.error("NO_CONTENT", "Нет содержимого для сохранения", null)
                        return@setMethodCallHandler
                    }
                    pendingSaveResult = result
                    pendingSaveContent = content
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/json"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    try {
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, requestSaveFile)
                    } catch (e: Exception) {
                        pendingSaveResult?.error("SAVE_FAILED", e.message, null)
                        pendingSaveResult = null
                        pendingSaveContent = null
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            requestPickFile -> {
                val pr = pendingPickResult
                pendingPickResult = null
                if (pr == null) return
                if (resultCode != RESULT_OK || data?.data == null) { pr.success(null); return }
                pr.success(readUriToString(data.data!!))
            }
            requestSaveFile -> {
                val pr = pendingSaveResult
                val content = pendingSaveContent
                pendingSaveResult = null
                pendingSaveContent = null
                if (pr == null) return
                if (resultCode != RESULT_OK || data?.data == null) { pr.success(false); return }
                val ok = writeUriFromString(data.data!!, content ?: "")
                pr.success(ok)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        when (intent.action) {
            Intent.ACTION_VIEW -> intent.data?.let { readUri(it) }
            Intent.ACTION_SEND -> {
                val stream = getSendStreamUri(intent)
                if (stream != null) {
                    readUri(stream)
                } else if (intent.type?.startsWith("text/") == true) {
                    val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                    if (!text.isNullOrBlank()) pendingImportJson = text.trim()
                }
            }
        }
    }

    private fun readUri(uri: Uri) {
        val text = readUriToString(uri)
        if (!text.isNullOrBlank()) pendingImportJson = text.trim()
    }

    private fun readUriToString(uri: Uri): String? {
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                BufferedReader(InputStreamReader(input, Charsets.UTF_8)).readText()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun writeUriFromString(uri: Uri, content: String): Boolean {
        return try {
            contentResolver.openOutputStream(uri)?.use { output ->
                OutputStreamWriter(output, Charsets.UTF_8).use { it.write(content) }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun getSendStreamUri(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }
}
