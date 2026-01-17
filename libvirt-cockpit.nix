{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        Origins = lib.mkForce "https://192.168.8.122:9090 https://eracles1:9090
        https://192.168.8.122:9090 http://192.168.8.122:9090
        https://192.168.8.123:9090 http://192.168.8.123:9090";
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.runAsRoot = true;
  
  # 3. Paquetes necesarios
  environment.systemPackages = with pkgs; [
    cockpit
    cockpit-machines
    cockpit-pcp
    virt-manager
    libvirt
    openssl
    pcp
  ];

  # 4. Permisos y Firewall
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # 5. Histórico de métricas con pmlogger
  systemd.services.pmlogger = {
    description = "PCP Performance Metric Logger";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.pcp}/bin/pmlogger -N -l /var/log/pcp/pmlogger/pmlogger.log /var/log/pcp/pmlogger/pmlogger";
      Restart = "on-failure";
    };
  };

  # Crear directorios necesarios para PCP
  systemd.tmpfiles.rules = [
    "d /var/log/pcp/pmlogger 0755 root root -"
  ];

  ###### Permisos de usuario ######
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];
}