eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fish_add_path -g $HOME/.local/bin

if status is-interactive
    set -g fish_greeting

    starship init fish | source
    fzf --fish | source

    macchina
end
