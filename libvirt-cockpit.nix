{ config, pkgs, lib, ... }:

{
  ###### Virtualización (libvirt + QEMU/KVM) ######
  virtualisation.libvirtd.enable = true;

  # Suele evitar problemas de permisos/compatibilidad con UIs
  virtualisation.libvirtd.qemu.runAsRoot = true;

  # (Opcional pero recomendado) soporte para TPM en VMs, etc.
  # virtualisation.libvirtd.qemu.swtpm.enable = true;

  ###### Cockpit (interfaz web) ######
  services.cockpit.enable = true;

  # Abre el puerto de Cockpit (9090) en el firewall automáticamente
  services.cockpit.openFirewall = true;

  # Aseguramos que openssl esté disponible para generar certificados
  environment.systemPackages = with pkgs; [
    cockpit
    openssl
    qemu
    libvirt
    virt-manager
  ];

  # Permitir acceso HTTP como fallback (imprescindible si falla TLS/HTTPS)
  services.cockpit.settings = {
    WebService = {
      AllowUnencrypted = true;
    };
  };

  # Servicio para generar automáticamente un certificado autofirmado si no existe
  systemd.services.create-cockpit-cert = {
    description = "Generate generic self-signed certificate for Cockpit";
    wantedBy = [ "multi-user.target" ];
    before = [ "cockpit.service" ];
    path = [ pkgs.openssl ];
    script = ''
      mkdir -p /etc/cockpit/ws-certs.d
      CERT_FILE=/etc/cockpit/ws-certs.d/01-self-signed.cert
      
      if [ ! -f "$CERT_FILE" ]; then
        echo "Generando certificado autofirmado para Cockpit..."
        openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
          -subj "/CN=nixos" \
          -keyout "$CERT_FILE" \
          -out "$CERT_FILE"
        # Permisos más abiertos para asegurar lectura (644) y ownership
        chmod 644 "$CERT_FILE"
        chown root:cockpit-ws "$CERT_FILE" || chown root:root "$CERT_FILE"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  ###### Permisos de usuario ######
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];

  ###### Red/firewall (si no usas openFirewall) ######
  # Si prefieres controlar el firewall a mano, comenta openFirewall y usa esto:
  # networking.firewall.allowedTCPPorts = [ 9090 ];

  ###### Arranque automático de libvirtd ######
  # Normalmente NixOS lo hace al habilitar libvirtd, pero lo dejamos explícito:
  systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];
}
