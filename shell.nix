with (import <nixpkgs> {});

mkShell {
  buildInputs = [ jekyll bundler ];
}

