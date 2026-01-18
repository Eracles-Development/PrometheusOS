{ config, pkgs, lib, ... }:

let
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "328";
    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-HlmvnWoVnN3Ju9EomlcM6j3a0MoZzqZ9OXqQxkUT4qs="; 
    };
    nativeBuildInputs = [ pkgs.gettext pkgs.findutils pkgs.gnused ];
    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      SOURCE_DIR=$(find . -name manifest.json -exec dirname {} \; | head -n 1)
      cp -r $SOURCE_DIR/* $out/share/cockpit/machines/
      # Elimina condiciones que causan errores de compatibilidad en NixOS
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  # 1. Cockpit: Instalación limpia con el plugin de máquinas
  services.cockpit = {
    enable = true;
    port = 9090;
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
  };

  # 2. Virtualización: Habilita el demonio base
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = true;
  };

  # 3. POLKIT: La solución al "Permission Denied" y al cierre de sesión
  # Autoriza al grupo libvirtd a gestionar el socket de virtualización
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  # 4. Paquetes necesarios en el sistema
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    libvirt
    bridge-utils
  ];

  # 5. Grupos de usuario: Asegura que eracles tenga acceso
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" ];
  };
}