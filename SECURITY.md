# Security Policy

## Supported versions

This action ships one rolling `latest` semantic-release version; there's no long-term-support branch to track. Security fixes land on `main` and are published as the next tagged release.

## Reporting a vulnerability

Please report security issues privately rather than opening a public GitHub issue: use [GitHub's private vulnerability reporting](https://github.com/swade1987/github-action-kustomize-diff/security/advisories/new) for this repository (Security tab → Report a vulnerability).

Include what you'd include in any good bug report: the affected version or commit, what you found, and how to reproduce it. We'll acknowledge new reports within 5 business days and aim to have a fix or mitigation plan within 30 days, depending on severity.

## Scope

This is a Docker-based GitHub Action: consumers build it fresh from a tagged ref each time it's used (there's no pre-built image published to a registry). It checks out and merges the caller's own base/head refs locally to build a diff - reports about that logic, the Dockerfile, or the CI/release pipeline are in scope. Using this action with `pull_request_target` on an untrusted (fork) PR is a misuse of the trigger, not a vulnerability in the action itself - the documented usage in the README uses plain `pull_request`.
