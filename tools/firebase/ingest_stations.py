import argparse
import json
import sys
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore


PROJECT_ID = "fuelsense-ai-b3e97"
SHARDS_DIR = (
    Path(__file__).resolve().parents[2]
    / "apps"
    / "fuelsense-backend-fastapi"
    / "services-go"
    / "data"
    / "india-fuel-pumps"
    / "shards"
)

BATCH_SIZE = 400


def initialize_firestore():
    if not firebase_admin._apps:
        app = firebase_admin.initialize_app(
            credentials.ApplicationDefault(),
            {"projectId": PROJECT_ID},
        )
    else:
        app = firebase_admin.get_app()

    return firestore.client(app)


def clean_optional(value: Any):
    if value is None or value == "":
        return None
    return value


def transform_outlet(outlet: dict[str, Any]) -> dict[str, Any]:
    products = []

    for product in outlet.get("products") or []:
        products.append(
            {
                "name": str(product.get("name") or ""),
                "priceInr": (
                    float(product["priceInr"])
                    if isinstance(product.get("priceInr"), (int, float))
                    else None
                ),
            }
        )

    return {
        "schemaVersion": outlet.get("schemaVersion", 1),
        "brand": clean_optional(outlet.get("brand")),
        "outletId": clean_optional(outlet.get("outletId")),
        "sourceUrl": clean_optional(outlet.get("sourceUrl")),
        "capturedAt": clean_optional(outlet.get("capturedAt")),
        "name": clean_optional(outlet.get("name")),
        "address": clean_optional(outlet.get("address")),
        "city": clean_optional(outlet.get("city")),
        "state": clean_optional(outlet.get("state")),
        "pincode": clean_optional(outlet.get("pincode")),
        "latitude": float(outlet["lat"]),
        "longitude": float(outlet["lng"]),
        "geohash": clean_optional(outlet.get("geohash")),
        "hours": clean_optional(outlet.get("hours")),
        "contact": clean_optional(outlet.get("contact")),
        "mapsLink": clean_optional(outlet.get("mapsLink")),
        "amenities": outlet.get("amenities"),
        "categories": outlet.get("categories") or [],
        "fuelProducts": products,
    }


def validate_outlet(outlet: dict[str, Any], source: Path) -> str:
    station_id = str(outlet.get("stationId") or "").strip()

    if not station_id:
        raise ValueError(f"Missing stationId in {source}")

    if "lat" not in outlet or "lng" not in outlet:
        raise ValueError(f"Missing coordinates for {station_id} in {source}")

    lat = outlet["lat"]
    lng = outlet["lng"]

    if not isinstance(lat, (int, float)) or not isinstance(lng, (int, float)):
        raise ValueError(f"Non-numeric coordinates for {station_id} in {source}")

    if not -90 <= lat <= 90 or not -180 <= lng <= 180:
        raise ValueError(f"Invalid coordinates for {station_id} in {source}")

    if not str(outlet.get("name") or "").strip():
        raise ValueError(f"Missing station name for {station_id} in {source}")

    return station_id


def load_outlets():
    files = sorted(SHARDS_DIR.glob("*.json"))

    if not files:
        raise FileNotFoundError(f"No JSON shards found at {SHARDS_DIR}")

    seen_ids: set[str] = set()
    total = 0

    for path in files:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)

        for outlet in data.get("outlets", []):
            station_id = validate_outlet(outlet, path)

            if station_id in seen_ids:
                raise ValueError(f"Duplicate stationId detected: {station_id}")

            seen_ids.add(station_id)
            total += 1

            yield station_id, transform_outlet(outlet)

    print(f"Validated {total:,} station records from {len(files)} shards.")
    print(f"Unique station IDs: {len(seen_ids):,}")


def dry_run():
    count = 0
    sample = None

    for station_id, document in load_outlets():
        count += 1

        if sample is None:
            sample = (station_id, document)

    print()
    print("DRY RUN: no Firestore writes performed.")
    print(f"Records ready for ingestion: {count:,}")

    if sample:
        station_id, document = sample
        print()
        print("Sample Firestore document ID:")
        print(station_id)
        print()
        print("Sample Firestore document:")
        print(json.dumps(document, indent=2, ensure_ascii=False))


def ingest(skip: int = 0, limit: int | None = None):

    db = initialize_firestore()
    collection = db.collection("stations")
    batch = db.batch()
    pending = 0
    written = 0
    processed = 0

    try:
        for index, (station_id, document) in enumerate(load_outlets()):
            if index < skip:
                continue
            if limit is not None and processed >= limit:
                break

            processed += 1
            batch.set(collection.document(station_id), document, merge=True)
            pending += 1

            if pending >= BATCH_SIZE:
                batch.commit()
                written += pending
                next_skip = skip + written
                print(
                    f"Committed {written:,} records "
                    f"(source index {skip:,} -> {next_skip:,})."
                )
                batch = db.batch()
                pending = 0

        if pending:
            batch.commit()
            written += pending

    except Exception as exc:
        next_skip = skip + written
        print()
        print("Firestore ingestion stopped before completion.")
        print(f"Successful commits in this run: {written:,}")
        print(f"Next validated source index: {next_skip:,}")
        print(
            "Resume command: "
            f"python3 tools/firebase/ingest_stations.py --write --skip {next_skip}"
        )
        raise exc

    print()
    print(f"Firestore ingestion complete: {written:,} documents.")


def main():
    parser = argparse.ArgumentParser(
        description="Ingest FuelSense GIS fuel stations into Firestore."
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually write station documents to Firestore.",
    )
    parser.add_argument(
        "--skip",
        type=int,
        default=0,
        help="Skip this many validated records before writing.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Write at most this many records after the skipped records.",
    )

    args = parser.parse_args()

    if args.skip < 0:
        parser.error("--skip cannot be negative")

    if args.write:
        ingest(skip=args.skip, limit=args.limit)
    else:
        dry_run()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
