if (typeof window === 'undefined') {
  self.addEventListener('install', () => self.skipWaiting());
  self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

  self.addEventListener('fetch', (event) => {
    const req = event.request;
    if (req.cache === 'only-if-cached' && req.mode !== 'same-origin') return;

    event.respondWith((async () => {
      const response = await fetch(req);
      if (!response || response.status === 0) return response;

      const headers = new Headers(response.headers);
      headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
      headers.set('Cross-Origin-Opener-Policy', 'same-origin');

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers,
      });
    })());
  });
} else {
  (() => {
    if (window.crossOriginIsolated === false && 'serviceWorker' in navigator) {
      navigator.serviceWorker.register('./coi-serviceworker.js').then(() => {
        if (navigator.serviceWorker.controller) {
          window.location.reload();
        }
      }).catch((err) => {
        console.warn('COI service worker registration failed:', err);
      });
    }
  })();
}
