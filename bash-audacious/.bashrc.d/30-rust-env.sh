# Rust toolchain environment (installed via rustup)
# Adds ~/.cargo/bin to PATH for cargo, rustc, rust-analyzer, etc.

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
