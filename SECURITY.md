# Security Policy

This policy applies to this repository and to every
[@FlexNetOS](https://github.com/FlexNetOS) repository that inherits it
(i.e. has no local `SECURITY.md`). A repo-local copy always overrides this
one.

## Reporting a vulnerability

**Please report privately. Do not open a public issue, pull request, or
Discussions thread.**

Preferred channels, in order:

1. **GitHub Private Vulnerability Reporting** — on the affected repo's
   *Security* tab, click **Report a vulnerability**. This creates a private
   advisory draft visible only to maintainers and to you. Preferred for all
   reports because it keeps the conversation, fix, and CVE coordination in
   one place.
2. **Email** — <revenaugh.david@gmail.com> with subject
   `SECURITY: <repo> - <short summary>`. Use this if GitHub PVR is
   unavailable for the repo, or if you need to reach the maintainer before
   creating an account.

Please include, as much as you can:

- Affected repository, branch or tag, and commit SHA if known.
- Reproduction steps or a minimal proof-of-concept.
- Impact assessment — what an attacker can do, and any pre-conditions.
- Your name (or handle) and how you would like to be credited in the
  advisory, or a note that you prefer to remain anonymous.

## Response SLA

| Stage | Target |
| --- | --- |
| Acknowledgement of receipt | within **48 hours** |
| Initial triage & severity assessment | within **7 days** |
| Fix or mitigation in `main` (High / Critical) | within **30 days** |
| Fix or mitigation in `main` (Low / Medium) | within **90 days** |
| Coordinated public disclosure | after a fix is shipped, or **90 days** from initial report — whichever comes first |

Critical issues with evidence of active exploitation, unauthenticated RCE,
or credential exposure are handled out-of-band and may be disclosed faster.

## Supported versions

| Repository class | Supported versions |
| --- | --- |
| Tagged releases (semver) | The latest minor of each currently-supported major. |
| `main`-only repos (no tags) | `main` is the only supported branch. |
| Reusable workflows in this repo | The latest moving major tag (e.g. `@v1`) and `main`. |

If a repository is archived or its README explicitly marks it end-of-life,
it is **not** supported and reports may be closed without remediation.

## Safe harbour

Good-faith security research conducted under this policy will not result in
legal action from FlexNetOS. To stay inside safe harbour, research must:

- Be limited to your own accounts or to resources you own and control.
- Not access, modify, or exfiltrate user or maintainer data beyond the
  minimum required to demonstrate the issue.
- Not degrade availability of any FlexNetOS service or any third-party
  service used by FlexNetOS.
- Give us reasonable time to remediate before public disclosure (see the
  SLA above).

## Out of scope

The following reports will be triaged but generally closed without
remediation:

- Findings from automated scanners with no working proof-of-concept.
- Missing security headers on static documentation sites.
- Self-XSS, clickjacking on pages with no state change, or social
  engineering of maintainers.
- Volumetric denial-of-service. Rate limits and edge protections are the
  responsibility of the hosting platform.
- Issues that require physical access to a maintainer's device.
- Best-practice deviations (e.g. weak cipher suites on a service that is
  not handling sensitive data) without demonstrated impact.

## Credit

Reporters who follow this policy are credited in the resulting GitHub
Security Advisory unless they ask to remain anonymous. We do not currently
operate a paid bug-bounty programme.
