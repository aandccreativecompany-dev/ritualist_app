# Finding build errors

Every push of a `v*` tag, and every manual run, triggers a build. When it fails,
this is how to get me the error text.

## Reading a failed run

1. Open the repository on GitHub and click the **Actions** tab.
2. Click the most recent run in the list — a red ✗ means it failed.
3. Click the job named **build** in the left sidebar.
4. The steps expand. The failed one has a red ✗; click it to open the log.
5. Scroll to the bottom. The real error is usually 10 to 30 lines above the last
   line, and starts with `Error:`, `error:`, or `FAILURE:`.

## Sending it to me

Easiest: click the **⚙ gear icon** at the top right of the log view and choose
**Download log archive**. Paste the contents of the failed step's file into chat.

Or select the last hundred or so lines of the log, copy, and paste them in. Do
not summarise or retype them — the exact text, including file names and line
numbers, is what I need.

If the log is enormous, the lines starting with `lib/` are the ones that matter:
they point at the exact Dart file and line.

## Running a build without tagging

Actions tab → **Build APK** in the left sidebar → **Run workflow** → pick `main`
→ **Run workflow**. This builds and attaches the APK as a downloadable artifact
at the bottom of the run page, without creating a release. Use this while we are
still fixing errors.

## Where the APK ends up

- **Manual run:** the run page, under *Artifacts* → `ritualist-apk`. Only people
  signed in to GitHub can download it.
- **Tagged run:** a draft release, with the APK attached. Open Releases, edit the
  draft, write the notes and publish. That is the version the public link points
  at.

## Common first failures, and what they mean

| In the log | What it is |
|---|---|
| `error: ... isn't defined` in a `lib/` file | A Dart mistake of mine. Send the line. |
| `Gradle task assembleRelease failed` | Android config. Send 50 lines above it. |
| `Because ritualist depends on ...` | A package version clash. Send the block. |
| `No such file or directory: android/app/...` | The generate step failed earlier up the log. |
