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

## Pro

Run `pro.sql` once. Free accounts keep 2 lineups and 2 custom stat fields; Pro unlocks the rest, advanced analysis,
longer date ranges, watermark-free share cards and CSV export. Until payments are connected, "Go Pro" collects a waitlist
in `pro_waitlist`. To give an account Pro by hand (e.g. for testing), run in the SQL Editor:

    insert into public.entitlements (user_id, plan)
    select id, 'pro' from auth.users where email = 'you@example.com'
    on conflict (user_id) do update set plan = 'pro', updated_at = now();
