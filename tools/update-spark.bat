@echo off & (py -3 -x "%~f0" || (echo. & echo Python isn't set up on this PC. Install it from python.org/downloads - tick "Add python.exe to PATH" - then run this again.)) & pause & exit /b
"""Spark Studio library updater for Windows. Just double-click update-spark.bat.

The line above is a tiny Windows launcher; everything below it is Python, run with
"py -x" (which skips that first line).

What it does:
  - Lists your Pinterest boards and downloads new pins from the boards you use,
    straight into the matching Spark folder (see BOARDS below).
  - Pins from your reference boards go to "_To sort", because only you can say
    whether each one belongs in Photo-Figure or Photo-Portrait.
  - Downloads new ArtStation likes into "ArtStation Likes".
  - Skips every image you already have, wherever you filed it, by recognising the
    Pinterest pin ID or image hash in its file name. Images it downloads are
    remembered, so deleting one later doesn't bring it back.
"""
import json
import os
import re
import subprocess
import sys
import time

PINTEREST_USER = "JasonLayel"
ARTSTATION_LIKES = "https://www.artstation.com/jasonlayel/likes"
BROWSER = "firefox"  # the browser you're logged in to Pinterest with: firefox, chrome or edge

TO_SORT = "_To sort"
ARTSTATION_FOLDER = "ArtStation Likes"
# Pinterest board -> Spark folder. Board names match ignoring case, punctuation and "&" vs "and".
# A "loose" rule also catches any board whose name contains that word (e.g. "Figure Reference").
BOARDS = [
    {"board": "Digital Painting",           "folder": "Environments"},
    {"board": "Sketching",                  "folder": "Character-Sketch"},
    {"board": "Character Design & Fashion", "folder": "Character-Render"},
    {"board": "Reference",                  "folder": TO_SORT, "loose": True},
    {"board": "Sculpture",                  "folder": TO_SORT, "loose": True},
]
# Spark folders whose images came from Pinterest (used to recognise the Spark folder
# and to check, on the first run, how many existing images can be matched to pins).
PINTEREST_FOLDERS = ("Environments", "Character-Sketch", "Character-Render", "Photo-Figure", "Photo-Portrait")

DATA_DIR = os.path.join(os.environ.get("LOCALAPPDATA") or os.path.expanduser("~"), "SparkStudio")
SETTINGS_FILE = os.path.join(DATA_DIR, "settings.json")
KNOWN_FILE = os.path.join(DATA_DIR, "known-images.json")
FILTER_FILE = os.path.join(DATA_DIR, "gallery-dl-filter.json")
ARCHIVE_FILE = os.path.join(DATA_DIR, "gdl-archive.sqlite3")

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".avif", ".bmp", ".heic", ".heif"}
# A pin ID, alone ("311944711663121720") or as gallery-dl names it ("pinterest_311944711663121720_2"),
# and Pinterest's 32-character image code. Copy suffixes like " (1)" are allowed.
PIN_ID_RE = re.compile(r"^(?:pinterest_(\d+)|(\d{9,20}))(?:[ _(-].*)?$", re.IGNORECASE)
HASH_RE = re.compile(r"^([0-9a-f]{32})(?:[ _(-].*)?$", re.IGNORECASE)
QUEUE = 6                                                    # gallery-dl -j message type for a board


def norm(name):
    words = re.sub(r"[^a-z0-9]+", " ", name.lower().replace("&", " and ")).split()
    return "".join(w for w in words if w != "and")


def board_rule(name):
    n = norm(name)
    for rule in BOARDS:
        if n == norm(rule["board"]):
            return rule
    for rule in BOARDS:
        if rule.get("loose") and norm(rule["board"]) in n:
            return rule
    return None


def load_json(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f)
    os.replace(tmp, path)


def ask_yes(question):
    return input(question + " [y/N] ").strip().lower() in ("y", "yes")


def pick_folder(initial=None):
    print("A window will open: choose your Spark folder (the one with Environments, Character-Sketch, ...).")
    try:
        import tkinter
        from tkinter import filedialog
        root = tkinter.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        path = filedialog.askdirectory(parent=root, title="Choose your Spark folder",
                                       initialdir=initial or "", mustexist=True)
        root.destroy()
    except Exception:
        path = input("Paste the path of your Spark folder and press Enter: ").strip().strip('"')
    return os.path.normpath(path) if path else ""


def looks_like_spark(folder):
    try:
        names = {n.lower() for n in os.listdir(folder)}
    except OSError:
        return False
    return any(f.lower() in names for f in PINTEREST_FOLDERS)


def countdown_start(seconds=10):
    """True to start; False if you pressed C to choose a different folder."""
    if os.name != "nt":
        return input("Press Enter to start, or C then Enter to choose a different folder: ").strip().lower() != "c"
    import msvcrt
    print(f"Starting in {seconds} seconds. Press Enter to start now, or C to choose a different folder.")
    end = time.time() + seconds
    while time.time() < end:
        if msvcrt.kbhit():
            key = msvcrt.getwch().lower()
            if key == "c":
                return False
            if key in ("\r", "\n", " "):
                return True
        time.sleep(0.05)
    return True


def choose_spark_dir(settings):
    folder = settings.get("spark_dir")
    if folder and os.path.isdir(folder):
        print(f"Spark folder: {folder}")
        if countdown_start():
            return folder
    while True:
        folder = pick_folder(folder)
        if not folder:
            return ""
        if looks_like_spark(folder) or ask_yes(
                f"{folder} doesn't contain any of {', '.join(PINTEREST_FOLDERS)}. Use it anyway?"):
            settings["spark_dir"] = folder
            save_json(SETTINGS_FILE, settings)
            print(f"Spark folder: {folder}")
            return folder


def scan(folder):
    """Pin IDs and image hashes found in image file names, image counts per top-level folder,
    and a few names that couldn't be matched."""
    ids, hashes, counts, matched, unmatched = set(), set(), {}, {}, []
    for dirpath, _dirnames, filenames in os.walk(folder):
        rel = os.path.relpath(dirpath, folder)
        top = "" if rel == "." else rel.split(os.sep)[0]
        for fn in filenames:
            stem, ext = os.path.splitext(fn)
            if ext.lower() not in IMAGE_EXTS:
                continue
            counts[top] = counts.get(top, 0) + 1
            m = PIN_ID_RE.match(stem)
            h = None if m else HASH_RE.match(stem)
            if m:
                ids.add(m.group(1) or m.group(2))
            elif h:
                hashes.add(h.group(1).lower())
            else:
                if len(unmatched) < 200:
                    unmatched.append((top, fn))
                continue
            matched[top] = matched.get(top, 0) + 1
    return ids, hashes, counts, matched, unmatched


def gdl(args, capture=False):
    cmd = [sys.executable, "-m", "gallery_dl", *args]
    if capture:
        return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return subprocess.run(cmd)


def upgrade_gallery_dl():
    return subprocess.run([sys.executable, "-m", "pip", "install", "--quiet", "--upgrade", "gallery-dl"]).returncode == 0


def list_boards():
    """[(board name, board URL)] from gallery-dl's board listing (no pins are downloaded)."""
    r = gdl(["--cookies-from-browser", BROWSER, "-j", f"https://www.pinterest.com/{PINTEREST_USER}/"], capture=True)
    try:
        messages = json.loads(r.stdout or "[]")
    except ValueError:
        messages = []
    boards = [((m[2].get("name") or m[1]).strip(), m[1]) for m in messages
              if isinstance(m, list) and len(m) >= 3 and m[0] == QUEUE and isinstance(m[2], dict)]
    problem = "; ".join(m[1].get("message", "") for m in messages
                        if isinstance(m, list) and len(m) >= 2 and m[0] == -1 and isinstance(m[1], dict))
    return boards, problem or (r.stderr or "").strip()[-600:]


def filter_expr(ids, hashes):
    """gallery-dl evaluates this for each file and skips it when False."""
    return f"str(id) not in {set(ids)!r} and str(filename).lower() not in {set(hashes)!r}"


def resolve_folder(spark, name):
    for entry in os.listdir(spark):
        if entry.lower() == name.lower() and os.path.isdir(os.path.join(spark, entry)):
            return os.path.join(spark, entry)
    return os.path.join(spark, name)


def main():
    print("Spark Studio library updater\n")
    os.makedirs(DATA_DIR, exist_ok=True)
    settings = load_json(SETTINGS_FILE, {})
    spark = choose_spark_dir(settings)
    if not spark:
        print("No Spark folder chosen, so nothing was downloaded.")
        return

    print("\nMaking sure gallery-dl is installed and up to date...")
    if not upgrade_gallery_dl():
        print("Couldn't install gallery-dl. Check your internet connection and try again.")
        return

    known = load_json(KNOWN_FILE, {})
    ids, hashes, before, matched, unmatched = scan(spark)
    ids |= set(known.get("ids", []))
    hashes |= set(known.get("hashes", []))

    if not settings.get("first_run_done"):
        wanted = {f.lower() for f in PINTEREST_FOLDERS}
        total = sum(v for k, v in before.items() if k.lower() in wanted)
        ok = sum(v for k, v in matched.items() if k.lower() in wanted)
        print(f"\nYou have {total} images in your Pinterest folders. {ok} of them have a pin ID or image"
              f" hash in their name, so they'll be skipped.")
        if total and ok < total * 0.9:
            print(f"The other {total - ok} can't be matched to a pin. Any that are still on your boards may be"
                  f" downloaded again as second copies (Spark hides exact copies, but they take up space).")
            examples = [os.path.join(t, f) for t, f in unmatched if t.lower() in wanted][:6]
            if examples:
                print("Examples: " + ", ".join(examples))
            if not ask_yes("Continue?"):
                return

    print("\nReading your Pinterest boards...")
    boards, problem = list_boards()
    if not boards:
        print("Couldn't read your Pinterest boards. Make sure you're logged in to Pinterest in "
              f"{BROWSER.title()}, then run this again.")
        if problem:
            print("Details: " + problem)
    else:
        plan, skipped = [], []
        for name, url in boards:
            rule = board_rule(name)
            if rule:
                plan.append((name, url, rule["folder"]))
            else:
                skipped.append(name)
        for rule in BOARDS:
            if not any(board_rule(n) is rule for n, _ in boards):
                print(f"Note: no board called \"{rule['board']}\" was found.")
        if skipped:
            print("Not downloading these boards: " + ", ".join(skipped))
        for name, url, folder in plan:
            target = resolve_folder(spark, folder)
            print(f"\n=== Pinterest \"{name}\" -> {os.path.basename(target)} ===")
            save_json(FILTER_FILE, {"extractor": {"file-filter": filter_expr(ids, hashes)}})
            gdl(["--config", FILTER_FILE, "--cookies-from-browser", BROWSER, "--download-archive", ARCHIVE_FILE,
                 "--sleep-request", "0.5", "-D", target, url])
            if os.path.isdir(target):  # a pin saved to two boards only comes down once
                new_ids, new_hashes, _, _, _ = scan(target)
                ids |= new_ids
                hashes |= new_hashes

    target = resolve_folder(spark, ARTSTATION_FOLDER)
    print(f"\n=== ArtStation likes -> {os.path.basename(target)} ===")
    gdl(["--download-archive", ARCHIVE_FILE, "--sleep-request", "0.5", "-D", target, ARTSTATION_LIKES])

    after_ids, after_hashes, after, _, _ = scan(spark)
    save_json(KNOWN_FILE, {"ids": sorted(ids | after_ids), "hashes": sorted(hashes | after_hashes)})
    settings["first_run_done"] = True
    save_json(SETTINGS_FILE, settings)

    added = {k: after[k] - before.get(k, 0) for k in after if after[k] > before.get(k, 0)}
    print("\n=== Done ===")
    if added:
        for folder, n in sorted(added.items()):
            print(f"  {folder or '(top folder)'}: {n} new")
        if any(k.lower() == TO_SORT.lower() for k in added):
            print(f"Move the images in \"{TO_SORT}\" into Photo-Figure or Photo-Portrait when you have a minute.")
    else:
        print("  Nothing new. You're up to date.")
    print("When Google Drive finishes syncing, press Refresh in Spark Studio.")


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(errors="replace")
    except Exception:
        pass
    try:
        main()
    except KeyboardInterrupt:
        print("\nStopped.")
    except Exception as exc:
        print(f"\nSomething went wrong: {exc!r}")
        print("Copy the text in this window if you want help with it.")
    sys.exit(0)
