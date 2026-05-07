function fish_command_not_found
    set cmd $argv[1]
    set artix_repos lib32 system world galaxy omniverse
    set results (pkgfile -b $cmd 2>/dev/null)
    
    if test -z "$results"
        echo "fish: команда '$cmd' не найдена ни в одном пакете"
        return 127
    end
    
    # Сначала ищем пакет с точным именем команды в Artix репо
    set selected_pkg ""
    for repo in $artix_repos
        set exact_match (string match -r "^$repo/$cmd\$" $results | head -n 1)
        if test -n "$exact_match"
            set selected_pkg $exact_match
            break
        end
    end
    
    # Если нет точного совпадения, берём первый из Artix
    if test -z "$selected_pkg"
        for repo in $artix_repos
            set found (string match -r "^$repo/.*" $results | head -n 1)
            if test -n "$found"
                set selected_pkg $found
                break
            end
        end
    end
    
    # Если и в Artix нет, ищем точное имя в Arch
    if test -z "$selected_pkg"
        set selected_pkg (string match -r ".+/$cmd\$" $results | head -n 1)
    end
    
    # Если всё ещё нет, берём первый попавшийся
    if test -z "$selected_pkg"
        set selected_pkg $results[1]
    end
    
    echo "Команда '$cmd' не найдена, но есть в пакете: $selected_pkg"
    read -P "Установить $selected_pkg? [y/N] " answer
    
    if test "$answer" = "y" -o "$answer" = "Y"
        set pkg_name (string split "/" $selected_pkg)[2]
        sudo pacman -S $pkg_name --needed --noconfirm
        if test $status -eq 0
            command $argv
        end
    end
    
    return 127
end
