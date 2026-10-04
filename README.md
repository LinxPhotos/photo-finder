# Photo Finder

**Photo Finder** is a Flutter Android app—a **download fixer** and **file renamer** for photos and videos that **download** from Google Photos with a bad or missing **file** name or extension. It is **not** a photo editor.

## What it does

1. **Scanner / recovery** — Pick a folder (Storage Access Framework) of already-downloaded files. Photo Finder detects images and videos from file content (magic bytes and EXIF when present), skips files that already look fine, and shows a **review** list before **rename** or copy. Fix missing or wrong extensions and junk filenames. Use capture date from EXIF when available; otherwise keep the basename and fix the extension only.
2. **Share target** — Register for shares from Google Photos (`image/*`, `video/*`). Read the display name and MIME type, add an extension when needed, and save into a folder you choose.

Photo Finder helps you **find** a photo or video **file** that **downloaded** without a proper name or extension. It does **not** search your whole library by picture content.

## What it cannot do

- Recover the original Google server filename for a file that was already saved wrong.
- Edit photos (no crop, filter, or adjust).
- Search all photos on the device by visual content.

## Build

Requires Flutter stable and the Android SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## CI

GitHub Actions builds a debug APK on push and pull request (see [`.github/workflows/android.yml`](.github/workflows/android.yml)).

## Play Store copy

Draft listing text for manual paste in Play Console: [`store/play-listing.md`](store/play-listing.md).

## Search phrases (store / discovery)

photo finder, file, download, rename, renamer, download fixer
