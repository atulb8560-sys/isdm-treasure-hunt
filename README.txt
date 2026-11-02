# ISDM Treasure Hunt registration website

## Files
- `index.html` — website
- `setup.sql` — shared database setup

## Publish the shared live version
1. Create a project at https://supabase.com/
2. Open the project's SQL Editor, paste all of `setup.sql`, and run it.
3. In Supabase, open Project Settings → API. Copy the Project URL and the `anon` / publishable public key. Never use the service_role/secret key in the website.
4. Open `index.html` in a text editor. Near the top of the JavaScript, find `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Paste your Project URL and anon/publishable key between the quotes.
5. Save `index.html`.
6. Upload the `index.html` file to https://app.netlify.com/drop (or another static host). Netlify gives you a public website link.
7. Open that public link and test with a few dummy names before sharing it with participants.

## Behaviour
- Participant chooses a column as a preference; that choice is recorded.
- Each successful registration randomises the display and assigns everyone as evenly as possible across four teams. Team sizes differ by at most one.
- The database stores the team allocation, so all devices see the same team lists.
- The database rejects new registrations after 4 Nov 2026, 11:59 PM IST. The last allocation stays fixed after the deadline.
- Names are public to anyone who can access the page. Collect only the minimum information needed.

## Important
The page uses Supabase's public browser key and database permissions. Do not add private credentials. The public key is intended for browser use; database access is limited by the supplied SQL policies and registration function. Test before sharing publicly.
