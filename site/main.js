// Points the download buttons at the APK in the latest GitHub release.
// Falls back to the releases page (the buttons' default href) when there is no
// release yet, the API is rate-limited, or the visitor is offline.
(async () => {
  document.getElementById('year').textContent = new Date().getFullYear();

  const repo = window.QP_REPO;
  if (!repo || repo.startsWith('__')) return; // local preview without substitution
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' },
    });
    if (!res.ok) return;
    const release = await res.json();
    const apk = (release.assets || []).find((a) => a.name.endsWith('.apk'));
    if (!apk) return;
    for (const id of ['download-apk', 'download-apk-2']) {
      document.getElementById(id).href = apk.browser_download_url;
    }
    const mb = (apk.size / (1024 * 1024)).toFixed(1);
    const date = new Date(release.published_at).toLocaleDateString(undefined, { dateStyle: 'medium' });
    document.getElementById('release-meta').textContent = `${release.tag_name} · ${mb} MB · ${date}`;
  } catch (_) {
    // Keep the releases-page fallback.
  }
})();
