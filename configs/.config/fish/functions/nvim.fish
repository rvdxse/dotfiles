function nvim
    kitty @ set-spacing padding=0 margin=0
    command nvim $argv
    kitty @ set-spacing padding=default margin=default
end
