{
  description = "Advent of Code 2025 in Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            zls
          ];

          shellHook = ''
            echo "Advent of Code 2025 - Zig Development Environment"
            echo "Zig version: $(zig version)"
            echo ""
            echo "Available commands:"
            echo "  zig build run -- <day>   Run a solution"
            echo "  zig build new -- <day>   Create new day"
            echo "  zig build fetch -- <day> Get input instructions"
            echo "  zig build test           Run tests"
          '';
        };
      }
    );
}
