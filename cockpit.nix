{ config, pkgs, lib, ... }:

let
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "328";
    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      # HASH CORREGIDO SEGÚN TU ERROR:
      sha256 = "sha256-HlmvnWoVnN3Ju9EomlcM6j3a0MoZzqZ9OXqQxkUT4qs="; 
    };
    nativeBuildInputs = [ pkgs.gettext pkgs.findutils pkgs.gnused ];

    installPhase = ''
      mkdir -p $out/share/cockpit/machines
      SOURCE_DIR=$(find . -name manifest.json -exec dirname {} \; | head -n 1)
      cp -r $SOURCE_DIR/* $out/share/cockpit/machines/
      # Limpiamos condiciones incompatibles con NixOS
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  # 1. Cockpit y su visibilidad
  services.cockpit = {
    enable = true;
    port = 9090;
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        extraPackages = [ cockpit-machines-manual ];
      };
      # Unimos el plugin al paquete principal
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
    settings.WebService.Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090";
  };

  # Variable crítica para que el bridge encuentre los archivos
  systemd.services.cockpit.environment.COCKPIT_DATA_DIR = "/run/current-system/sw/share/cockpit";

  # 2. Virtualización Libvirtd (Configuración Robusta)
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
    # Permisos de socket para evitar el error de descriptor/permisos
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_rw_perms = "0770"
      auth_unix_rw = "none"
    '';
  };

  # 3. Forzar persistencia y timeout 0
  systemd.services.libvirtd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.mkForce [ "" "${pkgs.libvirt}/sbin/libvirtd --timeout 0" ];
      Restart = lib.mkForce "always";
      RestartSec = "5s";
    };
  };

  # 4. Reglas de Polkit para autorizar a Cockpit
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  # 5. Paquetes y Usuario
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