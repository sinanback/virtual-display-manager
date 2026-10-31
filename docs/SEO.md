# Website and search maintenance

Production URL: https://sinanback.github.io/virtual-display-manager/

## Structure

- `/`: Turkish product page for monitor-free Windows remote access.
- `/en/`: English equivalent.
- `/monitorsuz-uzak-baglanti-siyah-ekran/` and its `/en/headless-remote-desktop-black-screen/` translation: practical display-capture troubleshooting.
- `/hdmi-dummy-plug-alternatifi/` and its `/en/hdmi-dummy-plug-alternative/` translation: physical display emulators vs. software virtual monitors.
- `/sitemap.xml`: six canonical URLs with reciprocal language alternates.

All core content and links are rendered in static HTML. JavaScript only enhances the clearly labeled behavior illustration. CSS, fonts and images do not depend on third-party CDNs. Pages have distinct titles/descriptions, canonical URLs, `tr`/`en`/`x-default` alternates, social preview metadata and semantic headings. App metadata uses SoftwareApplication JSON-LD; guides use TechArticle and BreadcrumbList. No reviews, star ratings, customers or compatibility certifications are fabricated.

SoftwareApplication data without a real review/rating does **not** meet all Google's software-app rich-result requirements. Do not add fictional ratings to pass a validator. The FAQ is useful visible content, not a promise of FAQ rich results.

## Update and validate

```powershell
python scripts/build-website.py
python tests/verify-website.py
```

Build production URLs before committing. `--base-url http://127.0.0.1:8765/` is for temporary local preview only. The verification script rejects preview URLs and checks internal links, image dimensions, unique canonicals, language reciprocity and sitemap coverage.

The build does not regenerate the stylesheet, behavior script or application screenshot: these are tracked in `docs/assets`. The generator copies the tracked application icon/cover into the website. Keep the screenshot current when the interface changes. Update guide modification dates only when the content actually changes.

## GitHub Pages

Publish `main` → `/docs`. `.nojekyll` keeps deployment buildless. GitHub also serves existing Markdown files in this directory as static source files; they are not added to the sitemap. The application source and release tag are independent of the website deployment.

This is a project under the `sinanback.github.io` host, not the host root. A project-local `robots.txt` would not control the host's crawler policy; do not treat it as authoritative. Indexable pages use `index,follow`, and the custom 404 uses `noindex`. Submit the full project sitemap URL directly through Search Console.

## Google Search Console

1. Add a URL-prefix property for `https://sinanback.github.io/virtual-display-manager/` in the owner's Google Search Console account.
2. Use the HTML-file or meta-tag verification method. Commit only the verification file/tag supplied by Google. Do not add a placeholder token or claim verification without a successful result.
3. Submit `https://sinanback.github.io/virtual-display-manager/sitemap.xml`.
4. Inspect the home page and English page; request indexing when eligible.
5. Track impressions, clicks, indexed URLs and queries over time. A new deployment does not prove that Google has crawled or indexed it.

Ranking depends on relevance, quality, competition and genuine references from other sites. Do not buy links, generate doorway pages, stuff hidden keywords, create fake reviews or guarantee a first-place result. Share the project where it is actually useful; don't post to third parties without the owner's instruction.

## Primary references

- [Google SEO Starter Guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide)
- [Google software-app structured data](https://developers.google.com/search/docs/appearance/structured-data/software-app)
- [Sitemaps](https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview)
- [Requesting recrawling](https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl)
- [GitHub Pages publication sources](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
