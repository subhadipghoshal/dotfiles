# dotfiles

Personal dotfiles, managed with [chezmoi](https://chezmoi.io).

This repository is the chezmoi **source state**: filenames use chezmoi's
encoding (`dot_zshrc` → `~/.zshrc`, `private_` → mode 0700,
`executable_` → mode +x, `symlink_` → a symlink).

## Layout

| Source | Target | What |
|---|---|---|
| `dot_zshrc`, `dot_zshenv`, `dot_zprofile` | `~/.zshrc` etc. | zsh bootstrap |
| `dot_zsh/` | `~/.zsh/` | zsh modules, one concern per file, loaded by a glob loop |
| `dot_p10k.zsh` | `~/.p10k.zsh` | powerlevel10k prompt |
| `dot_config/nvim/` | `~/.config/nvim/` | LazyVim-based neovim config |
| `dot_config/tmux/` | `~/.config/tmux/` | tmux config, split into `conf/` + `scripts/` |
| `dot_config/agents/AGENTS.md` | `~/.config/agents/AGENTS.md` | canonical global agent instructions |
| `dot_agents/skills/` | `~/.agents/skills/` | shared agent skills |
| `private_dot_claude/` | `~/.claude/` | Claude Code settings, commands, skills |
| `dot_codex/`, `dot_config/opencode/` | | symlinks to the canonical `AGENTS.md` |
| `dot_config/zsh-sandbox/` | `~/.config/zsh-sandbox/` | isolated `ZDOTDIR` harness for testing shell changes |

## Install on a new machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply subhadipghoshal
```

## Notes

- `~/.config/tmux/plugins/` is TPM-managed and deliberately untracked.
- Credential stores (`~/.config/gh`, `~/.config/gcloud`, `~/.config/anthropic`,
  `~/.codex/auth.json`) are deliberately **not** managed here. This repo is public.
- History before the chezmoi layout is preserved at the tag `pre-chezmoi-2026-01`.
