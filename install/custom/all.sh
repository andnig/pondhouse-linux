run_logged $OMARCHY_INSTALL/custom/pacman.sh
run_logged $OMARCHY_INSTALL/custom/home.sh
run_logged $OMARCHY_INSTALL/custom/mimetypes.sh
run_logged $OMARCHY_INSTALL/custom/misc.sh
run_logged $OMARCHY_INSTALL/custom/tuis.sh
run_logged $OMARCHY_INSTALL/custom/herdr.sh
run_logged $OMARCHY_INSTALL/custom/herdr-reviewr.sh
run_logged $OMARCHY_INSTALL/custom/zsh.sh
run_logged $OMARCHY_INSTALL/custom/terminal.sh
run_logged $OMARCHY_INSTALL/custom/yay.sh || echo "Yay installation failed, continuing..."
