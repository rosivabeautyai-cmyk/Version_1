import test from "node:test";
import assert from "node:assert/strict";

import { isMensProduct } from "../lib/mensFilter.mjs";

test("excludes men's variants", () => {
  for (const name of [
    "Homme Sport Eau de Toilette",
    "Dior Sauvage Pour Homme",
    "Nivea Men Face Wash",
    "Mens Grooming Kit",
    "Men's Beard Balm",
    "Beard & Moustache Oil",
    "Shaving Cream Sensitive",
    "Aftershave Splash",
    "Barber Grade Pomade",
    "Cologne For Him Gift Set",
  ]) {
    assert.equal(isMensProduct({ name }).excluded, true, name);
  }
});

test("does NOT exclude women's / neutral products (word boundaries)", () => {
  for (const name of [
    "Women's Lash Mascara",
    "Waterproof Mascara for Women",
    "Skin Supplement Capsules",
    "Daily Regimen Serum",
    "Menu Card Sample", // "menu"
    "Amendment-Free Formula",
    "Rose Petal Perfume 30ml",
    "Hydra Boost Vitamin C Serum",
    "Matte Ink Lipstick",
  ]) {
    assert.equal(isMensProduct({ name }).excluded, false, name);
  }
});

test("checks the category field too", () => {
  assert.equal(
    isMensProduct({ name: "Sport Balm", categoryName: "Men's Grooming" }).excluded,
    true,
  );
});

test("reports which keyword matched", () => {
  assert.equal(isMensProduct({ name: "Pour Homme EDT" }).matched, "pour homme");
  assert.equal(isMensProduct({ name: "Beard Oil" }).matched, "beard");
});
