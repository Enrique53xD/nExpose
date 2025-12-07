````markdown
# nExpose

A lightweight, high-performance alternative to ngrok. Instantly expose local files, videos, or websites to the internet using Cloudflare Tunnels and Miniserve.

![Shell](https://img.shields.io/badge/Shell-100%25-green) ![License](https://img.shields.io/badge/License-MIT-blue)

## Features

- **Zero Config:** Get a public URL instantly without signing up.
- **High Performance:** Uses Rust-based file serving and HTTP/2 tunneling.
- **Video Streaming:** Supports scrubbing/seeking for large video files (MKV/MP4).
- **Smart Mode:** Automatically detects if you are serving a static site (`index.html`) or a file browser.
- **Self-Healing:** Automatically detects and resolves port conflicts (kills zombie processes).

## Installation

Run this single command in your terminal to install nExpose:

```bash
curl -sL [https://raw.githubusercontent.com/Enrique53xD/nExpose/main/install.sh](https://raw.githubusercontent.com/Enrique53xD/nExpose/main/install.sh) | bash
````

## Usage

Navigate to any folder you want to share and run:

```bash
expose
```

By default, this runs on port **8080**. You can specify a custom port:

```bash
expose 3000
```

## How it works

1.  **Server:** It launches `miniserve` (a high-performance Rust server) locally to handle file serving and streaming.
2.  **Tunnel:** It launches `cloudflared` to create a secure outbound tunnel to the internet.
3.  **Cleanup:** It uses system traps (`trap`) to ensure all background processes are killed instantly when you close the terminal or press Ctrl+C.

## Custom Domain Setup (Optional)

By default, nExpose uses a random "Quick Tunnel" URL (e.g., `https://funny-name.trycloudflare.com`).

If you have a Cloudflare account and want to use your own domain (e.g., `dev.yourname.com`):

1.  Authenticate Cloudflare:
    ```bash
    cloudflared tunnel login
    ```
2.  Create a tunnel (replace `my-tunnel` with any name):
    ```bash
    cloudflared tunnel create my-tunnel
    ```
3.  Route your DNS to it:
    ```bash
    cloudflared tunnel route dns my-tunnel dev.yourname.com
    ```
4.  Edit the `expose` script installed on your machine and set the `TUNNEL_NAME` variable:
    ```bash
    # Inside the script:
    TUNNEL_NAME="my-tunnel"
    ```

## Requirements

The installer automatically checks for and installs these dependencies using Homebrew:

  * `cloudflared` (Cloudflare Tunnel Daemon)
  * `miniserve` (Rust File Server)

## License

This project is open source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

```
```
