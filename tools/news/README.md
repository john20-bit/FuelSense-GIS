# FuelSense GIS News Ingestion

FuelSense GIS uses GitHub Actions as the scheduler for news ingestion instead of Firebase Cloud Functions.

## Sources

- ET Auto: fuel news
- Autocar India: vehicle news

## Flow

RSS feeds -> GitHub Actions -> ingest_news.py -> Firestore /news -> FuelSense GIS mobile app

## Schedule

The GitHub Actions workflow runs every 6 hours and can also be triggered manually.

## Firestore

Articles are stored under /news/{articleId} with title, summary, URL, image, source, category, publication time, and ingestion metadata.

## Retention

The ingestion process keeps the latest 500 articles for each category.

## Authentication

GitHub Actions uses GitHub OIDC and Google Workload Identity Federation. No Firebase service-account JSON key is stored in GitHub.

Repository: john20-bit/FuelSense-GIS

Service account: fuelsense-news-ingester@fuelsense-ai-b3e97.iam.gserviceaccount.com
