{ config, pkgs, lib, ... }:

{
  xdg.configFile = {
    "zsh/.p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.sessionVariables.FLAKE}/home/novaviper/dots/zsh/.p10k.zsh";
    "zsh/functions" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.sessionVariables.FLAKE}/home/novaviper/dots/zsh/functions";
      recursive = true;
    };
    "zsh/manpages.zshrc".source = ../../dots/zsh/manpages.zshrc;
    "zsh/zsh-syntax-highlighting.sh".source =
      ../../dots/zsh/zsh-syntax-highlighting.sh;
  };

  home.packages = lib.mkMerge [
    (lib.mkIf (config.variables.desktop.useWayland)
      (with pkgs; [ wl-clipboard wl-clipboard-x11 ]))

    (lib.mkIf (!config.variables.desktop.useWayland)
      (with pkgs; [ xclip xsel xdotool xorg.xwininfo xorg.xprop ]))
  ];

  programs = {
    # Complete shell history replacement
    atuin = {
      enable = true;
      flags = [ ];
      settings = {
        keymap_mode = "auto";
        enter_accept = true;
      };
    };
    # Custom colors for ls, grep and more
    dircolors.enable = true;
    # terminal file manager written in Go
    lf = {
      enable = true;
      settings = {
        number = true;
        tabstop = 4;
      };
    };
    # Command-line fuzzy finder
    fzf = {
      enable = true;
      changeDirWidgetOptions =
        [ "--preview '${pkgs.tree}/bin/tree -C {} | head -200'" ];
      fileWidgetOptions =
        [ "--bind 'ctrl-/:change-preview-window(down|hidden|)'" ];
      historyWidgetOptions = [ "--sort" "--exact" ];
    };

    # The shell itself
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
      dotDir = ".config/zsh";
      defaultKeymap = "viins";
      autocd = true;
      history.path = "${config.xdg.configHome}/zsh/.zsh_history";
      localVariables = {
        # Make ZSH notifications expire, in miliseconds
        AUTO_NOTIFY_EXPIRE_TIME = 5000;
        # Make zsh-vi-mode be sourced
        ZVM_INIT_MODE = "sourcing";
        # Disable zsh-vi-mode's custom cursors
        ZVM_CURSOR_STYLE_ENABLED = false;
        # Prompt message for auto correct
        SPROMPT =
          "Correct $fg[red]%R$reset_color to $fg[green]%r$reset_color? [ny] ";
        # Add more strategies to zsh-autosuggestions
        ZSH_AUTOSUGGEST_STRATEGY = [ "history" "completion" ];
        # Customize style of zsh-autosuggestions
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "underline";
        # Make manpager use ls with color support``
        MANPAGER = "${pkgs.less}/bin/less -s -M +Gg";
      };
      initExtraFirst = ''
        # If not running interactively, don't do anything
        [[ $- != *i* ]] && return

        ${if config.programs.tmux.enable then ''
          # Run Tmux on startup
          if [ -z "$TMUX" ]; then
            ${pkgs.tmux}/bin/tmux attach >/dev/null 2>&1 || ${pkgs.tmuxp}/bin/tmuxp load ${config.xdg.configHome}/tmuxp/session.yaml >/dev/null 2>&1
            exit
          fi
        '' else
          ""}
      '';

      initExtra = lib.mkAfter ''
        # Append extra variables
        AUTO_NOTIFY_IGNORE+=("atuin" "yadm" "emacs" "nix-shell")

        source "$ZDOTDIR/manpages.zshrc"
        source "$ZDOTDIR/.p10k.zsh"
        source "$ZDOTDIR/zsh-syntax-highlighting.sh"

        setopt beep CORRECT # Enable terminal bell and autocorrect
        autoload -U colors && colors # Enable colors

        ### Pyenv command
        if command -v pyenv 1>/dev/null 2>&1; then
          eval "$(pyenv init -)"
        fi

        # set descriptions format to enable group support
        zstyle ':completion:*:descriptions' format '[%d]'

        # set list-colors to enable filename colorizing
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

        # disable sorting when completing any command
        zstyle ':completion:complete:*:options' sort false

        # switch group using `,` and `.`
        zstyle ':fzf-tab:*' switch-group ',' '.'

        # trigger continuous trigger with space key
        zstyle ':fzf-tab:*' continuous-trigger 'space'

        # bind tab key to accept event
        zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'

        # accept and run suggestion with enter key
        zstyle ':fzf-tab:*' accept-line enter

        # Enable fzf-tab integration with tmux
        ${if config.programs.tmux.enable then
          "zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup"
        else
          ""}

        # Create shell prompt
        if [ $(tput cols) -ge '75' ] || [ $(tput cols) -ge '100' ]; then
          ${pkgs.dwt1-shell-color-scripts}/bin/colorscript exec square
          ${pkgs.toilet}/bin/toilet -f pagga "FOSS AND BEAUTIFUL" --metal
        fi
      '';

      shellAliases = {
        # Easy access to accessing Doom cli
        doom = "${config.home.sessionVariables.EMDOTDIR}/bin/doom";
        # Refresh Doom configurations and Reload Doom Emacs
        doom-config-reload =
          "${config.home.sessionVariables.EMDOTDIR}/bin/org-tangle ${config.home.sessionVariables.DOOMDIR}/config.org && ${config.home.sessionVariables.EMDOTDIR}/bin/doom sync && systemctl --user restart emacs";
        # Substitute Doom upgrade command to account for fixing the issue of org-tangle not working
        doom-upgrade = ''
          ${config.home.sessionVariables.EMDOTDIR}/bin/doom upgrade --force && sed -i -e "/'org-babel-tangle-collect-blocks/,+1d" ${config.home.sessionVariables.EMDOTDIR}/bin/org-tangle
        '';
        # Download Doom Emacs frameworks
        doom-download = ''
          git clone https://github.com/hlissner/doom-emacs.git ${config.home.sessionVariables.EMDOTDIR}
        '';
        # Run fix to make org-tangle module work again
        doom-fix = ''
          sed -i -e "/'org-babel-tangle-collect-blocks/,+1d" ${config.home.sessionVariables.EMDOTDIR}/bin/org-tangle
        '';
        # Create Emacs config.el from my Doom config.org
        doom-org-tangle =
          "${config.home.sessionVariables.EMDOTDIR}/bin/org-tangle ${config.home.sessionVariables.DOOMDIR}/config.org";
        # Easy Weather
        weather = "curl 'wttr.in/Baton+Rouge?u?format=3'";
        # Make gpg switch Yubikey
        gpg-switch-yubikey =
          ''gpg-connect-agent "scd serialno" "learn --force" /bye'';

        # Make gpg smartcard functionality work again
        #fix-gpg-smartcard =
        #"pkill gpg-agent && sudo systemctl restart pcscd.service && sudo systemctl restart pcscd.socket && gpg-connect-agent /bye";
        # Load PKCS11 keys into ssh-agent
        load-pkcs-key = "ssh-add -s ${pkgs.opensc}/lib/pkcs11/opensc-pkcs11.so";
        # Remove PKCS11 keys into ssh-agent
        remove-pkcs-key =
          "ssh-add -e ${pkgs.opensc}/lib/pkcs11/opensc-pkcs11.so";
        # Remove all identities
        remove-ssh-keys = "ssh-add -D";
        # List all SSH keys in the agent
        list-ssh-key = "ssh-add -L";
        # Make resident ssh keys import from Yubikey
        load-res-keys = "ssh-keygen -K";
        # Quickly start Minecraft server
        start-minecraft-server = lib.mkIf (config.programs.mangohud.enable)
          "cd ~/Games/MinecraftServer-1.20.1/ && ./run.sh --nogui && cd || cd";
        # Append HISTFILE before running autin import to make it work properly
        atuin-import = lib.mkIf (config.programs.atuin.enable)
          "export HISTFILE && atuin import auto && export -n HISTFILE";
      };
      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          # Prompts
          "romkatv/powerlevel10k"

          #Docs https://github.com/jeffreytse/zsh-vi-mode#-usage
          "jeffreytse/zsh-vi-mode"

          # Fish-like Plugins
          "mattmc3/zfunctions"
          "Aloxaf/fzf-tab"
          "Freed-Wu/fzf-tab-source"
          "MichaelAquilina/zsh-auto-notify"

          # Sudo escape
          "ohmyzsh/ohmyzsh path:lib"
          "ohmyzsh/ohmyzsh path:plugins/sudo"

          # Tmux integration
          (lib.mkIf (config.programs.tmux.enable)
            "ohmyzsh/ohmyzsh path:plugins/tmux")

          # Nix stuff
          "chisui/zsh-nix-shell"

          # Make ZLE use system clipboard
          "kutsan/zsh-system-clipboard"
        ];
      };

      /* zplug = {
           enable = true;
           zplugHome = "${config.xdg.configHome}/zsh/zplug";
           plugins = [
             # Prompts
             {
               name = "romkatv/powerlevel10k";
               tags = [ "as:theme" "depth:1" ];
             }
             #Docs https://github.com/jeffreytse/zsh-vi-mode#-usage
             { name = "jeffreytse/zsh-vi-mode"; }
             { name = "mattmc3/zfunctions"; }
             { name = "Aloxaf/fzf-tab"; }
             {
               name = "MichaelAquilina/zsh-auto-notify";
             }
             # Sudo escape
             {
               name = "plugins/sudo";
               tags = [ "from:oh-my-zsh" ];
             }
             (lib.mkIf (config.programs.tmux.enable) {
               name = "plugins/tmux";
               tags = [ "from:oh-my-zsh" ];
             })
             # Nix stuff
             {
               name = "chisui/zsh-nix-shell";
             }
             # Make ZLE use system clipboard
             { name = "kutsan/zsh-system-clipboard"; }
           ];
         };
      */
    };
  };
}
