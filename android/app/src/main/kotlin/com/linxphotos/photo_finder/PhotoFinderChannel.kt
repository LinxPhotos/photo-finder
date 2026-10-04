package com.linxphotos.photo_finder

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException

class PhotoFinderChannel(
    private var activity: Activity?,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {

    companion object {
        const val CHANNEL = "com.linxphotos.photo_finder/platform"
        private const val REQ_PICK_SCAN_FOLDER = 9001
        private const val REQ_PICK_OUTPUT_FOLDER = 9002
        private const val REQ_PICK_SAVE_FOLDER = 9003
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingAction: String? = null
    private val shareQueue = mutableListOf<SharePayload>()

    fun attachToActivity(newActivity: Activity?) {
        activity = newActivity
    }

    fun ingestShareIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        when (action) {
            Intent.ACTION_SEND -> {
                val stream = readStreamExtra(intent)
                if (stream != null) {
                    shareQueue.add(buildPayload(stream, intent.type))
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val streams = readStreamListExtra(intent)
                streams?.forEach { uri ->
                    shareQueue.add(buildPayload(uri, intent.type))
                }
            }
        }
    }

    fun drainShareQueue(): List<SharePayload> {
        val copy = shareQueue.toList()
        shareQueue.clear()
        return copy
    }

    private fun readStreamExtra(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun readStreamListExtra(intent: Intent): ArrayList<Uri>? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun buildPayload(uri: Uri, fallbackMime: String?): SharePayload {
        val act = activity ?: return SharePayload(uri.toString(), fallbackMime, null)
        val resolver = act.contentResolver
        var displayName: String? = null
        var mime = fallbackMime
        resolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && nameIndex >= 0) {
                displayName = cursor.getString(nameIndex)
            }
        }
        if (mime.isNullOrBlank()) {
            mime = resolver.getType(uri)
        }
        return SharePayload(uri.toString(), mime, displayName)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("no_activity", "Activity not available", null)
            return
        }
        when (call.method) {
            "pickScanFolder" -> startPickFolder(REQ_PICK_SCAN_FOLDER, result)
            "pickOutputFolder" -> startPickFolder(REQ_PICK_OUTPUT_FOLDER, result)
            "pickSaveFolder" -> startPickFolder(REQ_PICK_SAVE_FOLDER, result)
            "listFolderFiles" -> {
                val uri = call.argument<String>("treeUri")
                if (uri == null) {
                    result.error("bad_args", "treeUri required", null)
                    return
                }
                result.success(listFolderFiles(act, Uri.parse(uri)))
            }
            "readFileBytes" -> {
                val uri = call.argument<String>("uri")
                val maxBytes = call.argument<Int>("maxBytes") ?: 512 * 1024
                if (uri == null) {
                    result.error("bad_args", "uri required", null)
                    return
                }
                try {
                    result.success(readBytes(act.contentResolver, Uri.parse(uri), maxBytes))
                } catch (e: IOException) {
                    result.error("io", e.message, null)
                }
            }
            "applyRenames" -> {
                val items = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
                val outputTree = call.argument<String>("outputTreeUri")
                val outputUri = outputTree?.let { Uri.parse(it) }
                result.success(applyRenames(act, items, outputUri))
            }
            "saveSharedFile" -> {
                val sourceUri = call.argument<String>("sourceUri")
                val treeUri = call.argument<String>("treeUri")
                val fileName = call.argument<String>("fileName")
                if (sourceUri == null || treeUri == null || fileName == null) {
                    result.error("bad_args", "sourceUri, treeUri, fileName required", null)
                    return
                }
                try {
                    result.success(
                        saveSharedFile(
                            act,
                            Uri.parse(sourceUri),
                            Uri.parse(treeUri),
                            fileName,
                        ),
                    )
                } catch (e: IOException) {
                    result.error("io", e.message, null)
                }
            }
            "takeSharePayloads" -> {
                result.success(
                    drainShareQueue().map { mapOf("uri" to it.uri, "mimeType" to it.mimeType, "displayName" to it.displayName) },
                )
            }
            "displayNameForUri" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("bad_args", "uri required", null)
                    return
                }
                result.success(queryDisplayName(act.contentResolver, Uri.parse(uri)))
            }
            else -> result.notImplemented()
        }
    }

    private fun startPickFolder(requestCode: Int, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another picker is open", null)
            return
        }
        val act = activity ?: run {
            result.error("no_activity", "Activity not available", null)
            return
        }
        pendingResult = result
        pendingAction = when (requestCode) {
            REQ_PICK_SCAN_FOLDER -> "scan"
            REQ_PICK_OUTPUT_FOLDER -> "output"
            else -> "save"
        }
        val intent =
            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
                )
            }
        act.startActivityForResult(intent, requestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQ_PICK_SCAN_FOLDER &&
            requestCode != REQ_PICK_OUTPUT_FOLDER &&
            requestCode != REQ_PICK_SAVE_FOLDER
        ) {
            return false
        }
        val result = pendingResult
        pendingResult = null
        pendingAction = null
        if (result == null) return true
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return true
        }
        val treeUri = data.data!!
        val act = activity
        if (act != null) {
            val takeFlags =
                data.flags and
                    (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            try {
                act.contentResolver.takePersistableUriPermission(treeUri, takeFlags)
            } catch (_: SecurityException) {
                // Some providers do not allow persist; still return URI.
            }
        }
        val doc = act?.let { DocumentFile.fromTreeUri(it, treeUri) }
        result.success(
            mapOf(
                "treeUri" to treeUri.toString(),
                "displayName" to (doc?.name ?: "Folder"),
            ),
        )
        return true
    }

    private fun listFolderFiles(activity: Activity, treeUri: Uri): List<Map<String, Any?>> {
        val root = DocumentFile.fromTreeUri(activity, treeUri) ?: return emptyList()
        val out = mutableListOf<Map<String, Any?>>()
        fun walk(dir: DocumentFile) {
            for (child in dir.listFiles()) {
                if (child.isDirectory) {
                    walk(child)
                } else if (child.isFile) {
                    out.add(
                        mapOf(
                            "uri" to child.uri.toString(),
                            "displayName" to (child.name ?: ""),
                            "size" to child.length(),
                        ),
                    )
                }
            }
        }
        walk(root)
        return out
    }

    private fun readBytes(resolver: ContentResolver, uri: Uri, maxBytes: Int): ByteArray {
        resolver.openInputStream(uri)?.use { input ->
            val buffer = ByteArray(maxBytes)
            var total = 0
            while (total < maxBytes) {
                val read = input.read(buffer, total, maxBytes - total)
                if (read <= 0) break
                total += read
            }
            return if (total == maxBytes) buffer else buffer.copyOf(total)
        } ?: throw IOException("Cannot open $uri")
    }

    private fun applyRenames(
        activity: Activity,
        items: List<Map<String, Any?>>,
        outputTreeUri: Uri?,
    ): List<Map<String, Any?>> {
        val resolver = activity.contentResolver
        val results = mutableListOf<Map<String, Any?>>()
        val outputRoot =
            outputTreeUri?.let { DocumentFile.fromTreeUri(activity, it) }
        for (item in items) {
            val uri = Uri.parse(item["uri"] as String)
            val newName = item["newName"] as String
            val selected = item["selected"] as? Boolean ?: true
            if (!selected) {
                results.add(mapOf("uri" to uri.toString(), "success" to true, "skipped" to true))
                continue
            }
            try {
                if (outputRoot != null) {
                    val mime = resolver.getType(uri) ?: "application/octet-stream"
                    val dest =
                        outputRoot.findFile(newName)
                            ?: outputRoot.createFile(mime, newName)
                    if (dest == null) {
                        results.add(
                            mapOf(
                                "uri" to uri.toString(),
                                "success" to false,
                                "error" to "Could not create $newName",
                            ),
                        )
                        continue
                    }
                    resolver.openInputStream(uri)?.use { input ->
                        resolver.openOutputStream(dest.uri)?.use { output ->
                            input.copyTo(output)
                        }
                    } ?: throw IOException("Cannot read source")
                    DocumentFile.fromSingleUri(activity, uri)?.delete()
                    results.add(
                        mapOf(
                            "uri" to uri.toString(),
                            "success" to true,
                            "newUri" to dest.uri.toString(),
                        ),
                    )
                } else {
                    val renamed = DocumentsContract.renameDocument(resolver, uri, newName)
                    results.add(
                        mapOf(
                            "uri" to uri.toString(),
                            "success" to true,
                            "newUri" to (renamed?.toString() ?: uri.toString()),
                        ),
                    )
                }
            } catch (e: Exception) {
                results.add(
                    mapOf(
                        "uri" to uri.toString(),
                        "success" to false,
                        "error" to (e.message ?: "rename failed"),
                    ),
                )
            }
        }
        return results
    }

    private fun saveSharedFile(
        activity: Activity,
        sourceUri: Uri,
        treeUri: Uri,
        fileName: String,
    ): Map<String, Any?> {
        val resolver = activity.contentResolver
        val root = DocumentFile.fromTreeUri(activity, treeUri)
            ?: throw IOException("Invalid save folder")
        val mime = resolver.getType(sourceUri) ?: "application/octet-stream"
        val existing = root.findFile(fileName)
        if (existing != null) {
            existing.delete()
        }
        val dest =
            root.createFile(mime, fileName)
                ?: throw IOException("Could not create $fileName")
        resolver.openInputStream(sourceUri)?.use { input ->
            resolver.openOutputStream(dest.uri)?.use { output ->
                input.copyTo(output)
            }
        } ?: throw IOException("Cannot read shared content")
        return mapOf("uri" to dest.uri.toString(), "displayName" to fileName)
    }

    private fun queryDisplayName(resolver: ContentResolver, uri: Uri): String? {
        resolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && nameIndex >= 0) {
                return cursor.getString(nameIndex)
            }
        }
        return null
    }
}
