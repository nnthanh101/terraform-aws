#!/bin/bash
set -euo pipefail

# Generate starship.toml with terraform workspace + AWS profile segments
STARSHIP_CONFIG="${HOME}/.config/starship.toml"
mkdir -p "$(dirname "$STARSHIP_CONFIG")"

if [ -f "$STARSHIP_CONFIG" ]; then
  echo "Starship config already exists at $STARSHIP_CONFIG"
  echo "Backing up to ${STARSHIP_CONFIG}.bak"
  cp "$STARSHIP_CONFIG" "${STARSHIP_CONFIG}.bak"
fi

cat > "$STARSHIP_CONFIG" << 'TOML'
# terraform-aws starship prompt
format = """$directory$git_branch$git_status$terraform$aws$line_break$character"""

[directory]
truncation_length = 3

[terraform]
format = "[$symbol$workspace]($style) "
symbol = "💠 "

[aws]
format = "[$symbol($profile )(\\($region\\) )]($style)"
symbol = "☁️ "

[git_branch]
format = "[$symbol$branch]($style) "

[git_status]
format = "[$all_status$ahead_behind]($style) "

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
TOML

echo "Starship config written to $STARSHIP_CONFIG"

# Wire into shell RC if not present
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  if [ -f "$rc" ] && ! grep -q 'starship init' "$rc"; then
    SHELL_NAME=$(basename "${rc%.rc}" | sed 's/^\.//')
    [ "$SHELL_NAME" = ".bashrc" ] && SHELL_NAME="bash"
    [ "$SHELL_NAME" = ".zshrc" ] && SHELL_NAME="zsh"
    echo "" >> "$rc"
    echo "# Starship prompt (added by terraform-aws)" >> "$rc"
    echo "eval \"\$(starship init $SHELL_NAME)\"" >> "$rc"
    echo "Added starship init to $rc"
  fi
done

echo "PASSED: starship:configure"
