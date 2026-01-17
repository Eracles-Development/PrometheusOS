{ config, pkgs, ... }:

{
  # Habilitar libvirt para virtualización
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;       # Para soporte TPM (necesario para Windows 11)
      ovmf.enable = true;        # Para soporte UEFI
      ovmf.packages = [ pkgs.OVMFFull.fd ];  # Imágenes OVMF completas
    };
    onBoot = "ignore";           # No iniciar VMs al arrancar el host
    onShutdown = "shutdown";     # Apagar VMs al apagar el host
    extraOptions = [
      "--verbose"
    ];
  };

  # Habilitar Cockpit con el módulo de máquinas virtuales
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;  # Abre automáticamente el puerto 9090
    package = pkgs.cockpit.override {
      extraPackages = with pkgs; [
        cockpit-machines    # Para gestión de VMs
        cockpit-podman      # Para gestión de contenedores (opcional)
        cockpit-networkmanager  # Para gestión de red
        cockpit-storaged    # Para gestión de almacenamiento
      ];
    };
    settings = {
      WebService = {
        Origins = "https://eracles1:9090 http://localhost:9090 http://eracles1:9090";
        ProtocolHeader = "X-Forwarded-Proto";
        AllowUnencrypted = false;
      };
    };
  };

  # Añadir los grupos necesarios
  users.groups.libvirtd = {};
  users.groups.kvm = {};

  # Añadir el usuario eracles a los grupos de virtualización
  users.users.eracles.extraGroups = [
    "libvirtd"
    "kvm" 
    "qemu-libvirtd"
    "disk"  # Para acceso a discos
  ];

  # Polkit rules para permitir gestión de VMs sin contraseña
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.libvirt.unix.manage" ||
             action.id == "org.libvirt.unix.monitor") &&
            subject.isInGroup("libvirtd")) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  # Paquetes específicos para virtualización
  environment.systemPackages = with pkgs; [
    # Herramientas de virtualización
    virt-manager
    virt-viewer
    virt-install
    libvirt
    qemu_kvm
    qemu-utils
    ovmf
    swtpm
    
    # Herramientas de red para VMs
    bridge-utils
    dnsmasq
    iptables
    
    # Herramientas de Cockpit
    cockpit-client
    
    # Herramientas de almacenamiento
    gparted
    ntfs3g
  ];

  # Configurar red para libvirt (bridge por defecto)
  virtualisation.libvirtd.networks = {
    default = {
      address = "192.168.122.0/24";
      dhcp = {
        start = "192.168.122.2";
        end = "192.168.122.254";
      };
      domain = "local";
      enable = true;
      localOnly = true;
    };
  };

  # Habilitar anfitrión QEMU
  virtualisation.libvirtd.qemu.runAsRoot = true;

  # Soporte para passthrough de GPU (opcional)
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:1c03,10de:10f1"  # Ejemplo para NVIDIA GPU
  ];

  # Configuración de cgroups v2 para compatibilidad
  systemd.enableUnifiedCgroupHierarchy = true;
}