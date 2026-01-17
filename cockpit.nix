{ config, pkgs, lib, ... }:

{
  # Habilitar servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permitir acceso desde la red local
        Origins = lib.mkForce "https://192.168.8.121:9090 http://192.168.8.121:9090 localhost:9090";
      };
    };
  };

  # Abrir puerto en el firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # Instalar plugin para manejar máquinas virtuales
  environment.systemPackages = with pkgs; [
    cockpit-machines
  ];
}
