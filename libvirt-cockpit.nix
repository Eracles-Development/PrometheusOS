{ config, pkgs, lib, ... }:

{
  # 1. Configuración de Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Permitimos todas las IPs locales posibles para evitar bloqueos de origen (CSRF)
        Origins = lib.mkForce "https://eracles1:9090 https://127.0.0.1:9090 https://192.168.8.121:9090 https://192.168.8.122:9090 https://192.168.8.123:9090";
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # 2. Configuración de Virtualización (Libvirt)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      swtpm.enable = true;
    };
  };

  # 3. Paquetes necesarios
  # Usamos 'cockpit-machines' directamente. Si falla el build, lee la nota abajo.
  environment.systemPackages = with pkgs; [
    cockpit-machines   # Plugin para ver la pestaña "Virtual Machines"
    virt-manager       # Interfaz gráfica (opcional)
    libvirt            # Herramientas de control
    packagekit         # Ayuda a Cockpit con permisos y actualizaciones
  ];

  # 4. Solución al "Limited Access" y permisos de Virtualización
  # Esto permite que los usuarios del grupo 'wheel' manejen VMs sin que pida password siempre
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, user) {
        if (action.id == "org.libvirt.unix.manage" &&
            user.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';

  # Necesario para que Cockpit y virt-manager guarden preferencias
  programs.dconf.enable = true;

  # Firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];
}