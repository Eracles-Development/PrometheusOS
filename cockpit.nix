{ config, pkgs, lib, ... }:

let
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "331";

    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-x16eynAUoOqAw4FbbXus3+jus/HEnxFfXvyHkki5d2A="; 
    };

    nativeBuildInputs = [ pkgs.gettext pkgs.findutils ];

    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      SOURCE_DIR=$(find . -name manifest.json -exec dirname {} \; | head -n 1)
      if [ -n "$SOURCE_DIR" ]; then
        cp -r $SOURCE_DIR/* $out/share/cockpit/machines/
      else
        echo "ERROR: No se encontró manifest.json en el código fuente"
        exit 1
      fi
    '';
  };
in
{
  # 1. Configuración del Servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        extraPackages = [ cockpit-machines-manual ];
      };
    });
    settings = {
      WebService = {
        Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090";
      };
    };
  };

  # --- LA PIEZA CLAVE QUE FALTABA ---
  systemd.services.cockpit.environment.COCKPIT_DATA_DIR = "/run/current-system/sw/share/cockpit";
  # ----------------------------------

  # 2. Motor de Virtualización (Tu configuración original exacta)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # 3. Paquetes del sistema
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    virt-viewer
    libvirt
    bridge-utils
  ];

  # 4. Configuración de usuario (Corregida para evitar errores de rebuild)
  users.users.eracles = {
    isNormalUser = true; # Obligatorio para que NixOS acepte al usuario
    extraGroups = [ "libvirtd" "kvm" "wheel" ];
  };
}