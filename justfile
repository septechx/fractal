run:
  zig build
  env FRACTAL_CONFIG_OVERRIDE=example ./zig-out/bin/fractal testing

build:
  zig build -Doptimize=ReleaseSafe -Dstatic-glass

install PREFIX="/usr": build
  sudo install -D -m755 zig-out/bin/fractal {{PREFIX}}/bin/fractal

setup:
  rustup install nightly
  rustup default nightly
  zvm install 0.16.0 --zls
