# Local domains

Local LifeOS/Hermes services should have stable names.

## Naming convention

Use `.test` domains for local-only service names:

- `workspace.test` -> Hermes Workspace UI
- `hermes.test` -> Hermes gateway API
- `dashboard.test` -> Hermes dashboard
- `router.test` -> 9Router gateway
- `ollama.test` -> local model API

`.test` is reserved for testing and avoids accidental ownership conflicts with public DNS.

## Source of truth

`network/service-map.yaml` owns the mapping from service name to local target port.

Do not spread these mappings across notes, shell history, ad-hoc scripts, and browser bookmarks. Update the service map first, then derive tool config from it.

## Safety

A local name is still an exposure decision. Before adding a service:

1. Check what the service binds to: `127.0.0.1` vs `0.0.0.0`.
2. Check whether the service has authentication.
3. Check whether it exposes secrets, local files, or admin actions.
4. Add a health check when possible.
5. Roll out one domain at a time.
