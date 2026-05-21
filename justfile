run:
  zig build
  env FRACTAL_CONFIG_OVERRIDE=config.glass ./zig-out/bin/fractal

setup:
  rustup install nightly
  rustup default nightly
  zvm install 0.16.0 --zls
