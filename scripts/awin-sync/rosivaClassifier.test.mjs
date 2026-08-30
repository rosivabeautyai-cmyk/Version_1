/**
 * Test cases for rosivaClassifier.mjs's women's-only, accuracy-first
 * eligibility policy. Not wired into a test runner (this project has
 * none for the Node scripts) — run directly with
 * `node rosivaClassifier.test.mjs`. Exits non-zero if any case fails,
 * so it's also CI-usable as-is.
 */
import {classifyProduct} from "./rosivaClassifier.mjs";

const cases = [
  // ===================================================================
  // Must PASS
  // ===================================================================
  ["women's face moisturizer -> skincare", {name: "Women's Face Moisturizer", merchantCategory: "Skincare"}, true, "skincare"],
  ["women's face serum -> skincare", {name: "Women's Face Serum", merchantCategory: "Skincare"}, true, "skincare"],
  ["women's facial cleanser -> skincare", {name: "Women's Facial Cleanser", merchantCategory: "Skincare"}, true, "skincare"],
  ["women's mascara -> makeup", {name: "Women's Mascara", merchantCategory: "Makeup"}, true, "makeup"],
  ["women's lipstick -> makeup", {name: "Women's Lipstick", merchantCategory: "Makeup"}, true, "makeup"],
  ["women's foundation -> makeup", {name: "Women's Foundation", merchantCategory: "Makeup"}, true, "makeup"],
  ["women's perfume -> perfume", {name: "Women's Perfume 100ml", merchantCategory: "Fragrance"}, true, "perfume"],
  ["women's eau de parfum -> perfume", {name: "Women's Eau de Parfum", merchantCategory: "Fragrance"}, true, "perfume"],
  ["women's eau de toilette -> perfume", {name: "Women's Eau de Toilette", merchantCategory: "Fragrance"}, true, "perfume"],

  // ===================================================================
  // Must FAIL — general
  // ===================================================================
  ["men's perfume", {name: "Men's Eau de Toilette 100ml", merchantCategory: "Fragrance"}, false, "perfume"],
  ["unisex perfume", {name: "Unisex Eau de Parfum", merchantCategory: "Fragrance"}, false, "perfume"],
  ["generic unknown-gender perfume, no women's evidence", {name: "Chanel No 5 Eau de Parfum", merchantCategory: "Fragrance"}, false, "perfume"],
  ["hair serum", {name: "Anti-Frizz Hair Serum", merchantCategory: "Hair Care"}, false, null],
  ["hair mask", {name: "Deep Repair Hair Mask", merchantCategory: "Hair Care"}, false, null],
  ["shampoo", {name: "Moisture Repair Shampoo", merchantCategory: "Hair Care"}, false, null],
  ["conditioner", {name: "Deep Conditioner 250ml", merchantCategory: "Hair Care"}, false, null],
  ["razor", {name: "Gillette Venus Razor", merchantCategory: "Shaving"}, false, null],
  ["razor blades", {name: "Gillette Venus Razor Blades 4 Pack", merchantCategory: "Shaving"}, false, null],
  ["shower gel", {name: "Fruity Rhythm Shower Gel", merchantCategory: "Bath & Fragrance"}, false, null],
  ["body wash", {name: "Vanilla Body Wash", merchantCategory: "Bath & Body"}, false, null],
  ["deodorant", {name: "48H Protection Deodorant Body Spray", merchantCategory: "Fragrance"}, false, null],
  ["air freshener", {name: "Lavender Air Freshener", merchantCategory: "Home Fragrance"}, false, null],
  ["room fragrance", {name: "Linen Room Fragrance Diffuser", merchantCategory: "Home Fragrance"}, false, null],
  ["makeup mirror", {name: "Luminous Makeup Mirror", merchantCategory: "Beauty Accessories"}, false, null],
  ["tweezers", {name: "Precision Tweezers", merchantCategory: "Beauty Tools"}, false, null],
  ["eyelash curler", {name: "Eyelash Curler", merchantCategory: "Beauty Tools"}, false, null],
  ["nail stickers", {name: "Nail Art Stickers Pack", merchantCategory: "Nail Art"}, false, null],
  ["beauty device", {name: "Facial Cleansing Beauty Device", merchantCategory: "Beauty Tech"}, false, null],
  ["cosmetic bag", {name: "Pink Cosmetic Bag", merchantCategory: "Accessories"}, false, null],
  ["household cleaner", {name: "Multi-Surface Cleaner Spray", merchantCategory: "Household"}, false, null],
  ["electronics", {name: "Bluetooth Speaker", merchantCategory: "Electronics"}, false, null],

  // ===================================================================
  // Must FAIL — this round's new findings
  // ===================================================================
  ["bicycle products", {name: "Rawlink Venice Bicycle Bar Set", merchantCategory: "Health & Beauty"}, false, null],
  ["cotton balls", {name: "Athena Beauté Cotton Balls - 200 pcs", brand: "Athena Beauté", description: "100% cosmetic cotton balls", merchantCategory: "Health & Beauty"}, false, null],
  ["sanitary products", {name: "Always Dailies Long - 46 pcs", brand: "Always", merchantCategory: "Feminine Hygiene"}, false, null],
  ["hand cream", {name: "Rich Hand Cream 75ml", merchantCategory: "Skincare"}, false, null],
  ["body lotion", {name: "Nourishing Body Lotion 400ml", merchantCategory: "Skincare"}, false, null],
  ["body cream", {name: "Whipped Body Cream 200ml", merchantCategory: "Skincare"}, false, null],
  ["foot cream", {name: "Intensive Foot Cream 100ml", merchantCategory: "Skincare"}, false, null],

  // ===================================================================
  // Regression tests — previously observed false positives (must stay excluded)
  // ===================================================================
  ["Gillette Venus Spa Breeze", {name: "Gillette Venus Spa Breeze Razor", brand: "Gillette", merchantCategory: "Shaving"}, false, null],
  ["Gillette Venus razor blades", {name: "Gillette Venus Razor Blades Refill", brand: "Gillette", merchantCategory: "Shaving"}, false, null],
  ["SOKO Nail Stickers", {name: "SOKO Nail Stickers Metallic", brand: "SOKO", merchantCategory: "Nail Art"}, false, null],
  ["Babyliss Luminous Makeup Mirror", {name: "Babyliss Luminous Makeup Mirror", brand: "Babyliss", merchantCategory: "Beauty Accessories"}, false, null],
  ["Adidas Fruity Rhythm Shower Gel", {name: "Adidas Fruity Rhythm Shower Gel", brand: "Adidas", merchantCategory: "Fragrance & Bath"}, false, null],
  ["Always Dailies (regression)", {name: "Always Dailies Pantyliners", brand: "Always", description: "With a light fragrance", merchantCategory: "Feminine Hygiene"}, false, null],
  ["Vacu Vin Wing corkscrew", {name: "Vacu Vin Wing Corkscrew", brand: "Vacu Vin", merchantCategory: "Kitchen"}, false, null],
  ["Rawlink Venice bicycle bar set (regression, exact name)", {name: "Rawlink Venice bicycle bar set - 2 pcs", brand: "Rawlink", merchantCategory: "Health & Beauty"}, false, null],
  ["Athena Beauté Cotton balls - 200 pcs (regression, exact name)", {name: "Athena Beauté Cotton balls - 200 pcs", brand: "Athena Beauté", merchantCategory: "Health & Beauty"}, false, null],
  ["Athena Beauté Cotton balls - 100 pcs (regression, exact name)", {name: "Athena Beauté Cotton balls - 100 pcs", brand: "Athena Beauté", merchantCategory: "Health & Beauty"}, false, null],
  ["Elizabeth Arden Eight Hour Cream Hand Cream", {name: "Elizabeth Arden Eight Hour Cream Hand Cream - 30ML", brand: "Elizabeth Arden", merchantCategory: "Skincare"}, false, null],
  ["Neutrogena Light Hand Cream", {name: "Neutrogena Light Hand Cream - 75ml", brand: "Neutrogena", merchantCategory: "Skincare"}, false, null],
  ["Neutrogena Perfumed Hand Cream", {name: "Neutrogena Perfumed Hand Cream - 50ml", brand: "Neutrogena", description: "With a light fragrance", merchantCategory: "Skincare"}, false, null],
  ["MAM Soother", {name: "MAM Soother 0-6 Months", brand: "MAM", description: "Fragrance-free, BPA-free silicone soother", merchantCategory: "Baby"}, false, null],

  // ===================================================================
  // Genuine beauty products that must qualify via conservative women
  // inference — real gender=unknown products from the catalog with NO
  // explicit gender wording, but strong product-identity evidence
  // (makeup and mainline facial skincare default to women absent
  // contrary evidence; perfume deliberately does not — tested above).
  // ===================================================================
  ["W7 Eyelust Mascara Black (no gender wording)", {name: "W7 Eyelust Mascara Black", brand: "W7", merchantCategory: "Mascara"}, true, "makeup"],
  ["W7 Very Vegan Liquid Eyeliner (no gender wording)", {name: "W7 Very Vegan Liquid Eyeliner", brand: "W7", merchantCategory: "Makeup"}, true, "makeup"],
  [
    "W7 Very Vegan Summer Sands Eyeshadow Palette (regression: must NOT be denied just because it includes a mirror)",
    {
      name: "W7 Very Vegan Summer Sands Eyeshadow Palette",
      brand: "W7",
      description: "9-shade eyeshadow palette with a built-in mirror for easy application",
      merchantCategory: "Makeup",
    },
    true,
    "makeup",
  ],
  ["bareMinerals Eyeshadow (no gender wording)", {name: "bareMinerals Eyeshadow", brand: "bareMinerals", merchantCategory: "Makeup"}, true, "makeup"],
  ["bareMinerals Complexion Rescue BB Cream (no gender wording)", {name: "bareMinerals Complexion Rescue BB Cream", brand: "bareMinerals", merchantCategory: "Makeup"}, true, "makeup"],
  [
    "Clinique iD Hydrating Jelly Face Gel - 115ML (regression: fragrance-free description must NOT deny it)",
    {
      name: "Clinique iD Hydrating Jelly Face Gel - 115ML",
      brand: "Clinique",
      description: "A fragrance-free jelly gel base that hydrates and preps skin.",
      merchantCategory: "Skincare",
    },
    true,
    "skincare",
  ],
  ["genuine women's Eau de Parfum", {name: "Daisy Eau de Parfum for Women", brand: "Marc Jacobs", merchantCategory: "Fragrance"}, true, "perfume"],
  ["genuine women's Eau de Toilette", {name: "J'adore Eau de Toilette for Her", brand: "Dior", merchantCategory: "Fragrance"}, true, "perfume"],

  // ===================================================================
  // This round's exact regression cases
  // ===================================================================
  [
    "Maybelline Baby Lips Moisturising Lipgloss - Fab & Fuchsia (regression: 'Lipgloss' one word)",
    {name: "Maybelline Baby Lips Moisturising Lipgloss - Fab & Fuchsia", brand: "Maybelline", merchantCategory: "Makeup"},
    true,
    "makeup",
  ],
  ["W7 Very Vegan Liquid Eyeliner - Very Black (exact name)", {name: "W7 Very Vegan Liquid Eyeliner - Very Black", brand: "W7", merchantCategory: "Makeup"}, true, "makeup"],
  ["London Pride Pro Eyebrow Brush", {name: "London Pride Pro Eyebrow Brush", brand: "London Pride", merchantCategory: "Makeup"}, true, "makeup"],
  ["London Pride Pro Blusher Brush", {name: "London Pride Pro Blusher Brush", brand: "London Pride", merchantCategory: "Makeup"}, true, "makeup"],
  ["e.l.f. Foundation Brush", {name: "e.l.f. Foundation Brush", brand: "e.l.f.", merchantCategory: "Makeup"}, true, "makeup"],
  ["Hugo Boss Orange Woman Eau de Toilette", {name: "Hugo Boss Orange Woman Eau de Toilette", brand: "Hugo Boss", merchantCategory: "Fragrance"}, true, "perfume"],
  // The bare product name has no gender word ("FlowerBomb" is a real
  // women's fragrance line, but that alone isn't explicit evidence
  // under this policy) — realistic retailer copy for it does include
  // explicit women's wording, which is what actually qualifies it.
  ["Viktor & Rolf FlowerBomb Eau de Parfum", {name: "Viktor & Rolf FlowerBomb Eau de Parfum", brand: "Viktor & Rolf", description: "An iconic floral fragrance for her", merchantCategory: "Fragrance"}, true, "perfume"],
  ["Makeup brush set (compound phrase) -> PASS", {name: "Professional Makeup Brush Set 12pc", merchantCategory: "Makeup"}, true, "makeup"],

  // ===================================================================
  // Sanity: explicit men's/unisex evidence still rejects even for
  // otherwise-inferrable categories (inference never overrides
  // explicit contrary evidence).
  // ===================================================================
  ["Men's foundation (explicit men's beats makeup inference)", {name: "Men's Tinted Foundation", merchantCategory: "Makeup"}, false, "makeup"],
  ["Unisex face moisturizer (explicit unisex beats skincare inference)", {name: "Unisex Face Moisturizer", merchantCategory: "Skincare"}, false, "skincare"],

  // ===================================================================
  // Sanity: merchant-category noise alone must NEVER create a match —
  // the product's own name/description decides, not retailer taxonomy.
  // ===================================================================
  ["Merchant category says Makeup, but name/description don't support it", {name: "Rawlink Venice Bicycle Bar Set", description: "Aluminium bicycle handlebar, black", merchantCategory: "Makeup"}, false, null],
  ["Merchant category says Skincare, but it's actually a household item", {name: "Multi-Surface Cleaning Spray 500ml", merchantCategory: "Skincare"}, false, null],

  // ===================================================================
  // Regression: a facial cleansing product whose own description
  // mentions removing makeup must stay skincare, not false-positive
  // into makeup via the bare "makeup"/"make-up" keyword. Reproduced
  // live via ROSIVA AI (a "highlighter" search returned these two as
  // makeup results) before this fix.
  // ===================================================================
  ["Simple Kind to Skin Purifying Cleansing Lotion (real bug: 'make-up' in description misfired makeup)", {name: "Simple Kind to Skin Purifying Cleansing Lotion - 200 ml", brand: "Simple", description: "Gently cleanses make-up and impurities. No colour, no perfume, no harsh chemicals that can upset your skin.", merchantCategory: "Skincare"}, true, "skincare"],
  ["Simple Water Boost Hydrating Cleansing Wipes (real bug: same false makeup match)", {name: "Simple Water Boost Hydrating Cleansing Wipes - 25 Pcs", brand: "Simple", description: "Removes make-up and refreshes skin.", merchantCategory: "Skincare"}, true, "skincare"],
  ["makeup remover stays a real makeup product (must not regress)", {name: "Bifesta Cleansing Makeup Remover", merchantCategory: "Makeup"}, true, "makeup"],

  // ===================================================================
  // Makeup TOOLS policy: genuine makeup APPLICATION tools are real
  // makeup products and must PASS; precision/grooming tools and
  // hair/nail tools are NOT makeup application tools and must stay
  // excluded.
  // ===================================================================
  ["makeup brush -> PASS (genuine makeup application tool)", {name: "Professional Makeup Brush", merchantCategory: "Makeup"}, true, "makeup"],
  ["eyebrow brush -> PASS", {name: "Eyebrow Brush", merchantCategory: "Makeup"}, true, "makeup"],
  ["blusher brush -> PASS", {name: "Blusher Brush", merchantCategory: "Makeup"}, true, "makeup"],
  ["foundation brush -> PASS", {name: "Foundation Brush", merchantCategory: "Makeup"}, true, "makeup"],
  ["beauty blender -> PASS", {name: "Beauty Blender Makeup Sponge", merchantCategory: "Makeup"}, true, "makeup"],
  ["concealer brush -> PASS", {name: "Concealer Brush", merchantCategory: "Makeup"}, true, "makeup"],
  ["eyeshadow brush -> PASS", {name: "Eyeshadow Brush Set", merchantCategory: "Makeup"}, true, "makeup"],
  ["lip brush -> PASS", {name: "Retractable Lip Brush", merchantCategory: "Makeup"}, true, "makeup"],
  ["cosmetic applicator -> PASS", {name: "Cosmetic Applicator Sponge", merchantCategory: "Makeup"}, true, "makeup"],

  ["hair brush -> FAIL (not a makeup tool)", {name: "Elina Hair Brush Set", brand: "Elina", merchantCategory: "Hair Care"}, false, null],
  ["hair trimmer -> FAIL", {name: "Cordless Hair Trimmer", merchantCategory: "Hair Care"}, false, null],
  ["manicure/pedicure tools -> FAIL", {name: "Manicure Pedicure Tool Set", merchantCategory: "Beauty Tools"}, false, null],
  ["nail scissors -> FAIL", {name: "Stainless Steel Nail Scissors", merchantCategory: "Beauty Tools"}, false, null],
  ["tweezers -> FAIL (precision tool, not an applicator)", {name: "Slant Tip Tweezers", merchantCategory: "Beauty Tools"}, false, null],
  ["cosmetic bag -> FAIL (not a makeup tool)", {name: "Cosmetic Bag Organiser", merchantCategory: "Accessories"}, false, null],
  ["toiletry bag -> FAIL (not a makeup tool)", {name: "Travel Toiletry Bag", merchantCategory: "Accessories"}, false, null],
];

let failed = 0;
for (const [label, input, expectEligible, expectCategory] of cases) {
  const r = classifyProduct(input);
  const ok = r.isRosivaProduct === expectEligible && r.rosivaCategory === expectCategory;
  if (!ok) failed++;
  console.log(
    (ok ? "PASS" : "FAIL"),
    label.padEnd(74),
    `-> eligible=${r.isRosivaProduct} category=${r.rosivaCategory} gender=${r.gender}`,
    ok ? "" : `  EXPECTED eligible=${expectEligible} category=${expectCategory}  (reason: ${r.classificationReason})`
  );
}

console.log(failed === 0 ? `\nALL PASS (${cases.length} cases)` : `\n${failed} FAILED of ${cases.length}`);
process.exit(failed === 0 ? 0 : 1);
