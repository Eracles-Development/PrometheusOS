{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # He ajustado las IPs para que coincidan con tu captura (.122) y el resto de tu red
        Origins = lib.mkForce "https://eracles1:9090 https://127.0.0.1:9090 https://192.168.8.121:9090 https://192.168.8.122:9090 https://192.168.8.123:9090";
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      swtpm.enable = true;
    };
  };

  # 3. Paquetes necesarios
  environment.systemPackages = [
    pkgs.cockpit-machines
    pkgs.virt-manager
    pkgs.libvirt
    pkgs.packagekit
  ];

  # 4. Solución al "Limited Access" y permisos de Virtualización
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, user) {
        if (action.id == "org.libvirt.unix.manage" &&
            user.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';

  programs.dconf.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];
}