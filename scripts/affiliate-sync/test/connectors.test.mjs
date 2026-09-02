import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";

import { ProductFeedConnector } from "../connectors/ProductFeedConnector.mjs";
import { RestApiProductConnector } from "../connectors/RestApiProductConnector.mjs";
import { ManualConnector } from "../connectors/ManualConnector.mjs";
import { getConnector } from "../connectors/index.mjs";

function serve(handler) {
  return new Promise((resolve) => {
    const srv = http.createServer(handler);
    srv.listen(0, "127.0.0.1", () => {
      const { port } = srv.address();
      resolve({ url: `http://127.0.0.1:${port}`, close: () => srv.close() });
    });
  });
}

test("ProductFeedConnector: parses a CSV feed with a field map", async () => {
  const csv =
    "sku,title,brand,cat,price,rrp,link,deep,stock\n" +
    "A1,Vitamin C Serum,Lumea,Serums,19.99,29.99,https://s/p/A1,https://go/A1,in stock\n" +
    "A2,Rose Perfume,Maison,Fragrance,40,40,https://s/p/A2,https://go/A2,out of stock\n";
  const srv = await serve((_req, res) => {
    res.setHeader("content-type", "text/csv");
    res.end(csv);
  });
  try {
    const store = {
      id: "s1",
      slug: "s1",
      currency: "USD",
      integrationType: "product_feed",
      feedUrl: `${srv.url}/feed.csv`,
      feedFormat: "csv",
      fieldMap: {
        externalProductId: "sku",
        name: "title",
        brand: "brand",
        categoryName: "cat",
        price: "price",
        oldPrice: "rrp",
        productUrl: "link",
        affiliateUrl: "deep",
        availability: "stock",
      },
    };
    const conn = new ProductFeedConnector(store, {});
    const pages = [];
    for await (const page of conn.fetchProductPages()) pages.push(...page);
    assert.equal(pages.length, 2);
    assert.equal(pages[0].externalProductId, "A1");
    assert.equal(pages[0].name, "Vitamin C Serum");
    assert.equal(pages[0].price, "19.99");
    assert.equal(pages[0].affiliateUrl, "https://go/A1");
    assert.equal(pages[1].availability, "out of stock");

    const testRes = await conn.testConnection();
    assert.equal(testRes.ok, true);
    assert.ok(testRes.sample.length > 0 && testRes.sample.length <= 5);
    // sample rows are RAW feed records (not pre-normalized) so the
    // orchestrator normalizes exactly once.
    assert.equal(testRes.sample[0].sku, "A1");
    assert.equal(testRes.sample[0].title, "Vitamin C Serum");
    // detectedColumns exposes the real CSV headers for the mapping UI.
    assert.deepEqual(testRes.detectedColumns, [
      "sku", "title", "brand", "cat", "price", "rrp", "link", "deep", "stock",
    ]);
  } finally {
    srv.close();
  }
});

test("ProductFeedConnector: JSON feed with feedItemPath", async () => {
  const body = JSON.stringify({
    meta: { total: 2 },
    result: {
      items: [
        { id: "J1", name: "Cleanser", price: 10, url: "https://s/J1", deep_link: "https://go/J1" },
        { id: "J2", name: "Toner", price: 12, url: "https://s/J2", deep_link: "https://go/J2" },
      ],
    },
  });
  const srv = await serve((_req, res) => {
    res.setHeader("content-type", "application/json");
    res.end(body);
  });
  try {
    const store = {
      id: "sj",
      slug: "sj",
      currency: "USD",
      integrationType: "product_feed",
      feedUrl: `${srv.url}/feed.json`,
      feedFormat: "json",
      feedItemPath: "result.items",
      fieldMap: { externalProductId: "id", name: "name", price: "price", productUrl: "url", affiliateUrl: "deep_link" },
    };
    const conn = new ProductFeedConnector(store, {});
    const all = [];
    for await (const page of conn.fetchProductPages()) all.push(...page);
    assert.equal(all.length, 2);
    assert.equal(all[0].externalProductId, "J1");
    assert.equal(all[1].name, "Toner");
  } finally {
    srv.close();
  }
});

test("RestApiProductConnector: paginates page-style until a short page", async () => {
  const all = [
    { id: "R1", title: "A", price: 1, link: "https://s/R1" },
    { id: "R2", title: "B", price: 2, link: "https://s/R2" },
    { id: "R3", title: "C", price: 3, link: "https://s/R3" },
  ];
  const srv = await serve((req, res) => {
    const u = new URL(req.url, "http://x");
    const page = Number(u.searchParams.get("page") || "1");
    const size = 2;
    const slice = all.slice((page - 1) * size, page * size);
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ data: slice, meta: { total: all.length } }));
  });
  try {
    const store = {
      id: "api1",
      slug: "api1",
      currency: "USD",
      integrationType: "rest_api",
      apiBaseUrl: srv.url,
      apiProductsPath: "/products",
      apiAuthType: "none",
      apiItemsPath: "data",
      apiPagination: { style: "page", pageParam: "page", sizeParam: "limit", pageSize: 2, totalPath: "meta.total" },
      fieldMap: { externalProductId: "id", name: "title", price: "price", productUrl: "link" },
    };
    const conn = new RestApiProductConnector(store, {});
    const got = [];
    for await (const page of conn.fetchProductPages()) got.push(...page);
    assert.equal(got.length, 3);
    assert.deepEqual(got.map((p) => p.externalProductId), ["R1", "R2", "R3"]);

    const t = await conn.testConnection();
    assert.equal(t.ok, true);
    assert.equal(t.productsDetected, 3);
  } finally {
    srv.close();
  }
});

test("RestApiProductConnector: missing config fails safely (no invented behaviour)", async () => {
  const conn = new RestApiProductConnector({ id: "x", slug: "x", integrationType: "rest_api" }, {});
  const t = await conn.testConnection();
  assert.equal(t.ok, false);
  assert.equal(t.error.code, "invalid_config");
});

test("ManualConnector: test returns data-source-required, fetch yields nothing", async () => {
  const conn = new ManualConnector({ id: "m", slug: "m", integrationType: "manual" }, {});
  const t = await conn.testConnection();
  assert.equal(t.ok, false);
  assert.equal(t.error.code, "data_source_required");
  const pages = [];
  for await (const p of conn.fetchProductPages()) pages.push(p);
  assert.equal(pages.length, 0);
});

test("getConnector: routes integration types + rejects unknown network", () => {
  assert.equal(
    getConnector({ id: "a", integrationType: "manual" }).constructor.name,
    "ManualConnector",
  );
  assert.equal(
    getConnector({ id: "b", integrationType: "rest_api" }).constructor.name,
    "RestApiProductConnector",
  );
  assert.equal(
    getConnector({ id: "c", integrationType: "product_feed", affiliateNetwork: "awin" }).constructor.name,
    "AwinProductFeedConnector",
  );
  assert.equal(
    getConnector({ id: "d", integrationType: "product_feed" }).constructor.name,
    "ProductFeedConnector",
  );
  assert.throws(
    () => getConnector({ id: "e", integrationType: "affiliate_network", affiliateNetwork: "cj" }),
    (err) => err.code === "not_supported",
  );
});

test("AwinProductFeedConnector: maps Awin columns + classifier passthrough", async () => {
  const csv =
    "aw_product_id,product_name,brand_name,category_name,search_price,currency,aw_deep_link,merchant_deep_link,in_stock,description\n" +
    "AW1,Hydra Serum,Lumea,Beauty > Skincare,15.00,GBP,https://awin/AW1,https://m/AW1,1,A face serum with hyaluronic acid\n" +
    "AW2,Cordless Drill,DeWalt,Tools,80.00,GBP,https://awin/AW2,https://m/AW2,1,18V power drill\n";
  const srv = await serve((_req, res) => {
    res.setHeader("content-type", "text/csv");
    res.end(csv);
  });
  try {
    const { AwinProductFeedConnector } = await import("../connectors/AwinProductFeedConnector.mjs");
    const store = { id: "awstore", slug: "awstore", currency: "GBP", integrationType: "affiliate_network", affiliateNetwork: "awin" };
    const conn = new AwinProductFeedConnector(store, { AWIN_FEED_URL: `${srv.url}/feed.csv` });
    const got = [];
    for await (const page of conn.fetchProductPages()) got.push(...page);
    // The drill must be dropped by the classifier; the serum kept.
    assert.equal(got.length, 1);
    assert.equal(got[0].externalProductId, "AW1");
    assert.equal(got[0].price, 15);
    assert.equal(got[0].affiliateUrl, "https://awin/AW1");
    assert.ok(got[0].rosivaClassification);
    assert.equal(got[0].rosivaClassification.rosivaCategory, "skincare");
  } finally {
    srv.close();
  }
});
