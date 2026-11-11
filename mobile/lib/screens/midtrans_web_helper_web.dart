import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void ensureSnapJsLoaded() {
  final existing = web.document.getElementById('midtrans-snap-js');
  if (existing == null) {
    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.id = 'midtrans-snap-js';
    script.type = 'text/javascript';
    script.src = 'https://app.sandbox.midtrans.com/snap/snap.js';
    script.setAttribute(
        'data-client-key', 'SB-Mid-client-tD0VtwirtHPzxFBcKggQPS.I');
    web.document.head?.appendChild(script);
  }
}

Widget buildMidtransWebFrame(String url, {required VoidCallback onLoaded}) {
  final viewType = 'midtrans-iframe-${url.hashCode}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = url;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.allow = 'payment *; clipboard-read; clipboard-write';
    iframe.onload = (web.Event _) {
      onLoaded();
    }.toJS;
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}

void triggerMidtransSnapPopup(
  String token, {
  VoidCallback? onSuccess,
  VoidCallback? onPending,
  VoidCallback? onError,
  VoidCallback? onClose,
}) {
  ensureSnapJsLoaded();

  if (onSuccess != null) {
    web.window.addEventListener(
      'midtrans-payment-success',
      (web.Event _) {
        onSuccess();
      }.toJS,
    );
  }

  if (onPending != null) {
    web.window.addEventListener(
      'midtrans-payment-pending',
      (web.Event _) {
        onPending();
      }.toJS,
    );
  }

  if (onError != null) {
    web.window.addEventListener(
      'midtrans-payment-error',
      (web.Event _) {
        onError();
      }.toJS,
    );
  }

  if (onClose != null) {
    web.window.addEventListener(
      'midtrans-payment-close',
      (web.Event _) {
        onClose();
      }.toJS,
    );
  }

  final jsCode = '''
    (function() {
      var attempts = 0;
      function openSnap() {
        if (window.snap && typeof window.snap.pay === 'function') {
          try {
            window.snap.pay('$token', {
              onSuccess: function(result) {
                window.dispatchEvent(new CustomEvent('midtrans-payment-success', {detail: result}));
              },
              onPending: function(result) {
                window.dispatchEvent(new CustomEvent('midtrans-payment-pending', {detail: result}));
              },
              onError: function(result) {
                window.dispatchEvent(new CustomEvent('midtrans-payment-error', {detail: result}));
              },
              onClose: function() {
                window.dispatchEvent(new CustomEvent('midtrans-payment-close'));
              }
            });
          } catch(e) {
            console.error('Snap pay error:', e);
          }
        } else if (attempts < 20) {
          attempts++;
          setTimeout(openSnap, 300);
        }
      }
      openSnap();
    })();
  ''';

  final scriptEl =
      web.document.createElement('script') as web.HTMLScriptElement;
  scriptEl.text = jsCode;
  web.document.body?.appendChild(scriptEl);
  scriptEl.remove();
}
