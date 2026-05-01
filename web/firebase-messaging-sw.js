// Add Firebase scripts for the background service worker
importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js");

// Initialize Firebase App
// Replace these with the config from your Firebase Project Settings -> Web App
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyB888vVD-rALFgSSgh8yJw7QccOfx_xHT4",
  authDomain: "facultypay.firebaseapp.com",
  projectId: "facultypay",
  storageBucket: "facultypay.firebasestorage.app",
  messagingSenderId: "1085093252774",
  appId: "1:1085093252774:web:00fc55a403c0192a7e2e67",
  measurementId: "G-GMQF5HGFQ5"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
});