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
- **Cross-device sync** — favorites, tags, dataset, and settings sync through a hidden
  app file in your Google Drive.

Nothing is uploaded to any server: Google Drive access is client-side and read-only,
and the access token lives only in memory.

## Deploying

This is a single static file — no build step. Netlify serves the repo root
(`netlify.toml` sets `publish = "."`). Any push to `main` auto-deploys to the live URL
once the site is linked to this repo in Netlify (Site configuration → Build & deploy →
Link repository).

## Google Drive setup (one time)

To use the Drive source you need a Google OAuth **Client ID** whose authorized
JavaScript origin includes the site's URL (e.g. `https://sparkjl.netlify.app`). Enter
the Client ID and a Drive folder link in the app's Connect panel.
