{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # mkForce obliga al sistema a usar esta IP y evita el error de conflicto
        Origins = lib.mkForce "https://192.168.8.122:9090";
        AllowUnencrypted = true;
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd.enable = true;
  
  # 3. Paquetes necesarios
  environment.systemPackages = with pkgs; [
    cockpit
    cockpit-machines  # Para gestionar VMs desde la web
    virt-manager      # Interfaz gráfica (opcional)
    libvirt
  ];

  # 4. Permisos y Firewall
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];
}