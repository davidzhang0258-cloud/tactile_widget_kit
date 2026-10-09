# Security Policy

## Reporting a vulnerability

We take security seriously. If you discover a security vulnerability in
Tactile Widget Kit, please **do not** open a public issue. Instead, report it
privately by opening a GitHub Security Advisory through the repository's
**Security** tab, or by emailing the maintainers directly.

Please include:

- A clear description of the vulnerability.
- Steps to reproduce, including environment details.
- The affected version range.
- Any proposed mitigation you may have.

We will acknowledge receipt within 3 business days and aim to provide a
resolution or timeline within 14 days.

## Supported versions

Only the latest release on the `main` branch receives security updates.

## Scope

This project is a local-first Flutter starter kit. It does not ship production
credentials, backend endpoints, or signing keys. Please do not report the
following as vulnerabilities:

- Hard-coded placeholder values in the sample/demo code.
- Debug signing configuration used to produce local builds.
- Missing runtime permission prompts for features not enabled in the demo.
