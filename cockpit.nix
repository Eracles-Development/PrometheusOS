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

  # 2. Virtualización Libvirtd
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

  # 3. CORRECCIÓN DEL TIMEOUT VÍA SYSTEMD (Solución al error anterior)
  # En lugar de extraArgs, modificamos el comando de inicio del servicio directamente
  systemd.services.libvirtd = {
    wantedBy = [ "multi-user.target" ];
    # Sobrescribimos el comando para añadir el timeout 0
    serviceConfig.ExecStart = [
      "" # Esto limpia el comando original de NixOS
      "${pkgs.libvirt}/sbin/libvirtd --timeout 0"
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # 4. Paquetes y Usuarios
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