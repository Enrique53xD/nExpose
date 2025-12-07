# nExpose

A lightweight, high-performance alternative to ngrok. Instantly expose local files, videos, or websites to the internet using Cloudflare Tunnels and Miniserve.

## Features

- **Zero Config:** Get a public URL instantly without signing up.
- **High Performance:** Uses Rust-based file serving and HTTP/2 tunneling.
- **Video Streaming:** Supports scrubbing/seeking for large video files (MKV/MP4).
- **Smart Mode:** Automatically detects if you are serving a static site (`index.html`) or a file browser.
- **Self-Healing:** Automatically detects and resolves port conflicts.

## Installation

Run this command in your terminal:

```bash
curl -sL [https://raw.githubusercontent.com/enrique53xd/expose/main/install.sh](https://raw.githubusercontent.com/enrique53xd/expose/main/install.sh) | bash
