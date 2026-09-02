/**
 * ManualConnector — the fallback for stores with no supported automatic
 * data source. It performs NO import. Products for a manual store are
 * added through the existing Admin product-management flow
 * (AdminProductCreateScreen / AdminRepository.createProduct), which is
 * untouched by this system.
 *
 * `testConnection()` returns a clear, safe "data source required"
 * result so the Admin UI can prompt the operator to configure a feed /
 * API / network instead of a bare website URL.
 */

import { ProductConnector } from "./ProductConnector.mjs";
import { ERROR_CODES } from "../lib/errors.mjs";

export class ManualConnector extends ProductConnector {
  async testConnection() {
    return {
      ok: false,
      productsDetected: null,
      sample: [],
      error: {
        code: ERROR_CODES.DATA_SOURCE_REQUIRED,
        userMessage:
          "Product data source required. This store is set to Manual, so there is nothing to test. " +
          "Add products from the Products screen, or switch the integration to a product feed, REST API, or affiliate network.",
        technical: "manual integration — no automatic source",
      },
    };
  }

  // eslint-disable-next-line require-yield
  async *fetchProductPages() {
    return; // nothing to import
  }
}
