{ config, pkgs, lib, ... }:

{
  ###### Virtualización (libvirt + QEMU/KVM) ######
  virtualisation.libvirtd.enable = true;

  # Suele evitar problemas de permisos/compatibilidad con UIs
  virtualisation.libvirtd.qemu.runAsRoot = true;

  # (Opcional pero recomendado) soporte para TPM en VMs, etc.
  # virtualisation.libvirtd.qemu.swtpm.enable = true;

  ###### Cockpit (interfaz web) ######
  services.cockpit.enable = true;

  # Abre el puerto de Cockpit (9090) en el firewall automáticamente
  services.cockpit.openFirewall = true;

  # Aseguramos que openssl esté disponible para generar certificados
  environment.systemPackages = with pkgs; [
    cockpit
    openssl
    qemu
    libvirt
    virt-manager
  ];

  # Limpiar certificados corruptos antes de que Cockpit inicie
  systemd.services.cockpit-cleanup-certs = {
    description = "Clean corrupted Cockpit certificates";
    before = [ "cockpit.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      rm -rf /etc/cockpit/ws-certs.d/*
      mkdir -p /etc/cockpit/ws-certs.d
    '';
  };

  ###### Permisos de usuario ######
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];

  ###### Red/firewall (si no usas openFirewall) ######
  # Si prefieres controlar el firewall a mano, comenta openFirewall y usa esto:
  # networking.firewall.allowedTCPPorts = [ 9090 ];

  ###### Arranque automático de libvirtd ######
  systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];
}