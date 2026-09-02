# ROSIVA — Affiliate Stores + Multi-Store Product Import

This system lets an admin register an affiliate **store / product source
once**, and the backend imports and refreshes its products automatically.
The Flutter user app never knows or cares where a product came from — every
source is normalized into the existing ROSIVA `ProductModel`.

```
USER APP        ADMIN PANEL
    │               │  Affiliate Stores  →  Add / Edit  →  Test Connection  →  Save  →  Sync
    │               ▼
    │            BACKEND (GitHub Actions worker + Render endpoint)
    │        ┌───────┼────────┐
    │       API     FEED    NETWORK          ← ProductConnector implementations
    │        └───────┼────────┘
    │          PRODUCT NORMALIZER            ← unique id, category map, commission
    │               ▼
    └────────── FIRESTORE  →  products  →  "Shop Now"  →  affiliateUrl
```

Because the Firebase project is on the **Spark (free) plan**, the backend
is **not** Cloud Functions. It reuses the two backends the repo already
has:

| Piece | Where it runs | Trigger |
|---|---|---|
| Scheduled / large / queued syncs | **GitHub Actions** (`.github/workflows/affiliate-sync.yml`) running `scripts/affiliate-sync/` with the Firebase Admin SDK | cron every 6 h + `workflow_dispatch` + drains the on‑demand queue |
| Test Connection & inline "Sync Now" | **Render** service (`server/`, already deployed for the AI assistant) | authenticated HTTPS from the Flutter Admin app |

The legacy single-store Awin sync (`scripts/awin-sync/` +
`.github/workflows/awin-sync.yml`) is **left running untouched** until the
generalized path is verified against real data.

---

## 1. How to add a new affiliate store

Admin panel → **Affiliate Stores** tab → **Add Store**:

1. **Basic information** — name, logo URL, description, website, country,
   currency.
2. **Affiliate** — network (e.g. `awin`), program id, affiliate id,
   default commission rate + type.
3. **Integration** — pick one:
   * **Product Feed** — a downloadable CSV / XML / JSON feed.
   * **REST API** — a paginated JSON API.
   * **Affiliate Network** — currently only `awin` has a built-in
     connector (Awin delivers a downloadable feed).
   * **Manual** — no automatic import; use the existing Products screen.
4. **Sync** — enable, choose frequency (6 h / 12 h / daily / weekly).
5. **Test Connection** (top-right) → fix config until it succeeds.
6. **Save**. The store id is the slug (e.g. `SHEIN` → `shein`).
7. Add any private credential as a **backend secret** (see §8), then
   **Sync Now** or wait for the schedule.

> If you only have a plain website URL, the form / test returns
> **“Product data source required.”** That is expected — a homepage is
> not a catalog. Configure a real feed / API / network.

## 2. Configure a Product Feed

Store fields (all public, no secrets):

| Field | Example |
|---|---|
| `feedUrl` | `https://feeds.example.com/rosiva/shein.csv.gz` |
| `feedFormat` | `csv` \| `xml` \| `json` |
| `feedItemPath` | (xml/json) `products.product` or `result.items` |
| `feedAuthType` | `none` \| `basic` \| `bearer` |
| `feedUsername` | (basic auth) — the **password is a backend secret** |
| `fieldMap` | `{ "externalProductId":"sku", "name":"title", "price":"price", "productUrl":"link", "affiliateUrl":"deep_link", ... }` |

`fieldMap` maps ROSIVA raw-product keys → the feed's own column /
element / property names. Supported keys: `externalProductId`, `name`,
`description`, `brand`, `categoryName`, `price`, `oldPrice`, `salePrice`,
`currency`, `imageUrl`, `productUrl`, `affiliateUrl`, `availability`,
`rating`, `reviewCount`, `commissionRate`.

Gzip is auto-detected from the file's magic bytes. CSV is streamed
(never fully buffered).

## 3. Configure a REST API integration

| Field | Example |
|---|---|
| `apiBaseUrl` | `https://api.partner.com/v3` |
| `apiProductsPath` | `/products` |
| `apiAuthType` | `none` \| `bearer` \| `header` \| `query` |
| `apiAuthHeaderName` | (header) `X-Api-Key` |
| `apiAuthQueryParam` | (query) `api_key` |
| `publicApiId` | a **non-secret** id the API needs in the URL |
| `apiItemsPath` | `data` — the array of items in the response |
| `apiPagination` | `{ "style":"page"\|"offset"\|"cursor", "pageParam":"page", "sizeParam":"limit", "pageSize":100, "cursorPath":"meta.next_cursor", "totalPath":"meta.total" }` |
| `fieldMap` | same shape as the feed connector |

The **API key/token is a backend secret** (`AFFILIATE_<SLUG>_API_KEY`).
If required config is missing the connector fails fast with a safe
"invalid config" error — it never invents endpoints or auth behaviour.

## 4. Configure an Affiliate Network integration

Set `affiliateNetwork: "awin"`, `integrationType: "affiliate_network"`,
`programId`, `affiliateId`. The private Awin feed URL (it embeds the
publisher id + API token) is the secret `AWIN_FEED_URL` (global) or
`AFFILIATE_<SLUG>_FEED_URL` (per store). The Awin connector optionally
runs ROSIVA's existing women's-beauty classifier so a fully-migrated
Awin store produces the same documents the legacy sync writes today.

Other networks (CJ, Rakuten, Impact, …) need a connector added under
`scripts/affiliate-sync/connectors/` before they can be used — the
architecture allows it without touching the Flutter product UI.

## 5. How automatic sync works

`.github/workflows/affiliate-sync.yml` (cron `15 */6 * * *`):

1. Drains `affiliateSyncJobs` (queued by "Sync Now").
2. Syncs every store that is **due**: `status == active`,
   `syncEnabled != false`, and `nextSyncAt` null or in the past.
   After each run `nextSyncAt` is set from the store's `syncFrequency`,
   so a fixed 6-hourly cron naturally spaces out 12 h / daily / weekly
   stores too.

Per store, `syncAffiliateStore(storeId)` (`scripts/affiliate-sync/syncEngine.mjs`):

load config → verify active → resolve secrets from the **environment**
→ pick connector → paged fetch → normalize + validate → **batched
upsert** (`merge:true`, so admin edits survive) → mark products the
source stopped returning `isActive:false` (**never hard-deleted**) →
update `productCount` / `lastSyncAt` / `nextSyncAt` / `syncStatus` →
write an `affiliateSyncLogs` row → log errors **redacted**.

Reliability: per-batch retry with exponential backoff, an overall time
budget, idempotent doc ids, in-feed duplicate suppression.

## 6. How to run a manual sync

* **Admin → Affiliate Stores → ⋯ → Sync Now.** Small sources (REST /
  mock) run inline and return `New / Updated / Unavailable / Errors`.
  Feed sources are **queued** (`affiliateSyncJobs`) and drained by the
  next worker run — the UI is never blocked on a large feed.
* **GitHub → Actions → “Affiliate product sync” → Run workflow**,
  optionally with a single store id.
* CLI: `cd scripts/affiliate-sync && node runScheduledSync.mjs --store <id>`.

## 7. How product normalization works

`scripts/affiliate-sync/lib/normalizer.mjs`:

* **Unique id** = `storeId + ":" + externalProductId`
  (e.g. `shein:SKU_987654`) — **never** the product name, so two stores
  selling a same-named product never collide.
* **Required fields**: id, name, and at least one of `productUrl` /
  `affiliateUrl`. A valid (or absent) price. Failures are counted and
  sampled in the sync log, they don't abort the run.
* **Category** → one of `skincare` / `makeup` / `perfume` via the
  admin-configurable `categoryMappings` collection (store-specific rows
  beat global), then the built-in keyword normalizer (mirrors the Dart
  `normalizeCategory`). Unmapped → `rosivaCategory: null`.
* **Commission** priority: product-specific rate → store default →
  system default. Stored as **configured metadata** (`commissionRate` /
  `commissionSource`), never as confirmed earnings.
* **`affiliateUrl`** is the click-out link. It is also written into
  `storeUrl` so the existing "Shop Now" path works with zero UI change.
* Imported products are written with `isRosivaProduct: false` (excluded
  from the AI catalog, like admin-authored products) **unless** the
  connector did proper classification (Awin).

## 8. Where secrets are stored

**Never** in Firestore, **never** in the Flutter app, **never** in the
`affiliateStores` document.

| Secret | Home |
|---|---|
| Firebase service account | GitHub secret `FIREBASE_SERVICE_ACCOUNT_JSON`; Render env `FIREBASE_SERVICE_ACCOUNT_JSON` |
| Awin feed URL (has token) | GitHub secret `AWIN_FEED_URL` or `AFFILIATE_<SLUG>_FEED_URL` |
| Feed password / token | `AFFILIATE_<SLUG>_FEED_PASSWORD` / `_FEED_TOKEN` (or global `FEED_PASSWORD` / `FEED_TOKEN`) |
| REST API key / token | `AFFILIATE_<SLUG>_API_KEY` / `_API_TOKEN` (or global `API_KEY` / `API_TOKEN`) |

`<SLUG>` = the store slug, uppercased, non-alphanumerics → `_`
(`shein` → `SHEIN`, `my-store` → `MY_STORE`).

## 9. How to add a new connector

1. Create `scripts/affiliate-sync/connectors/MyConnector.mjs` extending
   `ProductConnector`. Implement `testConnection()`,
   `fetchProductPages()`, `normalizeProduct(record)` and (optionally)
   `buildAffiliateUrl(record)`.
2. Wire it into `getConnector()` in `connectors/index.mjs`.
3. `node scripts/sync-vendor.mjs` to copy it into `server/src/affiliate/`.
4. Add tests under `scripts/affiliate-sync/test/`.
5. The Flutter product UI and models do **not** change.

## 10. How to deploy the backend

* **GitHub Actions worker** — nothing to deploy; it's a workflow.
  Set the repo secrets (§8, §13). First run:
  `Actions → Affiliate product sync → Run workflow`.
* **Render endpoint** — `server/` already auto-deploys from `main`
  (`server/render.yaml`). The new routes ship with it. Ensure
  `FIREBASE_SERVICE_ACCOUNT_JSON` is set (it already is for the AI
  backend) and add the affiliate secrets you need. `csv-parse` +
  `fast-xml-parser` were added to `server/package.json` — a redeploy
  runs `npm ci`.
* Before committing, run `node scripts/sync-vendor.mjs` so
  `server/src/affiliate/` matches `scripts/affiliate-sync/`. CI checks
  this (`node scripts/sync-vendor.mjs --check`).

## 11. Required Firebase configuration

* Firestore in the existing project (`rosiva-24fa4`).
* Deploy rules + indexes:
  `firebase deploy --only firestore:rules,firestore:indexes`.
* No Blaze plan required.

## 12. Required Firestore indexes

Added to `firestore.indexes.json`:

* `affiliateSyncLogs` — `storeId ASC, startedAt DESC` (store sync history).

Single-field queries used by the engine (`products.storeId`,
`affiliateSyncJobs.status`, `affiliateStores`) are covered by automatic
single-field indexes.

## 13. Required environment variables / secrets

| Name | Used by | Required |
|---|---|---|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | GH Actions worker, Render endpoint | **yes** |
| `AWIN_FEED_URL` / `AFFILIATE_<SLUG>_FEED_URL` | Awin / feed stores | per store |
| `AFFILIATE_<SLUG>_FEED_PASSWORD` / `_FEED_TOKEN` | authed feeds | per store |
| `AFFILIATE_<SLUG>_API_KEY` / `_API_TOKEN` | REST stores | per store |
| `AI_BACKEND_URL` (Flutter `--dart-define`) | Admin app → Test Connection / inline Sync Now | for those two features |

## 14. Known limitations

* **Non-Awin affiliate products are excluded from the AI catalog and the
  women-only shopper category feed** (`isRosivaProduct: false`) until a
  classifier pass or an admin curates them. They are fully visible and
  manageable in **Admin → Products** (filter by store). Awin imports are
  classified and behave exactly like today's catalog.
* **Test Connection & inline Sync Now need `AI_BACKEND_URL`** set at
  build time. Without it the Admin UI shows a clear notice; scheduled
  and `workflow_dispatch` syncs still work.
* **Logo upload** is a URL field — `firebase_storage` is not a
  dependency. Add it later if in-app upload is wanted.
* **REST / non-Awin network connectors are configuration scaffolding.**
  They work against any API that fits the declared pagination/field-map
  shape, but each real partner's exact endpoint, pagination and key must
  be supplied. No third-party API behaviour is assumed or invented.
* **Large inline syncs are bounded** (60 s on the endpoint). Anything
  bigger must go through the queue + GitHub Actions worker.
* **The vendored copy** `server/src/affiliate/` is generated. Edit
  `scripts/affiliate-sync/` and re-run `node scripts/sync-vendor.mjs`.
* Firestore has no cross-field `OR`, so the shopper category query still
  applies its single hard `isRosivaProduct == true` filter server-side.
