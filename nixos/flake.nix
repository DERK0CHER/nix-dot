 {                                                                                                                
    description = "NixOS system configuration";                                                                    
                                                                                                                   
    inputs = {                                                                                                     
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";                                                         
      hyprland = {                                                                                                 
        url = "github:hyprwm/Hyprland";                                                                            
        inputs.nixpkgs.follows = "nixpkgs";                                                                        
      };                                                                                                           
    };                                                                                                             
                                                                                                                   
    outputs = { self, nixpkgs, hyprland, ... }: {                                                                  
      nixosConfigurations.nix = nixpkgs.lib.nixosSystem {                                                          
        system = "x86_64-linux";                                                                                   
        modules = [                                                                                                
          hyprland.nixosModules.default                                                                            
          ./configuration.nix                                                                                      
        ];                                                                                                         
      };                                                                                                           
    };                                                                                                             
  }                                                                                                                
                                                                                                             
        
