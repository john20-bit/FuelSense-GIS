import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore

PROJECT_ID = "fuelsense-ai-b3e97"
COLLECTION_NAME = "stations"
BATCH_SIZE = 400
DAILY_TARGET = 18000
EXCLUDED_IDS = {"494e71856670b5f2"}

BASE_DIR = Path(__file__).resolve().parent
MANIFEST = BASE_DIR / "stations-import-manifest.json"
STATE_FILE = BASE_DIR / "stations-import-state.json"

SHARDS_DIR = (
    BASE_DIR.parents[1]
    / "apps"
    / "fuelsense-backend-fastapi"
    / "services-go"
    / "data"
    / "india-fuel-pumps"
    / "shards"
)


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
    return None if value is None or value == "" else value


def transform_outlet(outlet: dict[str, Any]) -> dict[str, Any]:
    products = []
    for product in outlet.get("products") or []:
        price = product.get("priceInr")
        products.append({
            "name": str(product.get("name") or ""),
            "priceInr": (
                float(price)
                if isinstance(price, (int, float))
                and not isinstance(price, bool)
                else None
            ),
        })

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


def read_shard(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if isinstance(data, list):
        records = data
    elif isinstance(data, dict):
        records = data.get("outlets", data.get("data"))
    else:
        records = None

    if not isinstance(records, list):
        raise ValueError(f"Unexpected JSON structure in {path}")

    for outlet in records:
        if not isinstance(outlet, dict):
            raise ValueError(f"Non-object station record in {path}")
        yield outlet


def validate_outlet(outlet: dict[str, Any], source: Path) -> str:
    station_id = str(outlet.get("stationId") or "").strip()
    if not station_id:
        raise ValueError(f"Missing stationId in {source}")

    lat, lng = outlet.get("lat"), outlet.get("lng")
    if (
        isinstance(lat, bool) or isinstance(lng, bool)
        or not isinstance(lat, (int, float))
        or not isinstance(lng, (int, float))
        or not -90 <= lat <= 90
        or not -180 <= lng <= 180
    ):
        raise ValueError(f"Invalid coordinates for {station_id} in {source}")

    if not str(outlet.get("name") or "").strip():
        raise ValueError(f"Missing station name for {station_id} in {source}")

    return station_id


def load_outlets():
    files = sorted(SHARDS_DIR.glob("*.json"))
    if not files:
        raise FileNotFoundError(f"No JSON shards found at {SHARDS_DIR}")

    seen = set()
    records = []
    excluded = 0

    for path in files:
        for outlet in read_shard(path):
            station_id = validate_outlet(outlet, path)
            if station_id in seen:
                raise ValueError(f"Duplicate stationId detected: {station_id}")
            seen.add(station_id)

            if station_id in EXCLUDED_IDS:
                excluded += 1
                continue

            records.append({
                "id": station_id,
                "data": transform_outlet(outlet),
            })

    if EXCLUDED_IDS - seen:
        raise ValueError(
            "Excluded station ID was not found in the source dataset: "
            + ", ".join(sorted(EXCLUDED_IDS - seen))
        )

    print(f"Validated records: {len(seen):,}")
    print(f"Source shards: {len(files):,}")
    print(f"Excluded records: {excluded:,}")
    print(f"Eligible source records: {len(records):,}")
    return records


def save_json_atomic(path: Path, payload):
    temp = path.with_suffix(path.suffix + ".tmp")
    with temp.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False)
        handle.flush()
        os.fsync(handle.fileno())
    temp.replace(path)


def prepare():
    if MANIFEST.exists():
        raise FileExistsError(
            f"{MANIFEST} already exists. It was not overwritten."
        )
    if STATE_FILE.exists():
        raise FileExistsError(
            f"{STATE_FILE} already exists. It was not overwritten."
        )

    records = load_outlets()
    db = initialize_firestore()

    print("Reading existing Firestore station IDs...")
    existing_ids = {
        doc.id for doc in db.collection(COLLECTION_NAME).stream()
    }

    missing = [r for r in records if r["id"] not in existing_ids]

    save_json_atomic(MANIFEST, missing)
    save_json_atomic(STATE_FILE, {
        "next_index": 0,
        "completed": 0,
        "created_batches": 0,
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "last_write_date_utc": None,
        "writes_today_utc": 0,
    })

    print("\nPREPARATION COMPLETE. No Firestore documents were changed.")
    print(f"Existing IDs observed: {len(existing_ids):,}")
    print(f"New documents in manifest: {len(missing):,}")
    print(f"Manifest: {MANIFEST}")
    print(f"Progress file: {STATE_FILE}")
    print("Review these counts before authorizing any writes.")


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_daily():
    if not MANIFEST.exists() or not STATE_FILE.exists():
        raise FileNotFoundError(
            "Manifest/progress files are missing. Run --prepare first."
        )

    records = load_json(MANIFEST)
    state = load_json(STATE_FILE)
    start = int(state["next_index"])

    if start >= len(records):
        print("All manifest records have already been processed.")
        return

    today_utc = datetime.now(timezone.utc).date().isoformat()
    if state.get("last_write_date_utc") == today_utc:
        raise RuntimeError(
            "A write run has already occurred today (UTC). "
            "Wait for the next UTC day before starting another run."
        )

    stop = min(start + DAILY_TARGET, len(records))
    db = initialize_firestore()
    collection = db.collection(COLLECTION_NAME)
    created_this_run = 0

    print(f"Manifest total: {len(records):,}")
    print(f"Starting index: {start:,}")
    print(f"Maximum planned creations this run: {stop - start:,}")
    print("Existing documents will never be merged or overwritten.")

    for offset in range(start, stop, BATCH_SIZE):
        chunk = records[offset:min(offset + BATCH_SIZE, stop)]
        batch = db.batch()

        for record in chunk:
            # create() uses an exists=false precondition. If an ID appeared
            # after preparation, the batch fails instead of overwriting it.
            batch.create(
                collection.document(record["id"]),
                record["data"],
            )

        # State advances only after Firestore confirms this whole batch.
        batch.commit()

        state["next_index"] = offset + len(chunk)
        state["completed"] = state["next_index"]
        state["created_batches"] = int(state["created_batches"]) + 1
        state["last_write_date_utc"] = today_utc
        state["writes_today_utc"] = created_this_run + len(chunk)
        save_json_atomic(STATE_FILE, state)

        created_this_run += len(chunk)
        print(
            f"Confirmed this run: {created_this_run:,}; "
            f"manifest progress: {state['next_index']:,}/{len(records):,}"
        )

    print(f"\nRun finished. Confirmed new documents: {created_this_run:,}")
    print(f"Remaining in manifest: {len(records) - state['next_index']:,}")
    print("Check Firebase Usage before proceeding on another quota day.")


def main():
    parser = argparse.ArgumentParser(
        description="Safely prepare and incrementally ingest station records."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate source data without Firestore writes.",
    )
    mode.add_argument(
        "--prepare",
        action="store_true",
        help="Read Firestore IDs and create a local manifest; no writes.",
    )
    mode.add_argument(
        "--write",
        action="store_true",
        help="Create up to the daily target of missing documents.",
    )
    args = parser.parse_args()

    if args.dry_run:
        records = load_outlets()
        print("\nDRY RUN: no Firestore writes performed.")
        print(f"Eligible records: {len(records):,}")
    elif args.prepare:
        prepare()
    elif args.write:
        write_daily()


if __name__ == "__main__":
    main()
