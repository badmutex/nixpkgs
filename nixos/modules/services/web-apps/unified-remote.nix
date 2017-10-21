{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.services.unified-remote;
  remotesPath = "${cfg.stateDir}/remotes";

in

{
  options = {
    services.unified-remote = {

      enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to enable Unified Remote Server

            NOTE that this is fairly useless without setting the openFirewall flag.
            Example usage:

            <code>
            services.unified-remote = { enable = true; openFirewall = true; }
            </code>
        '';
      };

      stateDir = mkOption {
        type = types.path;
        default = "/var/lib/unified-remote";
        description = "Path to the state dir";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open the firewall. This should be set else Unified Remote cannot be used.";
      };

      remotesPort = mkOption {
        type = types.int;
        default = 9512;
        description = "TCP port to access the remotes. (Only affects the firewall; does not configure UR)";
      };

      discoveryPort = mkOption {
        type = types.int;
        default = 9511;
        description = "UDP port for autodiscovery. (Only affects the firewall; does not configure UR)";
      };

      webPort = mkOption {
        type = types.int;
        default = 9510;
        description = "TCP port the GUI runs on. (Only affects the firewall; does not configure UR)";
      };

      pkg = mkOption {
        type = types.package;
        default = pkgs.unified-remote;
        description = "The Unified Remote derivation to use";
      };

      user = mkOption {
        type = types.str;
        default = "unified-remote";
        description = "<emphasis>required</emphasis> The user to run Unified Remote as.";
      };

      uinputGroup = mkOption {
        type = types.str;
        default = "uinput";
        description = "The group to enable access to /dev/uinput";
      };

    };
  };

  config = mkMerge [

    (mkIf cfg.enable {
      boot.kernelModules = [ "uinput" ];

      services.udev.extraRules = ''
        KERNEL=="uinput", GROUP="${cfg.uinputGroup}", MODE="0660", TAG+="unified-remote"
      '';

      users.users."${cfg.user}" = {
        extraGroups = [ cfg.uinputGroup ];
        isSystemUser = true;
        home = cfg.stateDir;
        createHome = true;
      };

      users.groups = builtins.listToAttrs [
        { name = cfg.uinputGroup; value = {}; }
      ];

      systemd.services.unified-remote = {
        enable = true;
        description = "Unified Remote server";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.unified-remote pkgs.rsync ];
        serviceConfig.User = cfg.user;
        serviceConfig.Type = "forking";
        serviceConfig.PIDFile = "${cfg.stateDir}/pid";
        script = ''
          rsync --chmod=D0700,F0600 -r --delete "${pkgs.unified-remote}/bin/remotes/" "${remotesPath}"
          urserver \
            --daemon \
            --pidfile "${cfg.stateDir}"/pid \
            --remotes "${remotesPath}"
        '';
      };

    })

    (mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [ cfg.remotesPort cfg.webPort ];
      networking.firewall.allowedUDPPorts = [ cfg.remotesPort cfg.discoveryPort ];
    })

    ];

}
