{ config, pkgs, lib, ... }:

{
  ###### Virtualización (libvirt + QEMU/KVM) ######
  virtualisation.libvirtd.enable = true;

  # Suele evitar problemas de permisos/compatibilidad con UIs
  virtualisation.libvirtd.qemu.runAsRoot = true;

  # (Opcional pero recomendado) soporte para TPM en VMs, etc.
  # virtualisation.libvirtd.qemu.swtpm.enable = true;

  ###### Paquetes (Libvirt + Herramientas GUI) ######
  environment.systemPackages = with pkgs; [
    qemu
    libvirt
    virt-manager  # GUI necesaria para X11 Forwarding
    xorg.xauth    # Requerido para X11 Forwarding
  ];

  # Necesario para que virt-manager guarde su configuración
  programs.dconf.enable = true;

  ###### Permisos de usuario ######
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];

  # Configuración de los sockets de libvirt para que el usuario pueda conectar sin sudo
  virtualisation.libvirtd.extraConfig = ''
    unix_sock_group = "libvirtd"
    unix_sock_rw_perms = "0770"
  '';

  ###### Arranque automático de libvirtd ######
  systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];
}
