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
      
      # --- LA CORRECCIÓN CLAVE ---
      # Borramos la sección de "conditions" que busca rutas de Ubuntu/RedHat que en NixOS no existen
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  services.cockpit = {
    enable = true;
    port = 9090;
    # Inyectamos el paquete modificado directamente en Cockpit
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
    settings.WebService.Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090";
  };

  # Variable de entorno para asegurar que el bridge mire donde debe
  systemd.services.cockpit.environment.COCKPIT_DATA_DIR = "/run/current-system/sw/share/cockpit";

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    libvirt
  ];

  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" ];
  };
}