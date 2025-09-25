# cargo-lambda-repro

This repository reproduces a bug in the [cargo-lambda](https://github.com/cargo-lambda/cargo-lambda) crate where it automatically installs a missing compilation target but then fails with an error saying the target may not be installed.

## Bug Description

When running `cargo lambda build --release --arm64` in a fresh environment:

1. cargo-lambda detects that the `aarch64-unknown-linux-gnu` target is missing
2. It automatically installs the target (you can see this in the output)
3. However, it then fails with an error message suggesting the target may not be installed
4. The target is actually installed correctly, but cargo-lambda seems to have a race condition or caching issue

## Error Example

```
❯ cargo lambda build --release --arm64
>>>>> Installing target component 'aarch64-unknown-linux-gnu'...
>>>>> Target component installed
Updating crates.io index
Downloading crates ...

error[E0463]: can't find crate for `core`
  |
  = note: the `aarch64-unknown-linux-gnu` target may not be installed
  = help: consider downloading the target with `rustup target add aarch64-unknown-linux-gnu`

For more information about this error, try `rustc --explain E0463`.
error: could not compile `cfg-if` (lib) due to 1 previous error
[... more compilation errors ...]
Error: Process completed with exit code 101.
```

## Reproduction

### Method 1: GitHub Actions

The repository includes two GitHub Actions workflows:

- `.github/workflows/reproduce-bug.yml` - Basic reproduction case
- `.github/workflows/target-bug-test.yml` - More detailed test with multiple scenarios

### Method 2: Local Reproduction

1. Set up a fresh Rust environment or remove the ARM64 target:
   ```bash
   rustup target remove aarch64-unknown-linux-gnu
   ```

2. Ensure you have cargo-lambda and Zig installed:
   ```bash
   pip3 install cargo-lambda
   # Install Zig 0.13.0 or newer
   ```

3. Try to build for ARM64:
   ```bash
   cargo lambda build --release --arm64
   ```

4. Observe the error despite the target being automatically installed

## Expected Behavior

cargo-lambda should either:
1. Successfully use the target it just installed, OR
2. Properly handle the target installation timing/caching

## Workaround

Manually install the target first:
```bash
rustup target add aarch64-unknown-linux-gnu
cargo lambda build --release --arm64
```
