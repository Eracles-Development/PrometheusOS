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
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  # 1. Configuración de Cockpit
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

  systemd.services.cockpit.environment.COCKPIT_DATA_DIR = "/run/current-system/sw/share/cockpit";

  # 2. Motor de Virtualización (LA CORRECCIÓN)
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown"; 
    # Forzamos timeout 0 para que no se apague solo a los 2 minutos
    extraArgs = [ "--timeout" "0" ];
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # 3. Forzar persistencia del servicio en Systemd
  # Esto hace que libvirtd sea un servicio "normal" que no depende de sockets para despertar
  systemd.services.libvirtd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExitType = "cgroup";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    libvirt
    bridge-utils
  ];

  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" ];
  };
}