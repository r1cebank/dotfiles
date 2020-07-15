#!/usr/bin/env bash

function wrap_up_init() {
    task_setup "wrap_up" "Final wrap up" "Finishing install" "check_system"
}

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout

  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done

  ((++wait_seconds))
}

function wrap_up_run() {
    PLATFORM=$(settings_get "PLATFORM")
    if [ "$PLATFORM" = "debian" ]; then
        if ask "Reboot?"; then
            sudo reboot
        fi
    elif [ "$PLATFORM" = "arch" ]; then
        # Force Xorg login
        sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/g' /etc/gdm/custom.conf
        # Set plymouth theme
        sudo plymouth-set-default-theme -R arch-logo
        # Fix yubikey-agent service
        # sudo sed -i 's/multi-user.target/default.target/g' /usr/lib/systemd/user/yubikey-agent.service
        # systemctl daemon-reload --user
        # systemctl --user enable --now yubikey-agent

        # Enable boot splash
        sudo sed -i 's/$/ quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0/' /boot/loader/entries/archlinux.conf

        # Setting fcitx config
        fcitx > /dev/null 2>&1 &
        log_info "Waiting for fcitx to start"
        wait_file "$HOME/.config/fcitx/profile" 5 || {
            log_error "Fcitx profile does not exist after 5 secs..."
            return ${E_FAILURE}
        }
        log_info "Waiting for file to finish writing..."
        sleep 10
        sed -i 's/sogouimebs:False/sogouimebs:True/g' $HOME/.config/fcitx/profile
        if ask "Reboot?"; then
            sudo reboot
        fi
    fi
    return ${E_SUCCESS}
}
