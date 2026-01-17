{ config, pkgs, lib, ... }:

{
  # Habilitar servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    
    # Esta es la forma más limpia y robusta para 24.11
    # Combinamos el paquete base con el plugin de máquinas
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        # Esto le dice a Cockpit dónde buscar módulos extra
        extraPackages = [ pkgs.cockpit-machines ];
      };
    });

    settings = {
      WebService = {
        Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090 http://localhost:9090";
      };
    };
  };

  # Virtualización y Libvirtd
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = true;
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };
  
  # Aseguramos que el usuario tenga los permisos necesarios
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];

  # Añadimos los paquetes necesarios al sistema
  environment.systemPackages = with pkgs; [
    cockpit-machines # Lo intentamos añadir aquí también para asegurar visibilidad
    qemu
    libvirt
    virt-manager 
  ];
}