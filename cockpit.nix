{ config, pkgs, lib, ... }:

let
  # Definimos el paquete manualmente usando el link de GitHub
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "331"; # Coincide con tu versión de Cockpit

    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      # Si el hash falla, cámbialo por lib.fakeSha256 y copia el que te pida Nix
      sha256 = "sha256-Hc3M4JB+RHzABIKRQtvD4SyErh4CbY2ZV69lLerZDvw="; 
    };

    nativeBuildInputs = [ pkgs.gettext ];

    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      cp -r * $out/share/cockpit/machines
    '';
  };
in
{
  # 1. Habilitar Cockpit y añadir el paquete manual
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
        # Asegúrate de que esto sea una sola línea sin saltos extraños
        Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090 http://localhost:9090";
      };
    };
  };

  # 2. Virtualización (Necesaria para que las máquinas funcionen)
  virtualisation.libvirtd.enable = true;
  
  # 3. Paquetes de apoyo
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    libvirt
  ];

  # 4. Permisos para tu usuario
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];
}