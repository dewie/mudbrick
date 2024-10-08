{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs =
        nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = with pkgs; mkShell {
        packages = [
          elixir_1_17
          (elixir_ls.override { elixir = elixir_1_17; })
          inotify-tools
        ];

        shellHook = ''
          export ERL_AFLAGS="-kernel shell_history enabled shell_history_file_bytes 1024000"
        '';
      };
    };
}
