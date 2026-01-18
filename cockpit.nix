{ config, pkgs, lib, ... }:

let
  # 1. Definición del paquete manual
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "331";

    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      # Este es el hash que te funcionó en el paso anterior
      sha256 = "sha256-x16eynAUoOqAw4FbbXus3+jus/HEnxFfXvyHkki5d2A="; 
    };

    # Necesitamos estas utilidades para mover los archivos correctamente
    nativeBuildInputs = [ pkgs.gettext pkgs.findutils ];

    # CORRECCIÓN DEFINITIVA: 
    # Buscamos el manifest.json y movemos todo su contenido al nivel superior
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
  # 2. Configuración del Servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    
    # Inyectamos el paquete manual en el bridge de Cockpit
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

  # 3. Motor de Virtualización (Libvirt)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # 4. Paquetes del sistema (Sin el error de virt-install)
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    virt-viewer
    libvirt
    bridge-utils
  ];

  # 5. Permisos de usuario
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];
}