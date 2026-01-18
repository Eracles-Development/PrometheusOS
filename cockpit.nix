{ config, pkgs, lib, ... }:

let
  # Bajamos el binario ya compilado para no tener que construir nada
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "328";
    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-HlmvnWoVnN3Ju9EomlcM6j3a0MoZzqZ9OXqQxkUT4qs="; 
    };
    # No compilamos nada, solo copiamos
    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      cp -r * $out/share/cockpit/machines/
    '';
  };
in
{
  services.cockpit = {
    enable = true;
    port = 9090;
    # QUITAMOS el overrideAttrs que forzaba la compilación pesada
  };

  # Usamos esto para enlazar el plugin sin reconstruir Cockpit
  systemd.tmpfiles.rules = [
    "L+ /run/current-system/sw/share/cockpit/machines - - - - ${cockpit-machines-manual}/share/cockpit/machines"
  ];

  virtualisation.libvirtd.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    virt-manager
    libvirt
  ];

  users.users.eracles.extraGroups = [ "libvirtd" "kvm" "libvirt" ];
}