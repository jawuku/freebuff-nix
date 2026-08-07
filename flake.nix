{
  description = "FHS-compliant shell for running the freebuff CLI via npx";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # An FHS-compliant environment (real /usr, /lib, /etc, ...) in which
      # `npx freebuff` runs. This lets npm packages that ship prebuilt native
      # binaries or hardcode FHS paths work on NixOS and other Nix systems.
      freebuffEnv = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.buildFHSEnvBubblewrap {
          name = "freebuff";
          targetPkgs = p: with p; [
            nodejs
            cacert
            yarn
          ];
          profile = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          '';
          # `--yes` avoids npm's interactive "Ok to proceed?" prompt.
          # Arguments after `--` on the `nix run` command line are forwarded here.
          runScript = "npx --yes freebuff";
        };
    in
    {
      packages = forAllSystems (system: {
        default = freebuffEnv system;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/freebuff";
        };
      });
    };
}
