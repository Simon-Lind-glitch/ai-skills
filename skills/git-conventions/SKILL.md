---
name: git-conventions
description: Team git conventions — branch names derived from the Jira ticket (e.g. PE-312/fix-login-redirect), Conventional Commits, and conventional merge request titles that drive semantic release. Use whenever creating a branch, writing a commit, or opening/titling a merge request.
---

# Git Conventions

How this team names branches, writes commits, and titles merge requests. Follow all three every time — they feed each other: the ticket flows from branch → commits → MR, and the conventional format is what triggers semantic release.

## Branch naming

Always name a branch after its Jira ticket, followed by a short kebab-case description:

```text
<TICKET-KEY>/<short-description>
```

Examples:

- `PE-312/fix-login-redirect`
- `PE-451/add-invoice-export`
- `PE-88/bump-node-20`

Rules:

- The ticket key is uppercase and comes first (`PE-312`, not `pe-312`).
- One branch per ticket. If there's no ticket, create one first — every branch traces to a ticket.
- Keep the description a few words, lowercase, hyphen-separated. No spaces or slashes beyond the one after the ticket.

## Commits

Every commit follows [Conventional Commits](https://www.conventionalcommits.org):

```text
<type>(<optional scope>): <description>

<optional body>

<optional footer>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

- `feat:` and `fix:` are the ones that produce a release (minor and patch respectively).
- A breaking change is either `feat!:` / `fix!:` (note the `!`) or a `BREAKING CHANGE:` footer — this drives a major bump.

**Subject:** imperative mood, lowercase, no trailing period. Keep it under ~72 chars.

**Reference the Jira ticket** in the footer so the commit links back to the ticket:

```text
feat(auth): add SSO login via SAML

Wires the identity provider into the login flow and adds the callback route.

PE-312
```

Examples:

- `fix(checkout): prevent double-charge on retry` + `PE-451` footer
- `refactor(api): extract pagination helper`
- `chore(deps): bump express to 4.19`

## Merge requests

The **MR title must also be a valid Conventional Commit** — it's what semantic release reads when the MR is squash-merged, so a non-conventional title means no release is cut.

- Title: `feat(billing): add annual plan` — same rules as a commit subject.
- Include the ticket in the MR title or description so it links in Jira, e.g. `feat(billing): add annual plan (PE-451)`.
- The MR description should summarise the change and list the ticket(s) it closes.

## Quick reference

| Thing | Format | Example |
| --- | --- | --- |
| Branch | `TICKET/short-desc` | `PE-312/fix-login-redirect` |
| Commit | `type(scope): description` + ticket footer | `fix(auth): handle expired token` … `PE-312` |
| MR title | `type(scope): description` | `feat(billing): add annual plan (PE-451)` |
| Breaking | `type!:` or `BREAKING CHANGE:` footer | `feat(api)!: drop v1 endpoints` |
