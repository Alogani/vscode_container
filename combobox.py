#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

def show_container_chooser(title, prompt, containers):
    dialog = Gtk.Dialog(title=title, modal=True)
    dialog.add_buttons(
        Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
        Gtk.STOCK_OK, Gtk.ResponseType.OK
    )

    box = dialog.get_content_area()
    box.set_spacing(10)
    box.set_margin_top(10)
    box.set_margin_bottom(10)
    box.set_margin_start(10)
    box.set_margin_end(10)

    label = Gtk.Label(label=prompt)
    label.set_halign(Gtk.Align.START)
    box.add(label)

    combo = Gtk.ComboBoxText()
    for c in containers:
        combo.append_text(c)
    combo.set_active(0)
    combo.set_hexpand(True)
    box.add(combo)

    dialog.show_all()
    response = dialog.run()

    selected = combo.get_active_text() if response == Gtk.ResponseType.OK else None
    dialog.destroy()
    return selected

# Example usage
if __name__ == '__main__':
    import sys
    choice = show_container_chooser(sys.argv[1], sys.argv[2], sys.argv[3:])
    if choice:
        print(choice)
        sys.exit(0)
    else:
        sys.exit(0)

