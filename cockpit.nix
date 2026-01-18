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
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  # 1. Cockpit
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

  # 2. Virtualización
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_rw_perms = "0770"
      auth_unix_rw = "none"
    '';
  };

  # 3. Systemd: Forzar configuración para evitar conflictos
  systemd.services.libvirtd = {
    path = [ pkgs.libvirt pkgs.qemu_kvm ];
    wantedBy = [ "multi-user.target" ];
    
    # Usamos lib.mkForce en todo el bloque conflictivo
    serviceConfig = {
      ExecStart = lib.mkForce [ "" "${pkgs.libvirt}/sbin/libvirtd --timeout 0" ];
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce "2s";
    };
  };

  # 4. Polkit: Autorización total
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.libvirt.unix.manage" || 
           action.id.indexOf("org.cockpit-project.cockpit-bridge") !== -1) &&
          subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  # 5. Paquetes y Usuario
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    libvirt
    bridge-utils
  ];

  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" "qemu-libvirtd" ];
  };
}