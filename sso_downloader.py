# sso_downloader.py
# ------------------------------------------------------------
# Downloads the rendered HTML of an SSO-protected page and the
# content/HTML from all hyperlinks on that page using your
# existing browser profile (Edge/Chrome).
#
# Requirements:
#   pip install playwright
#   playwright install
#   (optional for Edge) playwright install msedge
#
# First run tip:
#   Set HEADLESS=False to interactively sign in if needed.
# ------------------------------------------------------------

import hashlib
import os
import re
import sys
import time
from pathlib import Path
from urllib.parse import urlparse, urljoin, urldefrag, quote

from playwright.sync_api import sync_playwright

# -------------------- CONFIG --------------------

START_URL = "https://docs.intel.com/documents/OORJA_Repo/index.html"  # <-- Put the page you're viewing via SSO

# Where to save - can be overridden by command line argument
OUTPUT_DIR = Path("web_pages")

# Only download links from the same domain as START_URL?
SAME_DOMAIN_ONLY = True

# Crawl depth:
# 0 = only the START_URL page's links
# 1 = links from START_URL, then links found on those pages, etc.
CRAWL_DEPTH = 0

# Browser settings
BROWSER_CHANNEL = "msedge"  # "msedge" for Edge, "chrome" for Chrome, or None for default chromium
HEADLESS = False            # Set to False on first run if you need to sign in interactively

# Path to your browser user data dir to reuse SSO cookies (VERY IMPORTANT)
USER_DATA_DIR = None  # Set to None to use a temporary profile (you'll need to login)

# Optional include/exclude filters for URLs (regex)
# Set to empty list to download ALL sections automatically
INCLUDE_PATTERNS = []  # Empty = download ALL sections
EXCLUDE_PATTERNS = [r"logout", r"\.zip(\?.*)?$"]  # add anything you want to skip

# Known section names to automatically detect and organize
# These will be auto-detected from URLs, but you can add more here
KNOWN_SECTIONS = [
    "Power and Battery Life Workloads",
    "Performance Workloads",
    "Responsiveness and UX Workloads",
    "Automation and Debug Methodology",
    "PnP Project Details",
    "Chrome OS BKM",
    "Hardware Micros",
    "Regulatory Workloads",
    "Windows 10x Workloads",
    "Optane Delta Config Workloads",
    "Telemetry Workloads",
    "Soon to be Deprecated (post 2020)",
    "PnP Domain Knowledge Base",
    "Experience Based Design",
]

# HTTP timeouts (ms) — adjust if pages are slow
NAVIGATION_TIMEOUT_MS = 60000
REQUEST_TIMEOUT_MS = 60000

# Common "binary" file extensions we want to download as files
BINARY_EXTS = {
    ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
    ".csv", ".zip", ".rar", ".7z", ".gz", ".tar",
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".svg", ".webp",
    ".mp4", ".mov", ".mkv", ".mp3", ".wav", ".json", ".txt"
}

# -------------------- HELPERS --------------------

def sanitize_filename(name: str) -> str:
    # Remove characters not allowed in file names across OSes
    name = re.sub(r"[<>:\"/\\|?*\x00-\x1F]", "_", name)
    name = re.sub(r"\s+", "_", name).strip()  # Replace spaces with underscores
    return name or "untitled"

def url_without_fragment(u: str) -> str:
    u, _ = urldefrag(u)
    return u

def detect_section_from_url(url: str) -> str:
    """
    Automatically detect which section a URL belongs to based on known section names.
    Returns the section folder name (sanitized) or 'other' if not detected.
    """
    url_decoded = url.replace("%20", " ")
    
    # Check against known sections
    for section in KNOWN_SECTIONS:
        if section in url_decoded:
            return sanitize_filename(section)
    
    # Try to extract section from URL path (between OORJA_Repo/ and next /)
    path = urlparse(url_decoded).path
    if "/OORJA_Repo/" in path:
        parts = path.split("/OORJA_Repo/", 1)[-1].split("/")
        if len(parts) > 0 and parts[0]:
            # Check if this looks like a section name (not a file)
            potential_section = parts[0]
            if not potential_section.endswith('.html'):
                return sanitize_filename(potential_section)
    
    return "other"

def should_keep(url: str, base_netloc: str) -> bool:
    # Domain restriction
    parsed = urlparse(url)
    if SAME_DOMAIN_ONLY and parsed.netloc and parsed.netloc.lower() != base_netloc.lower():
        return False

    # Filters
    if INCLUDE_PATTERNS:
        if not any(re.search(p, url, re.IGNORECASE) for p in INCLUDE_PATTERNS):
            return False
    if EXCLUDE_PATTERNS:
        if any(re.search(p, url, re.IGNORECASE) for p in EXCLUDE_PATTERNS):
            return False
    return True

def ext_from_url(url: str) -> str:
    path = urlparse(url).path
    _, ext = os.path.splitext(path)
    return ext.lower()

def html_save_path_for_url(base_origin: str, url: str) -> Path:
    """
    Build a deterministic local path for HTML pages.
    Automatically organizes files into folders based on their detected section.
    """
    parsed = urlparse(url)
    
    # Automatically detect which section this URL belongs to
    section_folder = detect_section_from_url(url)
    
    # Make a base directory with section folder
    root = OUTPUT_DIR / section_folder

    # Directory from path (excluding file name)
    # Extract the path after the section name and remove section prefix to avoid deep nesting
    path_str = parsed.path
    url_decoded = url.replace("%20", " ")
    
    # Try to remove section prefix from path
    for section in KNOWN_SECTIONS:
        section_encoded = section.replace(" ", "%20")
        if section_encoded in path_str:
            path_str = path_str.split(section_encoded + "/", 1)[-1]
            break
    
    dir_path = Path(sanitize_filename(path_str)).parent
    # Ensure directories end up nested under root
    if str(dir_path).startswith("/"):
        dir_path = Path(str(dir_path)[1:])
    full_dir = root / dir_path

    # Determine file name
    leaf = Path(path_str).name
    if not leaf or leaf.endswith("/"):
        fname = "index.html"
    else:
        name, ext = os.path.splitext(leaf)
        if ext.lower() in (".html", ".htm"):
            fname = sanitize_filename(leaf)
        elif ext and ext.lower() not in (".html", ".htm"):
            # Not a typical HTML extension; still save as .html (rendered)
            fname = sanitize_filename(leaf) + ".html"
        else:
            fname = sanitize_filename(leaf) + ".html"

    # Encode query into a short hash to prevent overwrite
    if parsed.query:
        qhash = hashlib.sha1(parsed.query.encode("utf-8")).hexdigest()[:8]
        stem, ext = os.path.splitext(fname)
        fname = f"{stem}-{qhash}{ext}"

    return (full_dir / fname)

def binary_save_path_for_url(base_origin: str, url: str) -> Path:
    """
    Build local path for binary downloads, keeping original file name if present.
    Automatically organizes files into folders based on their detected section.
    """
    parsed = urlparse(url)
    
    # Automatically detect which section this URL belongs to
    section_folder = detect_section_from_url(url)
    
    root = OUTPUT_DIR / section_folder

    # If URL has a file name, use it; otherwise generate one
    leaf = Path(parsed.path).name
    if not leaf:
        # Generate a name from URL hash
        qhash = hashlib.sha1(url.encode("utf-8")).hexdigest()[:10]
        leaf = f"download-{qhash}"

    # If no extension, keep as-is
    fname = sanitize_filename(leaf)

    # Add small query hash to avoid collisions if different querystrings map to same path
    if parsed.query:
        stem, ext = os.path.splitext(fname)
        qhash = hashlib.sha1(parsed.query.encode("utf-8")).hexdigest()[:8]
        fname = f"{stem}-{qhash}{ext}"

    # Keep directory structure under root, but remove section prefix
    path_str = parsed.path
    
    # Try to remove section prefix from path
    for section in KNOWN_SECTIONS:
        section_encoded = section.replace(" ", "%20")
        if section_encoded in path_str:
            path_str = path_str.split(section_encoded + "/", 1)[-1]
            break
    
    dir_path = Path(sanitize_filename(path_str)).parent
    if str(dir_path).startswith("/"):
        dir_path = Path(str(dir_path)[1:])

    return (root / dir_path / fname)

def ensure_parent(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)

def is_probably_binary_by_ext(url: str) -> bool:
    return ext_from_url(url) in BINARY_EXTS

# -------------------- CORE --------------------

def collect_links(page, current_url: str) -> list:
    """Return absolute URLs from all <a href> elements on the current page."""
    # Use JavaScript in the page context to collect absolute hrefs
    hrefs = page.eval_on_selector_all("a[href]", "els => els.map(e => e.href)")
    print(f"DEBUG: Found {len(hrefs)} total links before filtering")
    # Normalize: remove fragments, and resolve relative URLs via current_url
    normalized = []
    for href in hrefs:
        if not href:
            continue
        if href.startswith("javascript:") or href.startswith("mailto:") or href.startswith("tel:"):
            continue
        abs_url = urljoin(current_url, href)
        abs_url = url_without_fragment(abs_url)
        normalized.append(abs_url)
    # Deduplicate while preserving order
    seen = set()
    unique = []
    for u in normalized:
        if u not in seen:
            unique.append(u)
            seen.add(u)
    print(f"DEBUG: {len(unique)} unique links after deduplication")
    # Show first few links for debugging
    if unique:
        print(f"DEBUG: First 3 links: {unique[:3]}")
    return unique

def save_rendered_html(page, url: str, save_path: Path, navigation_timeout_ms: int):
    try:
        page.goto(url, wait_until="networkidle", timeout=navigation_timeout_ms)
        html = page.content()
        ensure_parent(save_path)
        save_path.write_text(html, encoding="utf-8")
        print(f"[HTML] Saved: {save_path}")
    except Exception as e:
        print(f"[HTML] Failed: {url} -> {e}")

def download_binary(request_context, url: str, save_path: Path, request_timeout_ms: int):
    try:
        resp = request_context.get(url, timeout=request_timeout_ms / 1000, fail_on_status_code=False)
        if resp.ok:
            ensure_parent(save_path)
            save_path.write_bytes(resp.body())
            print(f"[FILE] Saved: {save_path} ({len(resp.body())} bytes)")
        else:
            print(f"[FILE] Failed: {url} -> HTTP {resp.status}")
    except Exception as e:
        print(f"[FILE] Failed: {url} -> {e}")

def crawl(start_url: str):
    with sync_playwright() as p:
        browser = p.chromium
        
        # Try to launch with persistent context (to reuse cookies)
        # If that fails (e.g., browser is running), fall back to regular context
        context = None
        page = None
        
        try:
            if USER_DATA_DIR:
                print(f"Attempting to use profile: {USER_DATA_DIR}")
                context = browser.launch_persistent_context(
                    user_data_dir=USER_DATA_DIR,
                    headless=HEADLESS,
                    channel=BROWSER_CHANNEL,
                    accept_downloads=True
                )
                page = context.pages[0] if context.pages else context.new_page()
            else:
                print("Using temporary profile (no USER_DATA_DIR specified)")
                browser_instance = browser.launch(
                    headless=HEADLESS,
                    channel=BROWSER_CHANNEL
                )
                context = browser_instance.new_context(accept_downloads=True)
                page = context.new_page()
        except Exception as e:
            print(f"Failed to launch with persistent context: {e}")
            print("\nTrying fallback mode (regular context)...")
            print("NOTE: You may need to login again in the browser window that opens.")
            browser_instance = browser.launch(
                headless=HEADLESS,
                channel=BROWSER_CHANNEL
            )
            context = browser_instance.new_context(accept_downloads=True)
            page = context.new_page()
        
        base = urlparse(start_url)
        base_origin = f"{base.scheme}://{base.netloc}"
        base_netloc = base.netloc

        # Go to the start page and save its rendered HTML
        print(f"Opening: {start_url}")
        save_path = html_save_path_for_url(base_origin, start_url)
        save_rendered_html(page, start_url, save_path, NAVIGATION_TIMEOUT_MS)

        # BFS crawl up to CRAWL_DEPTH
        visited = set()
        queue = [(start_url, 0)]
        all_links_to_process = []

        while queue:
            current, depth = queue.pop(0)
            if current in visited:
                continue
            visited.add(current)

            # Ensure the page is loaded in 'page' if we are not at the starting URL
            if depth > 0:
                try:
                    page.goto(current, wait_until="networkidle", timeout=NAVIGATION_TIMEOUT_MS)
                except Exception as e:
                    print(f"[NAV] Failed to open {current} -> {e}")
                    continue

            links = collect_links(page, current)
            # Filter
            filtered = [u for u in links if should_keep(u, base_netloc)]
            print(f"DEBUG: After filtering, {len(filtered)} links remain")
            if filtered and len(filtered) < 10:
                print(f"DEBUG: Filtered links: {filtered}")
            # Only gather links from the first page (depth 0) if CRAWL_DEPTH=0
            if depth == 0:
                all_links_to_process.extend(filtered)

            # Queue next depth if allowed
            if depth < CRAWL_DEPTH:
                for u in filtered:
                    if u not in visited:
                        queue.append((u, depth + 1))

        # Process collected links: download files or save rendered HTML
        req = context.request
        # Deduplicate
        dedup = []
        seen = set()
        for u in all_links_to_process:
            if u not in seen and u != start_url:
                dedup.append(u)
                seen.add(u)

        print(f"Found {len(dedup)} unique links to process.")
        
        # Track which sections are being downloaded
        sections_found = set()
        for url in dedup:
            section = detect_section_from_url(url)
            sections_found.add(section)
        
        print(f"Detected {len(sections_found)} sections: {', '.join(sorted(sections_found))}")
        print()
        
        for idx, url in enumerate(dedup, 1):
            print(f"({idx}/{len(dedup)}) {url}")
            if is_probably_binary_by_ext(url):
                path = binary_save_path_for_url(base_origin, url)
                download_binary(req, url, path, REQUEST_TIMEOUT_MS)
            else:
                path = html_save_path_for_url(base_origin, url)
                save_rendered_html(page, url, path, NAVIGATION_TIMEOUT_MS)

        context.close()
        print("\n" + "="*60)
        print("Download complete!")
        print(f"Files saved to: {OUTPUT_DIR}")
        print(f"Sections downloaded: {len(sections_found)}")
        for section in sorted(sections_found):
            section_dir = OUTPUT_DIR / section
            if section_dir.exists():
                file_count = len(list(section_dir.rglob("*.html")))
                print(f"  - {section}: {file_count} files")
        print("="*60)

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Download web pages from SSO-protected site and organize by section',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Download to default location (web_pages/)
  python sso_downloader.py
  
  # Download to baseline folder
  python sso_downloader.py --output baseline
  
  # Download to custom directory
  python sso_downloader.py --output "my_downloads/2026-02-04"
        """
    )
    
    parser.add_argument('--output', '-o', 
                       help='Output directory (default: web_pages)',
                       default='web_pages')
    parser.add_argument('--url',
                       help='Start URL to download from',
                       default=START_URL)
    
    args = parser.parse_args()
    
    # Update global OUTPUT_DIR with user input
    OUTPUT_DIR = Path(args.output)
    START_URL = args.url
    
    if START_URL.startswith("https://YOUR_SSO_PAGE_HERE"):
        print("Please set START_URL to your SSO page URL at the top of the script.")
        sys.exit(1)
    if USER_DATA_DIR is None:
        print(
            "WARNING: USER_DATA_DIR is not set. "
            "If your SSO requires existing cookies, set USER_DATA_DIR to your browser profile path. "
            "If you keep HEADLESS=False the first time, you can log in interactively."
        )
    
    print(f"Output directory: {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    crawl(START_URL)