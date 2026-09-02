/**
 * Connector factory. Given a store document + resolved secrets, returns
 * the right ProductConnector subclass. Adding a new KIND of source =
 * add a branch here + a subclass; the Flutter product UI never changes.
 */

import { INTEGRATION_TYPES } from "../lib/constants.mjs";
import { SyncError, ERROR_CODES } from "../lib/errors.mjs";
import { ProductConnector } from "./ProductConnector.mjs";
import { MockConnector } from "./MockConnector.mjs";
import { ProductFeedConnector } from "./ProductFeedConnector.mjs";
import { AwinProductFeedConnector } from "./AwinProductFeedConnector.mjs";
import { RestApiProductConnector } from "./RestApiProductConnector.mjs";
import { ManualConnector } from "./ManualConnector.mjs";

export {
  ProductConnector,
  MockConnector,
  ProductFeedConnector,
  AwinProductFeedConnector,
  RestApiProductConnector,
  ManualConnector,
};

/**
 * @param {object} store    affiliateStores document (must include `id`)
 * @param {object} [secrets] private values resolved from the backend env
 * @param {object} [opts]    forwarded to the connector (pageSize, timeouts, test seams)
 * @return {ProductConnector}
 */
export function getConnector(store, secrets = {}, opts = {}) {
  if (!store || !store.id) {
    throw new SyncError(ERROR_CODES.INVALID_CONFIG, "getConnector requires a store with an id");
  }

  // Explicit dev/testing override.
  if (store.connectorOverride === "mock" || store.integrationType === "mock") {
    return new MockConnector(store, secrets, opts);
  }

  const type = store.integrationType;
  const network = (store.affiliateNetwork || "").toLowerCase();

  switch (type) {
    case INTEGRATION_TYPES.MANUAL:
      return new ManualConnector(store, secrets, opts);

    case INTEGRATION_TYPES.REST_API:
      return new RestApiProductConnector(store, secrets, opts);

    case INTEGRATION_TYPES.AFFILIATE_NETWORK:
      if (network === "awin") return new AwinProductFeedConnector(store, secrets, opts);
      // Other networks: no connector implemented without their docs/creds.
      throw new SyncError(
        ERROR_CODES.NOT_SUPPORTED,
        `affiliate network "${network || "unknown"}" has no connector yet — add one under connectors/`,
      );

    case INTEGRATION_TYPES.PRODUCT_FEED:
      if (network === "awin") return new AwinProductFeedConnector(store, secrets, opts);
      return new ProductFeedConnector(store, secrets, opts);

    default:
      throw new SyncError(
        ERROR_CODES.INVALID_CONFIG,
        `unknown integrationType "${type || "(none)"}"`,
      );
  }
}
