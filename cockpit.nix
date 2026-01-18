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
      # Cirugía de manifest para compatibilidad total
      sed -i '/"conditions": \[/,/ \],/d' $out/share/cockpit/machines/manifest.json
    '';
  };
in
{
  # 1. Cockpit: Inyección de Paquetes Extra
  services.cockpit = {
    enable = true;
    port = 9090;
    # Esto es vital: añadimos el plugin a la lista de paquetes que Cockpit escanea nativamente
    package = pkgs.cockpit.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        ln -s ${cockpit-machines-manual}/share/cockpit/machines $out/share/cockpit/machines
      '';
    });
  };

  # 2. Virtualización: Eliminación de Sockets Inactivos
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
    };
    # Configuración de comunicación IPC
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_rw_perms = "0770"
      auth_unix_rw = "none"
    '';
  };

  # 3. Systemd: Forzar Persistencia de Estado
  systemd.services.libvirtd = {
    path = [ pkgs.libvirt pkgs.qemu_kvm ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.mkForce [ "" "${pkgs.libvirt}/sbin/libvirtd --timeout 0" ];
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # 4. Seguridad: Polkit (La llave maestra)
  # Esto soluciona el "Permission Denied" y el fallo de descriptor
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

  # 5. Entorno de Sistema
  environment.systemPackages = with pkgs; [
    cockpit-machines-manual
    libvirt
    qemu_kvm
    bridge-utils
  ];

  # Aseguramos que el usuario tenga herencia de grupos correcta
  users.users.eracles = {
    isNormalUser = true;
    extraGroups = [ "libvirtd" "kvm" "wheel" "libvirt" "qemu-libvirtd" ];
  };
}