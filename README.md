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

`tools/update-spark.bat` pulls new saves into the Spark folder with
[gallery-dl](https://codeberg.org/mikf/gallery-dl). It's a one-line Windows launcher
followed by a Python script, so double-clicking it is all you do.

- Each Pinterest board downloads straight into its Spark folder: Digital Painting →
  `Environments`, Sketching → `Character-Sketch`, Character Design & Fashion →
  `Character-Render`. Reference and Sculpture pins go to `_To sort`, to be filed into
  `Photo-Figure` or `Photo-Portrait` by hand. Other boards are left alone. The mapping
  is the `BOARDS` list at the top of the script.
- ArtStation likes go to `ArtStation Likes`.
- Images you already have are skipped wherever they're filed, by the Pinterest pin ID
  (`pinterest_<id>…`) or image hash in their file name. Everything it has seen is
  remembered in `%LOCALAPPDATA%\SparkStudio`, so a file you delete doesn't come back.

To run it:

1. Install [Python](https://www.python.org/downloads/) (tick "Add python.exe to PATH").
2. In Spark, click **⤓ Get updater** (or open
   https://sparkjl.netlify.app/tools/update-spark.bat). If the browser or Windows warns
   about the file, choose **Keep** / **More info → Run anyway**.
3. Be logged in to Pinterest in Firefox (the script uses those cookies).
4. Double-click `update-spark.bat`. The first time, pick your Spark folder in the window
   that opens; later runs remember it (press **C** at the start to change it).
5. When the folder has synced to Google Drive, press **Refresh** in Spark.

## Deploying

This is a single static file — no build step. Netlify serves the repo root
(`netlify.toml` sets `publish = "."`). Any push to `main` auto-deploys to the live URL
once the site is linked to this repo in Netlify (Site configuration → Build & deploy →
Link repository).

## Google Drive setup (one time)

To use the Drive source you need a Google OAuth **Client ID** whose authorized
JavaScript origin includes the site's URL (e.g. `https://sparkjl.netlify.app`). Enter
the Client ID and a Drive folder link in the app's Connect panel.
