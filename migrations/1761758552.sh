echo "Set text editor as default for all text mime types"

rm ~/.local/share/applications/nvim.desktop || true

# Query current default for text/plain
current_text_editor=$(xdg-mime query default text/plain 2>/dev/null || echo "")

# Use current default if set, otherwise fall back to nvim
if [ -n "$current_text_editor" ]; then
  echo "Using current default text editor: $current_text_editor"
  text_editor="$current_text_editor"
else
  echo "No default text editor set, using nvim as default"
  text_editor="nvim.desktop"
fi

# Set the editor for all text-related mime types
xdg-mime default "$text_editor" text/plain
xdg-mime default "$text_editor" text/english
xdg-mime default "$text_editor" text/x-makefile
xdg-mime default "$text_editor" text/x-c++hdr
xdg-mime default "$text_editor" text/x-c++src
xdg-mime default "$text_editor" text/x-chdr
xdg-mime default "$text_editor" text/x-csrc
xdg-mime default "$text_editor" text/x-java
xdg-mime default "$text_editor" text/x-moc
xdg-mime default "$text_editor" text/x-pascal
xdg-mime default "$text_editor" text/x-tcl
xdg-mime default "$text_editor" text/x-tex
xdg-mime default "$text_editor" application/x-shellscript
xdg-mime default "$text_editor" text/x-c
xdg-mime default "$text_editor" text/x-c++
xdg-mime default "$text_editor" application/xml
xdg-mime default "$text_editor" text/xml

