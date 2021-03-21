# m

> lightweight wrapper around make

This program makes it easier to pass arguments to make targets
by sacrificing the ability to run multiple targets

## Setup

### Install

```
sudo make install
```

### Uninstall

```sh
sudo make uninstall
```

## Usage

```sh
m build --hello=world
```

this will end up running the following make command

```sh
make build ARGS="--hello=world"
```
