{ config, pkgs, ... }:

{
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permite conexiones desde tu IP específica
        # Debes incluir tanto el protocolo como el puerto
        Origins = "https://192.168.8.122:9090";
        
        # Esto ayuda a evitar problemas con los protocolos de handshake
        AllowUnencrypted = true;
      };
    };
  };

  # Importante: Asegúrate de que polkit esté activo
  security.polkit.enable = true;

  # Abrir puerto
  networking.firewall.allowedTCPPorts = [ 9090 ];
}