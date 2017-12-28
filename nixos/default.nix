 # Import modules and configs from this overlay
 #
 # Both are structered as NixOS modules. The distinction is that
 # modules in the ./modules subdirectory should be actual modules that
 # define configuration parameters and take action based on their
 # values. Modules in the the ./config subdirectory just unconditionally
 # set configuration values of other modules.
 #
 # You should be very conservative about including unconditional
 # configuration modules. They should only be included in the overlay
 # if they *always* apply to *all* hosts that use the overlay. If they
 # only apply some of the time, write a true module that defines its
 # own configuration options and put it in the ./modules subdirectory,
 # which allows it to be enabled by settings in configuration.nix.

 { config, pkgs, ... }:

 {
   imports = [ (import ./modules)
               (import ./config)
             ];
 }
