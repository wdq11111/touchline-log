# Touchline Log

Free match tracker for FC Mobile players. Static site (one `index.html`) + Supabase for accounts and cloud sync.
Signed out, everything works locally in the browser; signing in merges this device's log into the account and syncs it.

## Setup

1. Create a Supabase project. In **SQL Editor**, run `supabase.sql`.
2. **Project Settings → API**: copy the Project URL and the anon / publishable key into `window.TL_CONFIG` in `index.html`.
   The anon key is meant to be public; Row Level Security in `supabase.sql` keeps each user's row private.
3. **Authentication → Emails → Magic Link** template: add `{{ .Token }}` so the email shows a sign-in code as well as the link.
4. Deploy the folder to any static host (GitHub Pages, Cloudflare Pages, Netlify).
5. **Authentication → URL Configuration**: set Site URL to the deployed address and add it to Redirect URLs.
6. Before a public launch, set up custom SMTP (Authentication → Emails), since the built-in sender is rate-limited and meant for testing.
7. Optional Google sign-in: enable the Google provider in Supabase with a Google Cloud OAuth client, then set `google:true` in `TL_CONFIG`.

Unofficial fan tool, not affiliated with or endorsed by Electronic Arts.
