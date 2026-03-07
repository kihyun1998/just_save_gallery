package com.example.just_save_gallery

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream
import java.io.IOException

/**
 * Handles saving media files to the device gallery via [MediaStore].
 *
 * Supports both Android 10+ (scoped storage with [MediaStore.IS_PENDING])
 * and older versions.
 */
internal class GallerySaver(private val context: Context) {

    /**
     * Saves raw [bytes] to the gallery.
     *
     * @param bytes    The raw media data.
     * @param name     The desired file name including extension.
     * @param albumName An optional album/folder name.
     * @param isVideo  Whether the media is a video (otherwise treated as image).
     * @return The content URI of the saved media.
     */
    fun saveBytes(bytes: ByteArray, name: String, albumName: String?, isVideo: Boolean): String {
        val uri = insertMediaEntry(name, albumName, isVideo)
            ?: throw IOException("Failed to create MediaStore entry")

        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            outputStream.write(bytes)
        } ?: throw IOException("Failed to open output stream for $uri")

        finalizePendingEntry(uri)
        return uri.toString()
    }

    /**
     * Saves a file at [filePath] to the gallery.
     *
     * @param filePath  The absolute path to the source file.
     * @param name      The desired file name including extension.
     * @param albumName An optional album/folder name.
     * @param isVideo   Whether the media is a video (otherwise treated as image).
     * @return The content URI of the saved media.
     */
    fun saveFile(filePath: String, name: String, albumName: String?, isVideo: Boolean): String {
        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            throw FileNotFoundException("Source file not found: $filePath")
        }

        val uri = insertMediaEntry(name, albumName, isVideo)
            ?: throw IOException("Failed to create MediaStore entry")

        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            FileInputStream(sourceFile).use { inputStream ->
                inputStream.copyTo(outputStream)
            }
        } ?: throw IOException("Failed to open output stream for $uri")

        finalizePendingEntry(uri)
        return uri.toString()
    }

    /**
     * Creates a new [MediaStore] entry with the appropriate collection,
     * MIME type, and relative path.
     *
     * On API 29+, the entry is created with [MediaStore.IS_PENDING] = 1
     * so the file is not visible until [finalizePendingEntry] is called.
     */
    private fun insertMediaEntry(name: String, albumName: String?, isVideo: Boolean): Uri? {
        val collection = if (isVideo) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            }
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
        }

        val mimeType = inferMimeType(name, isVideo)
        val resolvedName = resolveUniqueName(collection, name)

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, resolvedName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val basePath = if (isVideo) {
                    Environment.DIRECTORY_MOVIES
                } else {
                    Environment.DIRECTORY_PICTURES
                }
                val relativePath = if (albumName != null) {
                    "$basePath/$albumName"
                } else {
                    basePath
                }
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        return context.contentResolver.insert(collection, values)
    }

    /**
     * Marks a pending [MediaStore] entry as complete so it becomes visible
     * in the gallery. Only applies to API 29+.
     */
    private fun finalizePendingEntry(uri: Uri) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            context.contentResolver.update(uri, values, null, null)
        }
    }

    /**
     * Resolves a unique file name by appending a numeric suffix if a file
     * with the same name already exists in the given [collection].
     *
     * For example, if `photo.jpg` exists, this returns `photo(1).jpg`.
     */
    private fun resolveUniqueName(collection: Uri, name: String): String {
        val baseName = name.substringBeforeLast('.')
        val extension = if (name.contains('.')) ".${name.substringAfterLast('.')}" else ""

        var candidate = name
        var counter = 1

        while (nameExists(collection, candidate)) {
            candidate = "$baseName($counter)$extension"
            counter++
        }

        return candidate
    }

    /**
     * Checks whether a file with the given [displayName] already exists
     * in the specified [collection].
     */
    private fun nameExists(collection: Uri, displayName: String): Boolean {
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf(displayName)

        context.contentResolver.query(collection, projection, selection, selectionArgs, null)?.use {
            return it.count > 0
        }
        return false
    }

    /**
     * Infers a MIME type from the file [name] extension.
     * Falls back to `image/jpeg` or `video/mp4` if the extension is unknown.
     */
    private fun inferMimeType(name: String, isVideo: Boolean): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        return when (ext) {
            // Images
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "bmp" -> "image/bmp"
            "heic", "heif" -> "image/heif"
            // Videos
            "mp4" -> "video/mp4"
            "mov" -> "video/quicktime"
            "avi" -> "video/x-msvideo"
            "mkv" -> "video/x-matroska"
            "webm" -> "video/webm"
            "3gp" -> "video/3gpp"
            else -> if (isVideo) "video/mp4" else "image/jpeg"
        }
    }

    class FileNotFoundException(message: String) : IOException(message)
}
