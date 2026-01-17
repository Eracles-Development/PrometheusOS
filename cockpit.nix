{ config, pkgs, lib, ... }:

let
  # Definición manual desde GitHub
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
  # 1. Habilitar Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    
    # CORRECCIÓN AQUÍ: Forzamos la integración del paquete manual
    package = pkgs.cockpit.override {
      packageOverrides = {
        # Esto le dice a NixOS que incluya nuestro paquete manual en la ruta de Cockpit
        extraPackages = [ cockpit-machines-manual ];
      };
    };

    settings = {
      WebService = {
        Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090 http://localhost:9090";
      };
    };
  };

  # 2. Virtualización completa
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  # 3. Paquetes de apoyo
  # Añadimos virt-install porque cockpit-machines lo usa para crear las VMs
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    virt-viewer
    virt-install
    libvirt
    bridge-utils
  ];

  # 4. Permisos para tu usuario
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];
}