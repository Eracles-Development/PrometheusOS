{ config, pkgs, lib, ... }:

{
  # Habilitar servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permitir acceso desde la red local
        Origins = lib.mkForce "https://192.168.8.121:9090 http://192.168.8.121:9090 localhost:9090";
      };
    };
  };

  # Abrir puerto en el firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # Virtualización (libvirt + QEMU/KVM)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = true;
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
      ovmf.enable = true;
    };
    # Configuración de los sockets de libvirt para que el usuario pueda conectar sin sudo
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_rw_perms = "0770"
    '';
  };
  
  # Arranque automático de libvirtd
  systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];

  # Necesario para que virt-manager guarde su configuración
  programs.dconf.enable = true;
  
  # Permisos de usuario (Ajusta 'eracles' si tu usuario es diferente, o muévelo a configuration.nix si prefieres)
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];

  # Paquetes del sistema para virtualización y Cockpit
  environment.systemPackages = with pkgs; [
    # cockpit-machines # Comentado temporalmente por error 'undefined variable'
    qemu
    libvirt
    virt-manager 
    xorg.xauth
  ];
}
