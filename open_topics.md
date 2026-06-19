# Open Topics

This document lists outstanding items, design trade-offs, and issues to be resolved in future development phases:

## 1. Sequential API Bottleneck during SMS/Gmail Syncs
* **Description**: The background synchronization flow executes Gemini API parser requests sequentially for each newly detected message or email. While this prevents API rate limits and maintains consistency, it creates a latency bottleneck during bulk synchronization of historical messages.
* **Future Solution**: Introduce concurrent parsing with rate-limiting queues/throttling.

## 2. Fragile JSON Decoding & Restoration during Cloud Sync
* **Description**: Restoring keys, API keys, and app preferences from the encrypted Google Drive backup casts types directly from JSON without verifying schema compatibility or verifying field types.
* **Future Solution**: Introduce robust schema validation/deserialization layers for restoration.
