function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end
export PATH="$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    zoxide init fish | source
    atuin init fish | source

    if test "$TERM" = xterm-kitty
        pokemon-colorscripts -r
        #fastfetch --logo-type kitty --logo-width 27 --logo ~/dotfiles/Artix.png --config examples/13.jsonc --logo-padding-top 1
        echo ""
    end
    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias l 'ls -l'
    alias la 'ls -a'
    alias lla 'ls -la'
    alias lt 'ls --tree'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias venv 'uv venv .venv && source .venv/bin/activate.fish'
    alias pvenv 'python -m venv .venv && source .venv/bin/activate.fish'
    alias uvp 'uv pip'
    alias cd z
    alias rm trash-put
    alias cat 'bat -p'
    alias mkdir 'mkdir -p'

end
fish_add_path /home/rvdxse/.spicetify
