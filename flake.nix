{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-darwin"
        ]
          (system: function nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = with pkgs; mkShell {
          packages = [
            elixir_1_17
            (elixir_ls.override { elixir = elixir_1_17; })
            qpdf
          ]
          ++ lib.lists.optional stdenv.isLinux inotify-tools
          ++ lib.lists.optional stdenv.isDarwin darwin.apple_sdk.frameworks.CoreServices;

          shellHook = ''
            export ERL_AFLAGS="-kernel shell_history enabled shell_history_file_bytes 1024000"
            export FONT_LIBRE_BODONI_REGULAR="${libre-bodoni}/share/fonts/opentype/LibreBodoni-Regular.otf"
          '';
        };
      });
    };
}
