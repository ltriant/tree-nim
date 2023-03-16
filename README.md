## tree

An opinionated tree command with only the options, parameters, and defaults that I like.

## But why?

I originally wrote this because I needed/wanted a tree command, but I had no internet connection at my new home yet to install something like GNU tree, so I wrote my own for funsies.

## Build & Install

Requires the [Nim toolchain](https://nim-lang.org/) to build.

```
$ nimble build
```

This will build a `tree` executable. To install it to your Nimble directory (defaults to `~/.nimble/bin`):

```
$ nimble install
```
