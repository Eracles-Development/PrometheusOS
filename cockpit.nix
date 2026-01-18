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
  # 1. Habilitar Cockpit con integración del Plugin
  services.cockpit = {
    enable = true;
    port = 9090;
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
  };

  # 2. Configuración Agresiva de Libvirtd
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
    # Estos permisos en el socket evitan el "Permission Denied" en Cockpit
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_rw_perms = "0770"
      auth_unix_rw = "none"
    '';
  };

  # 3. Forzar que libvirtd NO tenga timeout (Evita que la web se desconecte)
  systemd.services.libvirtd = {
    path = [ pkgs.libvirt pkgs.qemu_kvm ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      # El mkForce es obligatorio aquí para ganar a la config por defecto
      ExecStart = lib.mkForce [ "" "${pkgs.libvirt}/sbin/libvirtd --timeout 0" ];
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce "5s";
    };
  };

  # 4. Polkit: La llave maestra para el acceso administrativo en la web
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id.indexOf("org.libvirt") !== -1 || 
           action.id.indexOf("org.cockpit-project") !== -1) &&
          subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  # 5. Entorno de paquetes y grupos
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    libvirt
    bridge-utils
    virt-manager
  ];

  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" "qemu-libvirtd" ];
  };
}