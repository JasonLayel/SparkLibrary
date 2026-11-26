# Spark Studio

A neon art-reference and study tool. Point it at your images and it shows one at
random, with study tools and dataset prep — everything runs locally in the browser.

**Live:** https://sparkjl.netlify.app/

## What it does

- **Image sources** — pick one:
  - **Google Drive** (live, read-only) — the same library on every device, synced.
  - **A folder on your computer** (Chrome/Edge, File System Access API) — e.g. your
    synced Google Drive desktop folder. Subfolders become toggleable "boards".
  - **Your phone's photos** — cached on-device (IndexedDB). Nothing is uploaded.
- **Random reference** — draw one image at a time; prefers images you haven't drawn yet.
- **Study tools** — flip, grayscale, notan/posterize, squint-blur, rule-of-thirds &
  fine grid overlays, palette extraction, a countdown timer, and gesture-drill sessions.
- **Library** — favorites, a **LoRA dataset** builder with tag/trigger-word caption
  export, "drawn" tracking, and a never-show list.
- **Organizing** — every folder that holds images is its own board (nested folders
  included). **Cull duds** pages through the library so you can hide the duds a screenful
  at a time. Images you skip within 3 seconds, 3+ times, come up last and gather under
  **Often skipped**. **Draw by tag** limits drawing to one tag (e.g. `face-front`). Note
  that tags also go into LoRA dataset captions. On Google Drive, byte-identical
  duplicate files show only once.
- **Cross-device sync** — favorites, tags, dataset, and settings sync through a hidden
  app file in your Google Drive.

Nothing is uploaded to any server: Google Drive access is client-side and read-only,
and the access token lives only in memory.

## Updating from Pinterest and ArtStation (Windows)

Spark only reads your Drive folder, so new saves get there with
[gallery-dl](https://codeberg.org/mikf/gallery-dl), run by `tools/update-spark.bat`:

1. Install [Google Drive for desktop](https://www.google.com/drive/download/) so the
   Spark folder is a normal folder on your PC, and
   [Python](https://www.python.org/downloads/) (tick "Add python.exe to PATH").
2. In Spark, click **⤓ Get updater** at the top right (or go to
   https://sparkjl.netlify.app/tools/update-spark.bat). If the browser or Windows warns
   about the file, choose **Keep** / **More info → Run anyway**.
3. Make sure you're logged in to Pinterest in Firefox. The script borrows those
   cookies so it can see secret boards.
4. Double-click `update-spark.bat`. The first time, it opens a folder picker: choose
   your Spark folder (the Drive folder Spark is connected to). It remembers that, and
   on later runs you can press **C** to pick a different one. It then downloads each
   Pinterest board to `pinterest\JasonLayel\<board>\` and your ArtStation likes to
   `artstation\jasonlayel\Likes\`.
5. When Drive finishes syncing, press **Refresh** in Spark.

Run it again whenever you like. Anything already downloaded is skipped, both by
gallery-dl's record (`%LOCALAPPDATA%\SparkStudio\gdl-archive.sqlite3`) and because the
file already exists. If a run ever does bring in a byte-identical copy, Spark shows it
only once.

## Deploying

This is a single static file — no build step. Netlify serves the repo root
(`netlify.toml` sets `publish = "."`). Any push to `main` auto-deploys to the live URL
once the site is linked to this repo in Netlify (Site configuration → Build & deploy →
Link repository).

## Google Drive setup (one time)

To use the Drive source you need a Google OAuth **Client ID** whose authorized
JavaScript origin includes the site's URL (e.g. `https://sparkjl.netlify.app`). Enter
the Client ID and a Drive folder link in the app's Connect panel.
