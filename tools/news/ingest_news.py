import argparse
import hashlib
import html
import json
import re
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from xml.etree import ElementTree

import requests


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "apps" / "fuelsense_mobile" / "assets" / "news" / "news_preview.json"

FEEDS = [
    {
        "url": "https://news.google.com/rss/search?q=petrol+diesel+ethanol+fuel+India+when%3A7d&hl=en-IN&gl=IN&ceid=IN:en",
        "source": "Google News India - Fuel",
        "category": "fuel",
    },
    {
        "url": "https://news.google.com/rss/search?q=automobile+cars+India+when%3A7d&hl=en-IN&gl=IN&ceid=IN:en",
        "source": "Google News India - Auto",
        "category": "vehicle",
    },
]

FUEL_KEYWORDS = (
    "fuel", "petrol", "diesel", "ethanol", "e20", "e85",
    "oil", "crude", "gasoline", "biofuel", "fuel price",
)

USER_AGENT = "FuelSense-GIS-News/1.0"
REQUEST_TIMEOUT = 15
MAX_PER_CATEGORY = 100


def clean_text(value):
    if not value:
        return ""
    value = html.unescape(str(value))
    value = re.sub(r"<[^>]+>", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def article_id(url):
    return hashlib.sha256(url.strip().encode("utf-8")).hexdigest()[:40]


def published_date(value):
    if not value:
        return None

    try:
        result = parsedate_to_datetime(value)
        if result.tzinfo is None:
            result = result.replace(tzinfo=timezone.utc)
        return result.astimezone(timezone.utc)
    except (TypeError, ValueError, OverflowError):
        return None


def text_of(item, tag):
    child = item.find(tag)
    if child is not None:
        return clean_text(child.text)

    for child in item.iter():
        if child.tag.rsplit("}", 1)[-1] == tag:
            return clean_text(child.text)

    return ""


def image_of(item):
    for child in item.iter():
        if child.tag.rsplit("}", 1)[-1] in ("thumbnail", "content", "enclosure"):
            candidate = child.attrib.get("url", "").strip()
            if candidate.startswith("https://"):
                return candidate
    return ""


def relevant(title, summary, category):
    text = f" {title} {summary} ".lower()

    if category == "fuel":
        keywords = FUEL_KEYWORDS
    elif category == "vehicle":
        keywords = (
            "car", "cars", "automotive", "automobile", "vehicle",
            "vehicles", "motorcycle", "motorbike", "scooter",
            "electric vehicle", "hybrid", "engine", "automaker",
            "automotive industry", "passenger vehicle", "commercial vehicle",
            "car launch", "car sales", "car market", "auto industry",
            "two-wheeler", "two wheeler", "four-wheeler", "four wheeler",
            "mileage", "fuel efficiency", "emission", "emissions",
            "petrol", "diesel", "ethanol", "flex fuel", "e20",
            "toyota", "maruti", "tata motors", "mahindra", "hyundai",
            "honda", "suzuki", "kia", "bmw", "mercedes-benz", "volkswagen",
            "nissan", "renault", "skoda", "volvo", "bajaj", "hero motocorp",
            "tvs motor", "royal enfield"
        )
    else:
        return False

    return any(
        re.search(
            rf"(?<![a-z0-9]){re.escape(keyword)}(?![a-z0-9])",
            text,
        )
        for keyword in keywords
    )


def fetch_feed(feed):
    response = requests.get(
        feed["url"],
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/rss+xml, application/xml, text/xml",
        },
        timeout=REQUEST_TIMEOUT,
    )
    response.raise_for_status()

    root = ElementTree.fromstring(response.content)
    return [
        item
        for item in root.iter()
        if item.tag.rsplit("}", 1)[-1] == "item"
    ]


def build_article(item, feed):
    title = text_of(item, "title")
    summary = text_of(item, "description")

    link = ""
    for child in item:
        if child.tag.rsplit("}", 1)[-1] == "link":
            link = clean_text(child.text or child.attrib.get("href", ""))
            if link:
                break

    date = published_date(text_of(item, "pubDate"))

    if not title or not link or not date:
        return None

    if not link.startswith("https://"):
        return None

    if not relevant(title, summary, feed["category"]):
        return None

    return {
        "id": article_id(link),
        "title": title,
        "summary": summary[:1200],
        "url": link,
        "imageUrl": image_of(item),
        "source": feed["source"],
        "category": feed["category"],
        "publishedAt": date.isoformat(),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Prepare a local FuelSense GIS news preview."
    )
    parser.add_argument(
        "--publish",
        action="store_true",
        help="Reserved for a separately reviewed publishing workflow.",
    )
    args = parser.parse_args()

    if args.publish:
        parser.error(
            "Publishing is disabled in this safe preview script. "
            "No Firestore writes were performed."
        )

    articles = []
    seen_urls = set()
    counts = {
        "fetched": 0,
        "accepted": 0,
        "duplicates": 0,
        "rejected": 0,
        "feed_errors": 0,
    }

    session_results = []

    for feed in FEEDS:
        try:
            items = fetch_feed(feed)
            counts["fetched"] += len(items)
            accepted_for_feed = 0

            for item in items:
                article = build_article(item, feed)

                if article is None:
                    counts["rejected"] += 1
                    continue

                key = article["url"].strip().lower()
                if key in seen_urls:
                    counts["duplicates"] += 1
                    continue

                seen_urls.add(key)
                articles.append(article)
                accepted_for_feed += 1
                counts["accepted"] += 1

            session_results.append(
                f"{feed['category']}: {accepted_for_feed} accepted"
            )

        except (requests.RequestException, ElementTree.ParseError) as error:
            counts["feed_errors"] += 1
            session_results.append(
                f"{feed['category']}: feed failed ({type(error).__name__})"
            )

    articles.sort(key=lambda article: article["publishedAt"], reverse=True)

    limited = []
    category_counts = {"fuel": 0, "vehicle": 0}

    for article in articles:
        category = article["category"]
        if category_counts[category] >= MAX_PER_CATEGORY:
            continue
        category_counts[category] += 1
        limited.append(article)

    if not limited:
        print("No valid articles fetched. Existing preview was preserved.")
        print("\n".join(session_results))
        return

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary_output = OUTPUT.with_suffix(".tmp")
    temporary_output.write_text(
        json.dumps(limited, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary_output.replace(OUTPUT)

    print("Local news preview updated.")
    print(f"Output: {OUTPUT}")
    print(f"Saved articles: {len(limited)}")
    print(f"Categories: {category_counts}")
    print(f"Feed results: {session_results}")
    print(f"Summary: {counts}")
    print("Firestore writes: 0")


if __name__ == "__main__":
    main()
