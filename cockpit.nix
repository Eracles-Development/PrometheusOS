{ config, pkgs, lib, ... }:

let
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "331";
    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-x16eynAUoOqAw4FbbXus3+jus/HEnxFfXvyHkki5d2A="; 
    };
    nativeBuildInputs = [ pkgs.gettext pkgs.findutils pkgs.gnused ];

    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      SOURCE_DIR=$(find . -name manifest.json -exec dirname {} \; | head -n 1)
      cp -r $SOURCE_DIR/* $out/share/cockpit/machines/
      
      # Eliminamos las condiciones de rutas fijas que no existen en NixOS
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  # 1. Servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
    settings.WebService.Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090";
  };

  # Variable para que Cockpit encuentre los paquetes en el sistema
  systemd.services.cockpit.environment.COCKPIT_DATA_DIR = "/run/current-system/sw/share/cockpit";

  # 2. Virtualización Libvirtd (CORRECCIÓN DE PERSISTENCIA)
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown"; 
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # Forzamos que libvirtd NO se desactive por inactividad (evita el cierre de sesión)
  systemd.services.libvirtd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExitType = "cgroup";
  };
  systemd.sockets.libvirtd.wantedBy = [ "sockets.target" ];

  # 3. Paquetes del sistema
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    virt-viewer
    libvirt
    bridge-utils
  ];

  # 4. Usuario con todos los grupos necesarios para gestionar VMs
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" "qemu-libvirtd" ];
  };
}