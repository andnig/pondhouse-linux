echo "Skipping Neovim setup, now managed by Pondhouse"
exit 0

echo "Change to omarchy-nvim package"
omarchy-pkg-drop omarchy-lazyvim
omarchy-pkg-add omarchy-nvim

# Will trigger to overwrite configs or not to pickup new hot-reload themes
omarchy-nvim-setup
