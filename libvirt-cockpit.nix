{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # mkForce es obligatorio para evitar el conflicto con el default
        Origins = lib.mkForce "https://192.168.8.122:9090";
        AllowUnencrypted = true;
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd.enable = true;
  
  # 3. Paquetes necesarios (Cambiado para evitar errores de variable)
  environment.systemPackages = [
    pkgs.cockpit
    pkgs.cockpit-machines  # Referencia directa al paquete
    pkgs.virt-manager
    pkgs.libvirt
  ];

  # 4. Permisos y Firewall
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];
}