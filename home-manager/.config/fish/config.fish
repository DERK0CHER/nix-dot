## ~/.config/fish/config.fish
# Linux-safe variant of your original fish config.
# Keep user bins first.
set -x PATH $HOME/bin /usr/local/bin $HOME/.local/bin $PATH

# Initialize Homebrew only when present.
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# ————————————————————————
# 2) Set XDG_DATA_DIRS.
if test -x /opt/homebrew/bin/brew
    set -l brew_share (brew --prefix)/share
    if set -q XDG_DATA_DIRS
        set -x XDG_DATA_DIRS "$brew_share:$XDG_DATA_DIRS"
    else
        set -x XDG_DATA_DIRS "$brew_share"
    end
end

# ————————————————————————
# 4) Prepend common bin dirs to PATH
set -x PATH /usr/local/bin $HOME/.local/bin $PATH

# ————————————————————————
# 5) Extend MANPATH
set -Ux MANPATH $MANPATH $HOME/.local/man/

# ————————————————————————
# 6) Interactive‑only tweaks
if status is-interactive
    set -g fish_greeting ""

    function fish_greeting
        echo (set_color magenta)"
        (\__/)
        (•ㅅ•)  ~
        / 　 づ  Fish shell ready!
        >°)))彡 ~
    "(set_color normal)
    end
    # …add other interactive stuff here…
end

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
