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

  # Permitir acceso HTTP sin restricciones para evitar problemas de certificados
  services.cockpit.settings = {
    WebService = {
      AllowUnencrypted = true;
    };
  };

  # LIMPIEZA: Eliminamos el certificado manual que causaba errores.
  # Cockpit generará uno temporal en memoria si es necesario, pero usaremos HTTP.
  systemd.services.clean-cockpit-cert = {
    description = "Remove problematic custom certificate";
    wantedBy = [ "multi-user.target" ];
    before = [ "cockpit.service" ];
    script = ''
      rm -f /etc/cockpit/ws-certs.d/01-self-signed.cert
    '';
    serviceConfig = {
      Type = "oneshot";
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
