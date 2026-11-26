package com.example.market_space

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.dealone.market_space/document_picker"
        private const val REQ_CAMERA = 4101
        private const val REQ_GALLERY = 4102
        private const val REQ_FILE = 4103
        private const val MAX_BYTES = 15 * 1024 * 1024
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (pendingResult != null) {
                    result.error("PICKER_BUSY", "Document picker is already active", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "pickFromCamera" -> {
                        pendingResult = result
                        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivityForResult(intent, REQ_CAMERA)
                        } else {
                            pendingResult = null
                            result.error("CAMERA_UNAVAILABLE", "No camera app available", null)
                        }
                    }
                    "pickFromGallery" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(intent, REQ_GALLERY)
                    }
                    "pickFile" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf(
                                    "image/jpeg",
                                    "image/png",
                                    "image/webp",
                                    "application/pdf",
                                ),
                            )
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(intent, REQ_FILE)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingResult
        if (requestCode != REQ_CAMERA && requestCode != REQ_GALLERY && requestCode != REQ_FILE) {
            return
        }
        pendingResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        try {
            if (requestCode == REQ_CAMERA) {
                @Suppress("DEPRECATION")
                val bitmap = data.extras?.get("data") as? Bitmap
                if (bitmap == null) {
                    result.success(null)
                    return
                }
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 92, stream)
                val bytes = stream.toByteArray()
                result.success(
                    mapOf(
                        "fileName" to "camera_${System.currentTimeMillis()}.jpg",
                        "mimeType" to "image/jpeg",
                        "bytes" to bytes,
                    ),
                )
                return
            }

            val uri: Uri? = data.data
            if (uri == null) {
                result.success(null)
                return
            }

            val mimeType = normalizeMimeType(contentResolver.getType(uri))
            val rawName = resolveFileName(uri)
            val fileName = ensureMatchingExtension(rawName, mimeType)

            val bytes = contentResolver.openInputStream(uri)?.use { input ->
                val buffer = ByteArrayOutputStream()
                val chunk = ByteArray(8192)
                var total = 0
                while (true) {
                    val read = input.read(chunk)
                    if (read <= 0) break
                    total += read
                    if (total > MAX_BYTES) {
                        throw IllegalStateException("File size exceeds 15 MB limit")
                    }
                    buffer.write(chunk, 0, read)
                }
                buffer.toByteArray()
            }

            if (bytes == null || bytes.isEmpty()) {
                result.success(null)
                return
            }

            result.success(
                mapOf(
                    "fileName" to fileName,
                    "mimeType" to mimeType,
                    "bytes" to bytes,
                ),
            )
        } catch (e: Exception) {
            result.error("PICKER_READ_FAILED", e.message ?: "Failed to read file", null)
        }
    }

    private fun resolveFileName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) {
                        val value = cursor.getString(idx)
                        if (!value.isNullOrBlank()) return value
                    }
                }
            }
        return uri.lastPathSegment?.substringAfterLast('/') ?: "document.jpg"
    }

    private fun normalizeMimeType(raw: String?): String {
        val lower = raw?.trim()?.lowercase() ?: "image/jpeg"
        return when (lower) {
            "image/jpg" -> "image/jpeg"
            "image/jpeg", "image/png", "image/webp", "application/pdf" -> lower
            else -> "image/jpeg"
        }
    }

    private fun ensureMatchingExtension(name: String, mimeType: String): String {
        val expectedExt = when (mimeType) {
            "application/pdf" -> "pdf"
            "image/png" -> "png"
            "image/webp" -> "webp"
            else -> "jpg"
        }
        val dot = name.lastIndexOf('.')
        if (dot <= 0 || dot == name.length - 1) {
            return "$name.$expectedExt"
        }
        val ext = name.substring(dot + 1).lowercase()
        val matches = when (mimeType) {
            "application/pdf" -> ext == "pdf"
            "image/png" -> ext == "png"
            "image/webp" -> ext == "webp"
            "image/jpeg" -> ext == "jpg" || ext == "jpeg"
            else -> true
        }
        return if (matches) name else "${name.substring(0, dot)}.$expectedExt"
    }
}
