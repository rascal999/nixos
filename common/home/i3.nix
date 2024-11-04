{ config, pkgs, ... }:

{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";  # Use Super (Windows key) as modifier
      
      # Default terminal
      terminal = "alacritty";

      # Default gaps
      gaps = {
        inner = 5;
        outer = 0;
      };

      # Basic keybindings
      keybindings = let
        modifier = config.xsession.windowManager.i3.config.modifier;
      in {
        "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+r" = "restart";
        "${modifier}+Shift+e" = "exec i3-nagbar -t warning -m 'Exit?' -B 'Yes' 'i3-msg exit'";
        
        # Screenshots
        "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";
        
        # Focus
        "${modifier}+Left" = "focus left";
        "${modifier}+Down" = "focus down";
        "${modifier}+Up" = "focus up";
        "${modifier}+Right" = "focus right";
        
        # Move
        "${modifier}+Shift+Left" = "move left";
        "${modifier}+Shift+Down" = "move down";
        "${modifier}+Shift+Up" = "move up";
        "${modifier}+Shift+Right" = "move right";
        
        # Workspaces
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        
        # Move container to workspace
        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
      };

      # Startup applications
      startup = [
        {
          command = "${pkgs.polybar}/bin/polybar -r main";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.networkmanagerapplet}/bin/nm-applet";
          always = false;
          notification = false;
        }
        {
          command = "${pkgs.pasystray}/bin/pasystray";
          always = false;
          notification = false;
        }
      ];

      # Window assignments
      assigns = {
        "1" = [{ class = "^Firefox$"; }];
        "2" = [{ class = "^code$"; }];
      };

      # Bar settings (using polybar instead)
      bars = [];
    };
  };

  # Polybar configuration
  services.polybar = {
    enable = true;
    package = pkgs.polybar;
    script = ''
      polybar-msg cmd quit || true  # Terminate already running bars
      echo "---" | tee -a /tmp/polybar.log
      polybar main 2>&1 | tee -a /tmp/polybar.log & disown
    '';
    config = {
      "bar/main" = {
        monitor = "\${env:MONITOR:}";
        width = "100%";
        height = 27;
        radius = 0;
        fixed-center = true;
        
        background = "#282A2E";
        foreground = "#C5C8C6";
        
        padding-left = 2;
        padding-right = 2;
        
        module-margin-left = 1;
        module-margin-right = 1;
        
        font-0 = "FiraCode Nerd Font:size=10;2";
        font-1 = "Font Awesome 6 Free:style=Solid:size=10;2";
        font-2 = "Font Awesome 6 Brands:style=Regular:size=10;2";
        
        modules-left = "i3";
        modules-center = "date";
        modules-right = "memory cpu";
        
        tray-position = "right";
        tray-padding = 2;
        
        cursor-click = "pointer";
        cursor-scroll = "ns-resize";
      };
      
      "module/i3" = {
        type = "internal/i3";
        pin-workspaces = true;
        strip-wsnumbers = true;
        index-sort = true;
        enable-click = true;
        enable-scroll = false;
        wrapping-scroll = false;
        reverse-scroll = false;
        fuzzy-match = true;
        
        label-focused = "%index%";
        label-focused-background = "#383838";
        label-focused-underline = "#fba922";
        label-focused-padding = 2;
        
        label-unfocused = "%index%";
        label-unfocused-padding = 2;
        
        label-visible = "%index%";
        label-visible-padding = 2;
        
        label-urgent = "%index%";
        label-urgent-background = "#bd2c40";
        label-urgent-padding = 2;
      };
      
      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = " ";
        format-prefix-foreground = "#fba922";
        label = "%percentage:2%%";
      };
      
      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format-prefix = " ";
        format-prefix-foreground = "#fba922";
        label = "%percentage_used%%";
      };
      
      "module/date" = {
        type = "internal/date";
        interval = 5;
        
        date = "%Y-%m-%d";
        date-alt = "%Y-%m-%d";
        
        time = "%H:%M";
        time-alt = "%H:%M:%S";
        
        format-prefix = " ";
        format-prefix-foreground = "#fba922";
        
        label = "%date% %time%";
      };
    };
  };
}
