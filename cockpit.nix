{ config, pkgs, lib, ... }:

let
  cockpit-machines = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "346";
    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-Hc3M4JB+RHzABIKRQtvD4SyErh4CbY2ZV69lLerZDvw=";
    };
    buildPhase = ":"; 
    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      cp -r * $out/share/cockpit/machines/
    '';
  };
in
{
  # Habilitar servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permitir acceso desde la red local
        # Permitir acceso desde la red local y hostname
        Origins = lib.mkForce ''https://eracles1:9090 https://192.168.8.121:9090 http://192.168.8.121:9090 localhost:9090 https://192.168.8.122:9090 http://192.168.8.122:9090 https://192.168.8.123:9090 http://192.168.8.123:9090'';
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # Abrir puerto en el firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # Polkit necesario para acciones privilegiadas sin root directo
  security.polkit.enable = true;

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
    cockpit-machines # Paquete definido arriba
    qemu
    libvirt
    virt-manager 
    xorg.xauth
  ];
}
