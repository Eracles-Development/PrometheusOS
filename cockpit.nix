{ config, pkgs, lib, ... }:

{
  # Habilitar servicio Cockpit
  services.cockpit = {
    enable = true;
    port = 9090;
    
    # FORMA CORRECTA PARA NIXOS 24.11:
    # Usamos symlinkJoin para "unir" el cockpit base con sus módulos
    package = pkgs.symlinkJoin {
      name = "cockpit-with-plugins";
      paths = [
        pkgs.cockpit        # El núcleo de Cockpit
        pkgs.cockpit-machines # El módulo de VMs
      ];
      # Esto asegura que el binario principal sea el que se ejecute
      postBuild = ''
        mkdir -p $out/share/cockpit
        ln -snf ${pkgs.cockpit}/share/cockpit/* $out/share/cockpit/
        ln -snf ${pkgs.cockpit-machines}/share/cockpit/* $out/share/cockpit/
      '';
    };

    settings = {
      WebService = {
        # Corregido el string para evitar saltos de línea accidentales
        Origins = "https://192.168.8.123:9090 http://192.168.8.123:9090 http://localhost:9090";
      };
    };
  };

  # ... resto de tu configuración de libvirtd igual ...
  # Asegúrate de mantener la virtualización y los grupos de usuario
  virtualisation.libvirtd.enable = true;
  users.users.eracles.extraGroups = [ "libvirtd" "kvm" ];

  environment.systemPackages = with pkgs; [
    qemu
    libvirt
    virt-manager 
    xorg.xauth
  ];
}