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

  ###### Paquetes (Cockpit + plugin de máquinas + herramientas) ######
  environment.systemPackages = with pkgs; [
    cockpit
    cockpit-machines
    qemu
    libvirt
    virt-manager  # opcional (GUI local). Puedes borrarlo si no lo quieres.
  ];

  ###### Permisos de usuario ######
  # Cambia "tuUsuario" por tu usuario real en NixOS.
  # IMPORTANTE: ese usuario debe existir en tu configuración.
  users.users.tuUsuario.extraGroups = [ "libvirtd" "kvm" ];

  ###### Red/firewall (si no usas openFirewall) ######
  # Si prefieres controlar el firewall a mano, comenta openFirewall y usa esto:
  # networking.firewall.allowedTCPPorts = [ 9090 ];

  ###### Arranque automático de libvirtd ######
  # Normalmente NixOS lo hace al habilitar libvirtd, pero lo dejamos explícito:
  systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];
}
