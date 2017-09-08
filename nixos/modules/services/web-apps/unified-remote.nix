{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.services.unified-remote;

in

{
  options = {
    services.unified-remote = {

      enable = mkEnableOption "Unified Remote Server";

      remotesPath = mkOption {
        type = types.str;
        default = "/var/lib/unified-remote/remotes";
        description = "Unified Remote remotes";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/unified-remote";
        description = "Path to the state dir";
      };

      tcpPorts = mkOption {
        type = types.listOf types.int;
        default = [ 9510 9511 9512 ];
        description = "TCP Ports the server listens on (opens firewall if necessary)";
      };

      udpPorts = mkOption {
        type = types.listOf types.int;
        default = [ 9511 ];
        description = "UDP Ports the server listens on (opens firewall if necessary)";
      };

      pkg = mkOption {
        type = types.package;
        default = pkgs.unified-remote;
        description = "The Unified Remote derivation to use";
      };

      user = mkOption {
        type = types.str;
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
        KERNEL="uinput", GROUP="${cfg.uinputGroup}"
      '';

      users.groups = builtins.listToAttrs [
        { name = cfg.uinputGroup; value = {}; }
      ];

      users.users."${cfg.user}".extraGroups = [ cfg.uinputGroup ];

      systemd.services.unified-remote = {
        enable = true;
        description = "Unified Remote server";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.unified-remote ];
        serviceConfig.User = cfg.user;
        serviceConfig.Type = "forking";
        serviceConfig.PIDFile = "${cfg.stateDir}/pid";
        script = ''
          if [[ ! -d "${cfg.remotesPath}" ]]; then
            mkdir -p "$(dirname ${cfg.remotesPath})"
            cp -r "${pkgs.unified-remote}/bin/remotes" "${cfg.remotesPath}"
          fi

          find "${cfg.remotesPath}" -type f -exec chmod 0640 '{}' \;

          mkdir -p ${cfg.stateDir}

          urserver \
            --daemon \
            --pidfile "${cfg.stateDir}"/pid \
            --remotes="${cfg.remotesPath}"
        '';
      };

    })

    (mkIf config.networking.firewall.enable {
      networking.firewall.allowedTCPPorts = cfg.tcpPorts;
      networking.firewall.allowedUDPPorts = cfg.udpPorts;
    })

    ];

}
