{ config, pkgs, lib, ... }:

let
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "331";

    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-x16eynAUoOqAw4FbbXus3+jus/HEnxFfXvyHkki5d2A="; 
    };

    nativeBuildInputs = [ pkgs.gettext ];

    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      cp -r * $out/share/cockpit/machines
    '';
  };
in
{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    
    # Esta es la forma correcta de inyectar el paquete en el servicio
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        extraPackages = [ cockpit-machines-manual ];
      };
    });

    settings = {
      WebService = {
        Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090 http://localhost:9090";
      };
    };
  };

  # 2. Virtualización
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # 3. Paquetes del sistema (Corregidos los nombres)
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager   # Este incluye virt-install internamente
    virt-viewer
    libvirt
    bridge-utils
  ];

  # 4. Permisos
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];
}