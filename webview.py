#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, WebKit2, Gdk

class BrowserWindow(Gtk.Window):
    def __init__(self, title, port):
        super().__init__(title=title)
        self.set_default_size(800, 600)

        # Create the WebView
        self.webview = WebKit2.WebView()
        self.webview.load_uri(f"http://127.0.0.1:{port}")

        # Ensure it can receive focus
        self.webview.set_can_focus(True)
        self.webview.grab_focus()
        
        # Connect the permission-request signal
        self.webview.connect("permission-request", self.on_permission_request)
                
        self.add(self.webview)
        self.show_all()
        
    def on_permission_request(self, web_view, request):
        if isinstance(request, WebKit2.ClipboardPermissionRequest):
            # Grant clipboard read access
            request.allow()
            return True  # Stop further handling
        return False  # Let other handlers process the request

if __name__ == '__main__':
    import sys
    win = BrowserWindow(sys.argv[1], sys.argv[2])
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()
