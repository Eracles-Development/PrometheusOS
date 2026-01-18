{ config, pkgs, ... }:

{
  # =========================================================================
  # CONFIGURACIÓN DE BRIDGE DE RED (MODO IP ESTÁTICA)
  # =========================================================================
  #
  # IMPORTANTE: Antes de activar esta configuración:
  # 1. Ejecuta `ip a` y verifica el nombre de tu interfaz física.
  # 2. Ejecuta `ip route` para ver tu Gateway (puerta de enlace) actual.
  # 3. Rellena los valores marcados con <---
  #
  # =========================================================================

  networking.bridges = {
    "br0" = {
      interfaces = [ "enp3s0" ]; # <--- 1. VERIFICAR NOMBRE INTERFAZ FÍSICA
      rstp = false; # Evita retardos del Spanning Tree Protocol
    };
  };

  # Desactivamos DHCP en el puente porque usaremos IP Estática
  networking.interfaces.br0.useDHCP = false;

  # Configuración de IP Fija (Recomendado para Servers/Kubernetes)
  networking.interfaces.br0.ipv4.addresses = [ {
    address = "192.168.1.50";     # <--- 2. TU IP DESEADA (Debe ser única en la red)
    prefixLength = 24;            # <--- 24 equivale a máscara 255.255.255.0
  } ];

  # Puerta de Enlace (Tu Router)
  networking.defaultGateway = "192.168.1.1"; # <--- 3. IP DE TU ROUTER

  # Servidores DNS (Google y Cloudflare como ejemplo)
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  # ---------------------------------------------------------------------
  # Interfaz Física: Se queda "muda", solo pasa paquetes al puente
  # ---------------------------------------------------------------------
  networking.interfaces.enp3s0.useDHCP = false; # <--- 4. VERIFICAR NOMBRE AQUÍ TAMBIÉN

}
