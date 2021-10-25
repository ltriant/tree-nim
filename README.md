## tree

An opinionated tree command with only the options, parameters, and defaults that I like.

I originally wrote this because I needed a tree command, and had no internet connection at my home yet to install an existing one. The first version was written in C, but that's now deprecated for this version.

## Build & Install

Requires the [Nim toolchain](https://nim-lang.org/) to build.

```
$ nimble build
```

This will build a `tree` executable. To install it to your Nimble directory (defaults to `~/.nimble/bin`):

```
$ nimble install
```
