# fractal

A tmux session manager that creates and configures tmux layouts using [Glass](https://github.com/oxilang/glass) config files.

## Prerequisites

- [Zig](https://ziglang.org/) 0.16.0
- [Rust](https://www.rust-lang.org/) nightly (for the Glass parser submodule)
- [tmux](https://github.com/tmux/tmux)

## Compilation

```sh
git clone --recursive git@github.com:septechx/fractal
cd fractal
zig build -Doptimize=ReleaseSafe
```

The binary is placed at `zig-out/bin/fractal`. You will also need `libglass.so`, which is placed at `glass/target/release`.

If you prefer static linking, you can use the `-Dstatic-glass` flag to have `libglass.a` included in the executable instead.

## Usage

Create a layout file at `~/.config/fractal/<name>.glass`:

```
root {
    dir "~/projects/myapp/",
    windows [
        {
            cmd "",
        },
        {
            cmd "nvim",
        },
        {
            cmd "npm run dev",
        },
    ],
},
```

Then launch it:

```sh
fractal <name>
```

This creates a tmux session named `<name>` with the specified windows and runs the given commands in each.

### Configuration

Global config at `~/.config/fractal/config.glass`:

```
root {
    first_window_offset 0,
},
```

- `first_window_offset` — controls the starting window index (default `0`)

### Override config path

```sh
FRACTAL_CONFIG_OVERRIDE=/path/to/configs fractal mylayout
```

## License

MIT
