/* ROSIVA — Firebase Cloud Messaging service worker (Web Push).
 *
 * Loaded automatically by `firebase_messaging_web` from the site root
 * (`/firebase-messaging-sw.js`). It runs in the Service Worker context —
 * no DOM, no ES modules — so it uses the Firebase *compat* SDK via
 * importScripts.
 *
 * The values below are the PUBLIC Firebase Web config (the same ones
 * already shipped in the app bundle / firebase_options.dart). No server
 * key, no VAPID private key — nothing secret lives here.
 */
importScripts(
  "https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyBl58zQ4J5bsaYHBMbY5eIpjpZd7B0oTVM",
  authDomain: "rosiva-24fa4.firebaseapp.com",
  projectId: "rosiva-24fa4",
  storageBucket: "rosiva-24fa4.firebasestorage.app",
  messagingSenderId: "1075173890462",
  appId: "1:1075173890462:web:c0a6ba8687887ea34a9e8f",
  measurementId: "G-GKN3YPV0QX",
});

const messaging = firebase.messaging();

// Background / closed-tab data messages. Notification-type messages are
// shown by the browser automatically; this only adds a fallback for
// data-only payloads so the user still sees something.
messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || payload.data || {};
  const title = n.title || "ROSIVA";
  const options = {
    body: n.body || "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});

// Focus / open the app when a background notification is clicked.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const route = (event.notification.data && event.notification.data.route) || "/";
  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ("focus" in client) return client.focus();
        }
        if (self.clients.openWindow) return self.clients.openWindow(route);
      })
  );
});
