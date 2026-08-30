/**
 * Lightweight dominant-language detection for reply wording.
 *
 * Mirrors the rule the old Gemini system-prompt used: an Arabic
 * sentence that contains a single English product word ("mascara") is
 * still Arabic. So: if the message contains ANY Arabic letters, treat
 * it as Arabic-dominant unless it's overwhelmingly Latin; otherwise
 * English. The caller's `locale` is only a tie-breaker.
 */
const ARABIC_RANGE = /[؀-ۿݐ-ݿࢠ-ࣿ]/;
const ARABIC_GLOBAL = /[؀-ۿݐ-ݿࢠ-ࣿ]/g;
const LATIN_GLOBAL = /[A-Za-z]/g;

/**
 * @param {string} message
 * @param {string} [locale] 'ar' | 'en' | anything
 * @return {'ar'|'en'}
 */
export function detectDominantLanguage(message, locale) {
  const text = String(message || '');
  if (!ARABIC_RANGE.test(text)) {
    // No Arabic at all.
    return locale === 'ar' && text.trim() === '' ? 'ar' : 'en';
  }
  const arabic = (text.match(ARABIC_GLOBAL) || []).length;
  const latin = (text.match(LATIN_GLOBAL) || []).length;
  // Any meaningful Arabic presence wins unless Latin dwarfs it (>3x).
  if (arabic === 0) return 'en';
  if (latin > arabic * 3) return 'en';
  return 'ar';
}
