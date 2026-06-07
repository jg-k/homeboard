// Homeboard offline service worker.
//
// Two caches:
//   - PIN_CACHE: pages + layout images explicitly pinned by the user.
//     Strategy: cache-first.
//   - ASSET_CACHE: stylesheets, JS, icons. Auto-populated as the user
//     browses online. Strategy: stale-while-revalidate.
// Everything else is network-only.

// PIN_CACHE name is stable: it holds user-pinned data and must not be wiped
// just because we shipped unrelated SW changes. Refreshing the cached
// /offline shell happens explicitly in activate.
// ASSET_CACHE is versioned: bumping it costs nothing because assets
// re-download on first use.
const PIN_CACHE = "homeboard-pin"
const ASSET_CACHE = "homeboard-assets-v1"
const OFFLINE_URL = "/offline"
const KNOWN_CACHES = [PIN_CACHE, ASSET_CACHE]

async function refreshOfflineShell() {
  try {
    const res = await fetch(OFFLINE_URL, { credentials: "same-origin" })
    if (!res.ok) return
    const cache = await caches.open(PIN_CACHE)
    await cache.put(OFFLINE_URL, res.clone())
  } catch (_) { /* offline at SW update time */ }
}

self.addEventListener("install", (event) => {
  event.waitUntil((async () => {
    await refreshOfflineShell()
    self.skipWaiting()
  })())
})

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys()
    await Promise.all(names.filter(n => !KNOWN_CACHES.includes(n)).map(n => caches.delete(n)))
    // Re-fetch the offline shell on every SW update so changes to the
    // /offline route or its auth posture take effect without forcing
    // every user to re-pin their boards.
    await refreshOfflineShell()
    await self.clients.claim()
  })())
})

function cacheKey(url) {
  const u = new URL(url)
  u.search = ""
  u.hash = ""
  return u.toString().replace(/\/$/, "")
}

function isAssetRequest(request) {
  const u = new URL(request.url)
  if (u.origin !== self.location.origin) return false
  if (u.pathname.startsWith("/assets/")) return true
  if (u.pathname.startsWith("/rails/active_storage/")) return true
  if (/^\/icon\.(png|svg)$/.test(u.pathname)) return true
  if (u.pathname === "/manifest.json") return true
  return false
}

self.addEventListener("fetch", (event) => {
  const request = event.request
  if (request.method !== "GET") return

  event.respondWith((async () => {
    const pinCache = await caches.open(PIN_CACHE)
    const keyed = cacheKey(request.url)
    const pinned = await pinCache.match(keyed)

    if (pinned) {
      event.waitUntil((async () => {
        try {
          const fresh = await fetch(keyed, { credentials: "same-origin" })
          if (fresh.ok) await pinCache.put(keyed, fresh.clone())
        } catch (_) { /* offline */ }
      })())
      return pinned
    }

    if (isAssetRequest(request)) {
      const assetCache = await caches.open(ASSET_CACHE)
      const cached = await assetCache.match(keyed)
      const network = fetch(request).then(res => {
        if (res.ok) assetCache.put(keyed, res.clone())
        return res
      }).catch(() => null)
      return cached || (await network) || Response.error()
    }

    try {
      return await fetch(request)
    } catch (_) {
      if (request.mode === "navigate") {
        const cache = await caches.open(PIN_CACHE)
        const fallback = await cache.match(OFFLINE_URL)
        if (fallback) return fallback
      }
      return Response.error()
    }
  })())
})

self.addEventListener("message", (event) => {
  const { type, payload } = event.data || {}
  if (type === "PIN") {
    event.waitUntil(pinUrls(payload.urls, event.source))
  } else if (type === "UNPIN") {
    event.waitUntil(unpinUrls(payload.urls))
  } else if (type === "REFRESH") {
    event.waitUntil(refreshUrls(payload.add, payload.update, payload.remove, event.source))
  }
})

async function pinUrls(urls, source) {
  const cache = await caches.open(PIN_CACHE)
  let done = 0
  for (const url of urls) {
    try {
      const res = await fetch(url, { credentials: "same-origin" })
      if (res.ok) await cache.put(cacheKey(url), res.clone())
    } catch (e) { /* skip */ }
    done++
    if (source) source.postMessage({ type: "PIN_PROGRESS", done, total: urls.length })
  }
  if (source) source.postMessage({ type: "PIN_DONE", total: urls.length })
}

async function unpinUrls(urls) {
  const cache = await caches.open(PIN_CACHE)
  await Promise.all(urls.map(u => cache.delete(cacheKey(u))))
}

async function refreshUrls(add = [], update = [], remove = [], source) {
  const cache = await caches.open(PIN_CACHE)
  await Promise.all(remove.map(u => cache.delete(cacheKey(u))))
  for (const url of [...add, ...update]) {
    try {
      const res = await fetch(url, { credentials: "same-origin" })
      if (res.ok) await cache.put(cacheKey(url), res.clone())
    } catch (e) { /* skip */ }
  }
  if (source) source.postMessage({ type: "REFRESH_DONE" })
}
