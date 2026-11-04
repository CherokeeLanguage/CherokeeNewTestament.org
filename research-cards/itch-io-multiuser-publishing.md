# Research card: itch.io multi-user publishing / shared org account

(YAML)
id: itch-io-multiuser-publishing
question: Can multiple users share an org setup on itch.io for app/game publishing and management?
date: 2026-11-04
confidence: high on core facts; medium on new-device pass behavior and game-admin upload rights
answer: |
  itch.io has no native organization/team account. One account owns each
  project; the game admins feature grants per-game collaborator access to
  other individual accounts. Shared-credential operation works but carries
  device-verification friction and full-account risk.

findings:
  - fact: No org/team account concept; every itch.io account is a single user. Password sharing is the forced workaround for full-account access.
    source: https://itch.io/t/6563075/feature-request-organization-accounts-multi-user-collaboration-with-granular-permissions (opened Jul 01 2026, describes current state)
    confidence: high
  - fact: Game admins feature (official; referenced by leafo in Aug 2015) — a game admin "has access to a game in your account as if they had created it": edit basic data, edit appearance, view unpublished game, see all analytics; game appears in their My games page. Added via Edit game → Game admins tab by username/subdomain; admin must approve via generated link.
    source: https://itch.io/updates/let-collaborators-edit-your-game-pages-with-the-new-game-admins-feature
    confidence: high
  - fact: No granular permissions, no co-ownership, no multi-account profile visibility — game stays under the owner account's URL/profile. Co-ownership feature request open since Aug 2015, still open.
    source: https://github.com/itchio/itch.io/issues/206
    confidence: high
  - fact: itch.io detects logins from new devices and requires a security pass delivered to the account's email — significant friction for shared credentials across locations.
    source: https://itch.io/t/4915603/team-account-for-multiple-memebers-of-a-team-how-to-set-up (May 2025, single user report, thread archived unanswered)
    confidence: medium
  - fact: 2FA is TOTP-only (SMS deliberately not offered, per NIST guidance); setup via QR-code shared secret; 8-digit recovery codes generated as fallback. The TOTP seed and recovery codes can be stored in a shared password-manager vault so multiple credential holders can generate valid codes.
    source: https://itch.io/docs/advanced/two-factor-authentication
    confidence: high
  - fact: ToS Acceptable Use section does not explicitly prohibit account sharing; accounts are individually registered and publishers must be 18+. Creator FAQ contains no team/org entry (not an officially supported workflow).
    source: https://itch.io/docs/legal/terms ; https://itch.io/docs/creators/faq
    confidence: medium (ToS read partially; FAQ question list read in full)
  - fact: Payouts are configured per owning account — direct-to-you (each purchase a transaction to your PayPal/Stripe) or collected-by-itch paid later; set in seller settings.
    source: https://itch.io/docs/creators/faq
    confidence: high
  - fact: butler auth is per-account (butler login or API key); push targets owner-account namespaces (butler push <dir> user/game:channel). Web/CLI build upload rights for game admins are not documented in the official announcement.
    source: https://itch.io/docs/butler/pushing.html
    confidence: high on butler mechanics; gap noted below on admin upload rights

gaps:
  - Whether game admins can upload builds (web upload or butler push under the owner namespace) — not covered by official docs/announcement found; verify by experiment or keep all build pushes on the owning account.
  - Whether itch.io staff have an official written position on shared credentials beyond community threads (no statement found).

recommended_practice: |
  1. Dedicated studio/org account (not personal) owns all projects, the public
     brand/subdomain, and payouts — IP ownership stays with the account.
  2. Humans operate their own personal itch.io accounts, granted per-game
     admin access for page edits/analytics; revocation is instant and needs
     no password rotation.
  3. Run build pushes from CI (e.g., GitHub Actions) with the studio account's
     butler API key stored as a CI secret — humans never need the master
     password for uploads.
  4. Master password + TOTP seed + recovery codes live in a shared password
     manager vault restricted to 1–2 trusted people.
  5. Expect the new-device security pass on logins from unfamiliar machines.
  6. On member departure: remove game admin immediately; rotate master
     password and TOTP seed if they had access to the vault.
  7. Known limits: no granular roles, no audit log found, master-credential
     holders see all games and all financial data.

encounter_protocol: none — no deprecation encountered during this research
