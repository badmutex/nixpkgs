import ./make-test.nix {
  name = "unified-remote";

  nodes = {
    server = { pkgs, ... }:
    {
      networking.firewall.enable = true;
      services.unified-remote.enable = true;
      services.unified-remote.openFirewall = true;
    };
    client = { pkgs, ... }:
    {
    };
  };

  testScript =
    let ports = { web = "9510"; client = "9512"; discovery = "9511"; };
    in
    ''
      $server->waitForUnit('unified-remote.service');
      $client->waitForUnit('multi-user.target');
      $client->succeed('nc -w 1 -z server ${ports.client}');
      $client->succeed('nc -w 1 -z server ${ports.web}');
      $client->succeed('nc -w 1 -z -u server ${ports.discovery}');
      $client->succeed('curl http://server:${ports.web}/web');
    '';
}
