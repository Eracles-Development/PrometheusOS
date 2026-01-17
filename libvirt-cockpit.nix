{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        Origins = lib.mkForce "https://eracles1:9090 https://127.0.0.1:9090 https://192.168.8.121:9090 https://192.168.8.122:9090 https://192.168.8.123:9090";
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Configuración de Virtualización
  virtualisation.libvirtd.enable = true;

  # 3. Paquetes con "Red de Seguridad"
  environment.systemPackages = with pkgs; [
    virt-manager
    libvirt
    packagekit
  ] 
  # Esta línea intenta instalar cockpit-machines solo si el sistema lo encuentra
  ++ (if pkgs ? cockpit-machines then [ pkgs.cockpit-machines ] else [ ])
  # Por si acaso ha cambiado de lugar a cockpitPackages
  ++ (if pkgs ? cockpitPackages.machines then [ pkgs.cockpitPackages.machines ] else [ ]);

  # 4. Permisos de administración
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