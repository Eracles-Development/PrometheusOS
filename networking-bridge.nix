{ config, pkgs, ... }:

{
# en caso de ser ncesario como un controlador que no quiera funcionar bien con macvtap

networking.useDHCP = false;

systemd.network.enable = true;

systemd.network.netdevs."br0" = {
  netdevConfig = {
    Kind = "bridge";
    Name = "br0";
  };
  bridgeConfig = {
    STP = false;
  };
};

systemd.network.networks = {
  "eno1" = {
    matchConfig.Name = "eno1";
    networkConfig.Bridge = "br0";
  };

  "br0" = {
    matchConfig.Name = "br0";
    networkConfig = {
      DHCP = "yes";
    };
    linkConfig.MACAddress = "b0:0c:d1:7d:10:ea";
  };
};


}
