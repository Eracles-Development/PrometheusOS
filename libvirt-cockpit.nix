{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permitimos la IP y el nombre de host para evitar el rechazo de conexión
        # Si quieres ser menos estricto mientras pruebas, puedes comentar la línea de Origins
        Origins = lib.mkForce "https://eracles1:9090
        https://192.168.8.121:9090 http://192.168.8.121:9090
        https://192.168.8.122:9090 http://192.168.8.122:9090
        https://192.168.8.123:9090 http://192.168.8.123:9090";
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd.enable = true;
  
  # 3. Paquetes necesarios
  environment.systemPackages = [
    # pkgs.cockpit-machines  # Si sigue fallando, coméntalo para poder entrar al menos al dashboard base
    pkgs.virt-manager
    pkgs.libvirt
  ];

  # 4. Permisos y Firewall
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];
}