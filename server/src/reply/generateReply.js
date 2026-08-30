import { groqChatResilient, GroqError } from '../groqClient.js';

/**
 * Localized, deterministic copy. Used verbatim for every case except
 * the "here are products" intro, which gets one short LLM call for a
 * natural sentence (with these as the fallback if the model fails).
 */
const COPY = {
  ar: {
    unsupported:
      'روزيفيا حاليًا بتوفر منتجات العناية بالبشرة والمكياج والعطور النسائية بس ❤️ '
      + 'اسأليني عن أي حاجة في الفئات دي.',
    unsupportedMen:
      'روزيفيا حاليًا كتالوجها نسائي بس (عناية بالبشرة، مكياج، عطور) ❤️ '
      + 'مش متوفر عندنا منتجات رجالي أو للجنسين.',
    noProducts: 'معنديش منتجات مناسبة لطلبك حاليًا ❤️',
    productsIntro: 'لقيتلك شوية منتجات ممكن تناسبك ❤️',
    aiBusy: 'المساعد مشغول حاليًا، جربي تاني بعد شوية ❤️',
    aiUnavailable: 'الـAI مش متاح مؤقتًا، جربي تاني بعد شوية ❤️',
  },
  en: {
    unsupported:
      "ROSIVA currently offers women's skincare, makeup and perfume only ❤️ "
      + 'Ask me about anything in those categories.',
    unsupportedMen:
      "ROSIVA's catalog is women's only right now (skincare, makeup, perfume) ❤️ "
      + "We don't carry men's or unisex products.",
    noProducts: "I don't have a matching product for that right now ❤️",
    productsIntro: 'Here are a few products that may suit you ❤️',
    aiBusy: 'The assistant is busy right now. Please try again in a moment ❤️',
    aiUnavailable: 'The AI is temporarily unavailable. Please try again ❤️',
  },
};

/** @param {'ar'|'en'} lang */
export function copyFor(lang) {
  return COPY[lang === 'ar' ? 'ar' : 'en'];
}

/**
 * Deterministic reply for the no-LLM-needed cases.
 * @param {object} opts
 * @param {'ar'|'en'} opts.lang
 * @param {'unsupported'|'no_products'} opts.kind
 * @param {string} [opts.reason]  intent.reason, to pick men/unisex wording
 */
export function deterministicReply({ lang, kind, reason = '' }) {
  const c = copyFor(lang);
  if (kind === 'unsupported') {
    if (reason.includes('mens') || reason.includes('unisex')) return c.unsupportedMen;
    return c.unsupported;
  }
  return c.noProducts;
}

/**
 * One short Groq call to introduce a set of REAL products. Only
 * minimal fields (name, brand, price) are sent — never descriptions,
 * ingredients, the full catalog, or product URLs.
 *
 * @param {object} opts
 * @param {string} opts.message   the user's latest message
 * @param {'ar'|'en'} opts.lang
 * @param {object[]} opts.products ranked, client-shaped
 * @param {Function} [opts._groq]  test seam
 * @return {Promise<string>}
 */
export async function generateProductsIntro({ message, lang, products, _groq }) {
  const fallback = copyFor(lang).productsIntro;
  if (!products.length) return fallback;

  const list = products
    .slice(0, 6)
    .map((p) => {
      const price = p.price != null ? `${p.price} ${p.currency}` : '';
      return `- ${p.name}${p.brand ? ` (${p.brand})` : ''}${price ? ` ${price}` : ''}`;
    })
    .join('\n');

  const system = [
    'You are ROSIVA AI, a warm, concise beauty shopping assistant for women',
    '(skincare, makeup, perfume only). Write ONE short friendly sentence (max ~25',
    `words) introducing the product list below. Reply in ${lang === 'ar' ? 'Arabic' : 'English'}.`,
    'Do NOT list the products, do NOT mention prices/brands, do NOT invent anything,',
    'do NOT give medical advice. Just a friendly lead-in.',
  ].join(' ');

  const call = _groq || groqChatResilient;
  try {
    const text = await call({
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: `My message: "${String(message).slice(0, 300)}"\nProducts:\n${list}` },
      ],
      maxTokens: 80,
      temperature: 0.5,
    });
    const trimmed = (text || '').trim();
    return trimmed || fallback;
  } catch (err) {
    if (err instanceof GroqError) return fallback;
    return fallback;
  }
}
