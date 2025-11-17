# trdp

This repository packages the [TCNOpen TRDP stack](https://www.cooperationtool.eu/tcnopen/) and provides a
self-contained build that produces the static core library as well as the XML
and PD helper tools shipped upstream. The codebase is intentionally free from
the legacy xpact metadata that shipped with the original vendor drop; only the
standard `make` based workflow described below is required to build the
artifacts.

## Prerequisites

The build uses the system toolchain and relies on a couple of development
packages:

- A C compiler (e.g. `gcc`) and `pkg-config`
- `libxml2` headers and libraries (`libxml2-dev` on Debian/Ubuntu)
- `zlib` development files (`zlib1g-dev`)
- `libuuid` (`uuid-dev`)

The archive containing the upstream sources (`trdp-2.0.3.0.tar.gz`) already
lives at the root of the repository.

## Building

```sh
make        # builds libtrdp_core.a and the XML/PD test tools under build/
```

Running `make` automatically

1. Extracts the reference stack into `build/trdp/`
2. Applies every patch located in `patches/*.patch`
3. Compiles the library and helper executables under `build/lib` and `build/bin`

To force re-extraction/patching you can run:

```sh
make prepare
```

Additional useful targets:

- `make clean` – remove compiled objects and binaries
- `make distclean` – remove the entire `build/` directory, including the
  extracted TRDP tree

The helper script [`tools/prepare_sources.sh`](tools/prepare_sources.sh) is
responsible for keeping the unpacked tree in sync with the shipped tarball and
patch series.
