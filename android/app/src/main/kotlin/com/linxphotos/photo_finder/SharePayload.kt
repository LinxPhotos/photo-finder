package com.linxphotos.photo_finder

data class SharePayload(
    val uri: String,
    val mimeType: String?,
    val displayName: String?,
)
