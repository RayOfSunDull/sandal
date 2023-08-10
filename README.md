# Simple file syncer

``sandal`` is a simple file sync/backup utility for Linux (though in principle it should work when compiled for any OS). As it stands, it's just a slightly more configurable ``cp``. More capabilities will probably be added in the future.

## Installation
You may install the precompiled binary:
```sh
$ git clone https://github.com/RayOfSunDull/sandal
$ mv sandal/bin/sandal ~/bin/sandal
$ rm -rf sandal
```
Or compile it using the [nim](https://nim-lang.org/) compiler:
```sh
$ git clone https://github.com/RayOfSunDull/sandal
$ cd sandal
$ make
```

## Usage
The basic usage is as follows:
```
$ sandal input_dir output_dir
```
This just works like ``cp``, but can be configured using a json file such as the ones in `sandal/examples`. It supports simple glob patterns, as well as a special "`@`" pattern. 

In short, `@/some_path` will omit the latest directory in `@` if `@/some_path` exists. The motivation for this was to allow for the general exclusion of Python venvs. Refer to `sandal/examples/ignore_venvs.json`

After having created some `sandal.json` file, you may use it through:

```
$ sandal input_dir output_dir --config=sandal.json
```