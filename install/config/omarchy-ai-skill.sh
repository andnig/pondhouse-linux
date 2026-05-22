# Place in each assistant's global skills directory so the Omarchy skill is available on first install.
# ~/.agents/skills/omarchy is provided via the `agents` stow package
# (see install/custom/home.sh and config/agents/.agents/skills/omarchy), so it
# is intentionally not recreated here.
mkdir -p ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$OMARCHY_PATH/default/omarchy-skill" ~/.claude/skills/omarchy
ln -sfn "$OMARCHY_PATH/default/omarchy-skill" ~/.codex/skills/omarchy
ln -sfn "$OMARCHY_PATH/default/omarchy-skill" ~/.pi/agent/skills/omarchy
