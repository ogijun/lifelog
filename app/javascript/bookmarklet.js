/*
 * ブックマークレットの本体。ページに出すときに空白を詰めて javascript: の1行にする
 * (BookmarkletsHelper#bookmarklet_href)。行コメントは使わない (1行にすると後ろが消える)。
 *
 * 見ているページの URL・タイトル・og:image・og:type・選んだ文字・ページ内のリンクを /capture に送る。
 * どのサイトでも同じ処理で、サイトごとの判定はサーバ (Capture の認識器) に置く。
 * フォームの POST だと CSP の form-action で止めるサイトがあるので、ページの移動 (GET) で送る。
 * リンクは「選んだ範囲 → 本文 (article / main) → その他」の順に、URL が約 8KB に収まるまで。
 */
(() => {
  const meta = document.querySelector('meta[property="og:image"],meta[name="twitter:image"],meta[property="twitter:image"]');
  const image = meta && meta.content ? new URL(meta.content, location.href).href : "";
  const type = (document.querySelector('meta[property="og:type"]') || {}).content || "";
  const selection = getSelection();
  const selected = selection.toString().trim().slice(0, 200);
  const inSelection = (a) => {
    for (let i = 0; i < selection.rangeCount; i++) if (selection.getRangeAt(i).intersectsNode(a)) return true;
    return false;
  };
  const rank = (a) => (inSelection(a) ? 0 : a.closest("article, main, [role=main]") ? 1 : 2);
  const seen = new Set();
  const anchors = [...document.querySelectorAll("a[href]")]
    .filter((a) => /^https?:/.test(a.href) && !seen.has(a.href) && seen.add(a.href))
    .map((a, i) => [rank(a), i, a])
    .sort((x, y) => x[0] - y[0] || x[1] - y[1]);
  const base = CAPTURE_URL + "?url=" + encodeURIComponent(location.href) +
    "&title=" + encodeURIComponent(document.title) + "&image=" + encodeURIComponent(image) +
    "&type=" + encodeURIComponent(type) +
    "&selection=" + encodeURIComponent(selected) + "&links=";
  const links = [];
  for (const [, , a] of anchors) {
    const link = [a.href, a.textContent.replace(/\s+/g, " ").trim().slice(0, 80)];
    if (base.length + encodeURIComponent(JSON.stringify([...links, link])).length > 8000) break;
    links.push(link);
  }
  location.href = base + encodeURIComponent(JSON.stringify(links));
})();
