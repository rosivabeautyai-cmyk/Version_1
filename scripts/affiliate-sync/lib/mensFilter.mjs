/**
 * Lightweight men's-product exclusion for the generalized sync.
 *
 * Beauty feeds routinely mix men's and women's products. ROSIVA's
 * shopper catalog is women-only, so a keyword match on the product
 * NAME or CATEGORY name marks the product excluded
 * (`isRosivaProduct: false`, `gender: 'men'`, `exclusionReason` set) —
 * it is still written to Firestore and visible under the admin
 * "Ineligible" filter, never silently dropped.
 *
 * Word boundaries matter: a naive `includes('men')` would also match
 * "wo​men", "supplement", "regimen", "menu". Every pattern below is
 * anchored with \b so "women's mascara" is NOT excluded.
 *
 * Keyword list approved by the product owner:
 *   men, men's, mens, for him, homme, pour homme, beard, shaving,
 *   aftershave, barber
 */

const MENS_PATTERNS = [
  { re: /\bmen'?s?\b/i, label: "men" }, // men / mens / men's
  { re: /\bfor him\b/i, label: "for him" },
  { re: /\bpour homme\b/i, label: "pour homme" },
  { re: /\bhomme\b/i, label: "homme" },
  { re: /\bbeard\b/i, label: "beard" },
  { re: /\bshaving\b/i, label: "shaving" },
  { re: /\baftershave\b/i, label: "aftershave" },
  { re: /\bbarber\b/i, label: "barber" },
];

/**
 * @param {{ name?: string, categoryName?: string }} product
 * @return {{ excluded: boolean, matched: string|null }}
 */
export function isMensProduct({ name, categoryName } = {}) {
  const haystack = [name, categoryName].filter(Boolean).join(" ");
  if (!haystack) return { excluded: false, matched: null };
  for (const { re, label } of MENS_PATTERNS) {
    if (re.test(haystack)) return { excluded: true, matched: label };
  }
  return { excluded: false, matched: null };
}
