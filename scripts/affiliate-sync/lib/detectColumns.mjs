/**
 * detectColumns — given a small sample of RAW source records (feed rows
 * or API items), return the list of column / field names an admin can
 * map in the Admin "column mapping" UI.
 *
 * - Union of top-level keys across the sample, first-seen order kept.
 * - For nested objects (XML / JSON feeds) it also emits one level of
 *   dotted paths ("price.amount") so nested values are pickable; arrays
 *   and deeper nesting are left for the admin to type by hand.
 * - Bounded so a pathological record can't produce a huge list.
 */

const MAX_COLUMNS = 60;

export function detectColumns(records) {
  if (!Array.isArray(records)) return [];
  const seen = new Set();
  const out = [];

  const add = (name) => {
    if (typeof name !== "string" || !name || seen.has(name)) return;
    if (out.length >= MAX_COLUMNS) return;
    seen.add(name);
    out.push(name);
  };

  for (const rec of records) {
    if (!rec || typeof rec !== "object" || Array.isArray(rec)) continue;
    for (const [key, value] of Object.entries(rec)) {
      add(key);
      if (value && typeof value === "object" && !Array.isArray(value)) {
        for (const childKey of Object.keys(value)) add(`${key}.${childKey}`);
      }
    }
    if (out.length >= MAX_COLUMNS) break;
  }

  return out;
}
