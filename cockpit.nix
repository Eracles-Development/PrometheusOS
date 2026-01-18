{ config, pkgs, lib, ... }:

let
  # Bajamos a la versión 328 para evitar el error de asyncio/dbus de la 331
  cockpit-machines-manual = pkgs.stdenv.mkDerivation rec {
    pname = "cockpit-machines";
    version = "328";
    src = pkgs.fetchzip {
      url = "https://github.com/cockpit-project/cockpit-machines/releases/download/${version}/cockpit-machines-${version}.tar.xz";
      sha256 = "sha256-kK7M9h2V5p1pLhW7WbS9qO1D/jV6Wk6Yl+f5S/GvX8U="; # Hash para v328
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
  # 1. Cockpit Service
  services.cockpit = {
    enable = true;
    port = 9090;
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
  };

  # 2. Variable de entorno para estabilidad
  systemd.services.cockpit.environment = {
    COCKPIT_DATA_DIR = "/run/current-system/sw/share/cockpit";
    PYTHONPATH = "${pkgs.python3}/lib/python3.12/site-packages";
  };

  # 3. Libvirtd sin timeout y persistente
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  systemd.services.libvirtd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.mkForce [ "" "${pkgs.libvirt}/sbin/libvirtd --timeout 0" ];
      Restart = lib.mkForce "always";
    };
  };

  # 4. Reglas de Polkit para evitar el "Permission Denied" anterior
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

  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" ];
  };
}