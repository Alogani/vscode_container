#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gio, Gtk, WebKit2

class BrowserApp(Gtk.Application):
    def __init__(self, app_name, title, port):
        super().__init__(application_id=app_name,
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.connect("activate", lambda app: self.on_activate(app, app_name, title, port))

    def on_activate(self, app, app_name, title, port):
        win = Gtk.ApplicationWindow(application=app, title=title)
        win.set_default_size(1000, 800)
        win.set_icon_name(app_name)

        # Create the WebView
        webview = WebKit2.WebView()
        webview.load_uri(f"http://127.0.0.1:{port}")

        # Ensure it can receive focus
        webview.set_can_focus(True)
        webview.grab_focus()
        
        # Connect the permission-request signal
        webview.connect("permission-request", self.on_permission_request)
                
        win.add(webview)
        win.show_all()
        
    def on_permission_request(self, web_view, request):
        if isinstance(request, WebKit2.ClipboardPermissionRequest):
            # Grant clipboard read access
            request.allow()
            return True  # Stop further handling
        return False  # Let other handlers process the request

if __name__ == '__main__':
    import sys
    app = BrowserApp(sys.argv[1], sys.argv[2], sys.argv[3])
    sys.exit(app.run())
