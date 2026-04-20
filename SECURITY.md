# Security Policy

## Supported Versions

Only the latest release on the `main` branch receives security fixes. The beta (`next`) branch may also receive backports for critical vulnerabilities.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Email **security@monicahq.com** with:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- Any suggested mitigations, if known

You should receive an acknowledgement within **48 hours**. We aim to provide a fix or mitigation plan within **14 days** for critical issues and **90 days** for lower-severity issues.

We will notify you when the vulnerability is fixed and coordinate a public disclosure date with you. We ask that you do not disclose the issue publicly until a fix is released.

## Scope

In scope: authentication, authorization, data leakage, remote code execution, SQL injection, XSS, CSRF, and other OWASP Top 10 categories.

Out of scope: denial-of-service attacks, issues requiring physical access to a self-hosted server, and vulnerabilities in third-party dependencies that have already been publicly disclosed.
