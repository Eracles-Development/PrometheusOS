{ config, pkgs, ... }:

{
  # Habilitar Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permite que la negociación TLS sea más flexible
        AllowUnencrypted = true;
      };
    };
  };

  # Abrir el puerto en el firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # IMPORTANTE: Cockpit a veces necesita polkit para funcionar correctamente
  security.polkit.enable = true;

  # Opcional: Asegúrate de tener instalados los paquetes base
  environment.systemPackages = with pkgs; [
    cockpit
  ];
}