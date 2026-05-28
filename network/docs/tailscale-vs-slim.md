# Tailscale vs Slim

Slim and Tailscale solve different parts of the network story.

## Slim

Use Slim for local developer ergonomics:

- stable local names
- local HTTPS routing
- local proxying from domains to ports
- browser-friendly service surfaces

Example: `https://workspace.test` routes to `http://127.0.0.1:3090`.

## Tailscale

Use Tailscale for remote and tailnet reachability:

- access from another machine
- private mesh networking
- device identity
- remote admin access
- cross-device service sharing

Example: a laptop or phone reaches a workstation service over the tailnet.

## Combined model

Use Slim to make local services humane. Use Tailscale to reach the machine safely from elsewhere.

Do not assume a Slim local name is automatically safe to expose remotely. Treat remote exposure as a separate gate.
