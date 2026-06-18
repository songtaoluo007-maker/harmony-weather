#!/usr/bin/env python3
"""Fetch and package a representative photo for every configured city.

The source list comes from weather_config.json. Each city page image is resolved
through MediaWiki, composed into a mobile portrait background, and an ArkTS
resource map is generated. Re-running this script updates every city in one pass.
"""

from __future__ import annotations

import io
import json
import os
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "entry/src/main/resources/rawfile/weather_config.json"
MEDIA = ROOT / "entry/src/main/resources/base/media"
MAPPING = ROOT / "entry/src/main/ets/theme/BundledCityBackgrounds.ets"
SOURCES = ROOT / "CITY_BACKGROUND_SOURCES.md"
USER_AGENT = "harmony-weather/1.0 (city background asset builder)"
CANVAS_SIZE = (1080, 1920)


def request_json(url: str) -> dict:
    if os.name == "nt":
        return json.loads(powershell_download(url).decode("utf-8-sig"))
    try:
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=15) as response:
            return json.load(response)
    except OSError:
        return json.loads(powershell_download(url).decode("utf-8-sig"))


def request_bytes(url: str) -> bytes:
    if "upload.wikimedia.org" in url:
        direct_url = url
        if "/thumb/" in url:
            prefix, thumb_path = url.split("/thumb/", 1)
            url = prefix + "/" + "/".join(thumb_path.split("/")[:-1])
        url = urllib.parse.unquote(url)
        url = "https://wsrv.nl/?" + urllib.parse.urlencode({"url": url, "w": "1400", "output": "jpg", "q": "84"})
        if os.name == "nt":
            try:
                return powershell_download(url, quick=True)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                return powershell_download(direct_url)
    if os.name == "nt":
        return powershell_download(url)
    try:
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=20) as response:
            return response.read()
    except OSError:
        return powershell_download(url)


def powershell_download(url: str, quick: bool = False) -> bytes:
    delays = (2,) if quick else (2, 8, 20)
    for attempt, delay in enumerate(delays, start=1):
        with tempfile.NamedTemporaryFile(delete=False) as temporary:
            destination = Path(temporary.name)
        escaped_url = url.replace("'", "''")
        escaped_destination = str(destination).replace("'", "''")
        command = (
            "$ProgressPreference='SilentlyContinue'; "
            f"Invoke-WebRequest -UseBasicParsing -Uri '{escaped_url}' "
            f"-Headers @{{'User-Agent'='{USER_AGENT}'}} -OutFile '{escaped_destination}'"
        )
        try:
            time.sleep(delay)
            subprocess.run(
                ["powershell", "-NoProfile", "-Command", command],
                check=True,
                timeout=60,
                capture_output=attempt < len(delays),
            )
            return destination.read_bytes()
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            if attempt == len(delays):
                raise
        finally:
            destination.unlink(missing_ok=True)
    raise RuntimeError(f"Unable to download {url}")


def resolve_city_image(city_name: str) -> tuple[str, str, str]:
    candidates = [city_name] if city_name.endswith("市") else [f"{city_name}市", city_name]
    for title in candidates:
        query = urllib.parse.urlencode(
            {
                "action": "query",
                "prop": "pageimages|info",
                "piprop": "thumbnail",
                "pithumbsize": "1800",
                "inprop": "url",
                "format": "json",
                "formatversion": "2",
                "titles": title,
            }
        )
        payload = request_json(f"https://zh.wikipedia.org/w/api.php?{query}")
        pages = payload.get("query", {}).get("pages", [])
        if pages and pages[0].get("thumbnail", {}).get("source"):
            page = pages[0]
            return page["thumbnail"]["source"], page.get("fullurl", ""), page.get("title", title)
    raise RuntimeError(f"No city image found for {city_name}")


def resolve_city_images(city_names: list[str]) -> dict[str, tuple[str, str, str]]:
    titles = [name if name.endswith("市") else f"{name}市" for name in city_names]
    query = urllib.parse.urlencode(
        {
            "action": "query",
            "prop": "pageimages|info",
            "piprop": "thumbnail",
            "pithumbsize": "1400",
            "inprop": "url",
            "format": "json",
            "formatversion": "2",
            "titles": "|".join(titles),
        }
    )
    payload = request_json(f"https://zh.wikipedia.org/w/api.php?{query}")
    result: dict[str, tuple[str, str, str]] = {}
    for page in payload.get("query", {}).get("pages", []):
        thumbnail = page.get("thumbnail", {}).get("source")
        if not thumbnail:
            continue
        normalized = page.get("title", "").removesuffix("市")
        result[normalized] = (thumbnail, page.get("fullurl", ""), page.get("title", normalized))
    return result


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(image, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def compose_portrait(source: bytes) -> Image.Image:
    with Image.open(io.BytesIO(source)) as opened:
        image = ImageOps.exif_transpose(opened).convert("RGB")

    backdrop = cover(image, CANVAS_SIZE).filter(ImageFilter.GaussianBlur(34))
    backdrop = ImageEnhance.Brightness(backdrop).enhance(0.76)

    foreground = image.copy()
    scale = CANVAS_SIZE[0] / foreground.width
    target_height = max(1, round(foreground.height * scale))
    foreground = foreground.resize((CANVAS_SIZE[0], target_height), Image.Resampling.LANCZOS)
    if foreground.height > 1160:
        foreground = ImageOps.fit(foreground, (CANVAS_SIZE[0], 1160), method=Image.Resampling.LANCZOS)

    y = min(900, CANVAS_SIZE[1] - foreground.height)
    mask = Image.new("L", foreground.size, 255)
    pixels = mask.load()
    fade = min(220, foreground.height // 3)
    for row in range(fade):
        alpha = round(255 * row / max(1, fade - 1))
        for column in range(foreground.width):
            pixels[column, row] = alpha

    backdrop.paste(foreground, (0, y), mask)
    return backdrop


def generate_mapping(records: list[dict]) -> None:
    cases = []
    for record in records:
        cases.append(
            "      case '%s': return new BundledCityBackground($r('app.media.city_bg_%s'), '%s')"
            % (record["id"], record["id"], record["attribution"].replace("'", "\\'"))
        )
    source = """export class BundledCityBackground {
  resource: Resource
  attribution: string

  constructor(resource: Resource, attribution: string) {
    this.resource = resource
    this.attribution = attribution
  }
}

export class BundledCityBackgrounds {
  static resolve(cityId: string): BundledCityBackground | null {
    switch (cityId) {
%s
      default: return null
    }
  }
}
""" % "\n".join(cases)
    MAPPING.write_text(source, encoding="utf-8")


def generate_sources(records: list[dict]) -> None:
    lines = [
        "# City background sources",
        "",
        "Generated by `scripts/fetch_city_backgrounds.py` from each configured city's Wikipedia page image.",
        "The runtime UI displays a compact Wikimedia/Wikipedia attribution for the active city.",
        "",
    ]
    for record in records:
        lines.append(f"- {record['name']} ({record['id']}): [{record['title']}]({record['page_url']})")
    lines.append("")
    SOURCES.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    MEDIA.mkdir(parents=True, exist_ok=True)
    records = []
    resolved = resolve_city_images([city["name"] for city in config["cities"]])
    for city in config["cities"]:
        city_image = resolved.get(city["name"])
        if city_image is None:
            city_image = resolve_city_image(city["name"])
        image_url, page_url, title = city_image
        output = MEDIA / f"city_bg_{city['id']}.jpg"
        if not output.exists():
            compose_portrait(request_bytes(image_url)).save(output, "JPEG", quality=84, optimize=True, progressive=True)
        records.append(
            {
                "id": city["id"],
                "name": city["name"],
                "title": title,
                "page_url": page_url,
                "attribution": f"城市影像 · 维基百科 · {title}",
            }
        )
        print(f"{city['name']}: {output.name}")
    generate_mapping(records)
    generate_sources(records)


if __name__ == "__main__":
    main()
