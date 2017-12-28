# Import all config modules in the overlay that are ready for use
#
# You should be very careful about including config modules in this
# list. If you do, they should *alwayr* apply to *all* hosts that use
# the overlay.
#
# If that is not the case, the best approach is to define the
# configuration as a new module that defines configuration options the
# user can set to enable it.

{ config, pkgs, ... }:

{
  imports =
    [
    ];
}
