{ config, pkgs, ... }:

{
  # 1. Habilitar el servicio de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090; # Puerto por defecto
    settings = {
      WebService = {
        # Esto permite conexiones si estás usando una IP directamente
        AllowUnencrypted = true; 
        # Opcional: Si quieres evitar problemas estrictos de certificados en local
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Abrir los puertos necesarios en el Firewall
  # Cockpit usa el puerto 9090 por defecto, NO el 443.
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # 3. (Opcional) Asegurarte de tener herramientas de red instaladas
  environment.systemPackages = with pkgs; [
    cockpit
  ];
}