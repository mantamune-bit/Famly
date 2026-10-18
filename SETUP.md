# Famly — Setup Guide

About 20 minutes, once. After that it just runs.

Files:
- `index.html` — the whole app
- `schema.sql` — the database
- `manifest.json`, `icon-180.png`, `icon-512.png` — app name and icon on the home screen

---

## 1. Create the database (Supabase)

1. Create a new project at supabase.com (region: Singapore is closest).
2. Open **SQL Editor**, paste all of `schema.sql`, press **Run**.
3. Go to **Authentication → Sign In / Providers** and turn **off** "Allow new users to sign up". Only the two of you should have accounts.

## 2. Create your two accounts

**Authentication → Users → Add user → Create new user**, tick "Auto Confirm User".
Do this twice: one for you, one for your wife.

## 3. Register both of you as family members

In SQL Editor, run (change the emails and names):

```sql
insert into public.members (user_id, name)
select id, 'Josia' from auth.users where email = 'your@email.com';

insert into public.members (user_id, name)
select id, 'Nama Istri' from auth.users where email = 'wife@email.com';
```

## 4. Connect the app to the database

In Supabase, go to **Project Settings → API** and copy:
- Project URL
- the `anon` / publishable key

Open `index.html` and fill in the two lines near the top:

```js
const SUPABASE_URL = 'https://xxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJ...';
```

The anon key is safe to put in the page. Row Level Security makes sure only logged-in family members can see anything.

## 5. Put it online (GitHub Pages)

1. New GitHub repo, e.g. `famly`. Upload all five files.
2. **Settings → Pages → Deploy from branch → main / root**.
3. A minute later it's live at `https://<your-username>.github.io/famly/`.

## 6. Add to both iPhones

Open the link in **Safari** → Share → **Add to Home Screen**. Log in once. It now opens like a normal app.

---

## 7. iPhone Shortcut for steps (do on each phone)

First, in Famly go to **Sehat → ⚙︎ → Salin token**. Each person has their own token.

### Build the Shortcut
Shortcuts app → **+** → name it "Famly Steps". Add these actions:

1. **Find Health Samples**
   - Type: **Steps**
   - Filter: Start Date **is today**
2. **Calculate Statistics** → **Sum** of Health Samples
3. **Get Contents of URL**
   - URL: `https://xxxx.supabase.co/rest/v1/rpc/log_steps`
   - Method: **POST**
   - Headers:
     - `apikey` → your anon key
     - `Content-Type` → `application/json`
   - Request Body: **JSON**
     - `p_token` (Text) → your token from Famly
     - `p_steps` (Number) → the **Statistics** result

Run it once by hand. iPhone will ask for Health permission. Allow it. Check that the step count shows up in Famly.

### Make it automatic
Shortcuts → **Automation** → **+** → **App** → choose **WhatsApp** → **Is Opened** → **Run Immediately** → select "Famly Steps".

Every time you open WhatsApp, today's steps update silently. The phone is always unlocked then, so Health data is readable. Running many times a day is fine; it just overwrites today's number.

---

## Daily use

- **Morning:** open Famly → tap ☀️ **Aku bangun** → sleep hours → feeling → yesterday's food. Done.
- **Permintaan:** + Baru for things to buy or do. Bought something before? One tap under "Beli lagi".
- **Weekend:** tap a day to add a plan. Tap a plan to delete it.
- **Sehat:** the triangle and 14-day history. Set your own sleep and step targets under ⚙︎.

## What triggers a warning (shown on both phones' home screen)

- Someone checked in as 🤒 sick today
- Average sleep below target for 3 nights
- Wake time more than 1 hour off from usual, 3 days in a row
- Steps under half the target for 3 days
- Food rated 👎 three days in a row
- No check-in for 2 days

After a few months, the Sehat tab also shows your "sick pattern": how much you slept in the nights before getting sick versus normal days.
