{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permitimos la IP y el nombre de host para evitar el rechazo de conexión
        # Si quieres ser menos estricto mientras pruebas, puedes comentar la línea de Origins
        Origins = lib.mkForce "https://192.168.8.122:9090 https://eracles1:9090
        https://192.168.8.122:9090 http://192.168.8.122:9090
        https://192.168.8.123:9090 http://192.168.8.123:9090";
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd.enable = true;
  
  # 3. Paquetes necesarios
  environment.systemPackages = with pkgs; [
    cockpit
    cockpit-machines
    cockpit-pcp
    virt-manager
    libvirt
    openssl
  ];

  # 4. Permisos y Firewall
  security.polkit.enable = true;
  networking.firewall.allowedTCPPorts = [ 9090 ];

  # 5. PCP (Performance Co-Pilot) para métricas históricas
  services.pmcd.enable = true;
  services.pmlogger.enable = true;
}