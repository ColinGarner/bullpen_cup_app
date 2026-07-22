# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Rails 8 (Ruby 3.2.0) app for running Ryder Cup-style golf tournaments: teams, rounds, matches, live per-hole scoring with handicap adjustments, and a leaderboard. Multi-tenant by `Group` (each group is an independent tournament community with its own users, tournaments, and invite code).

Stack: Rails 8 + PostgreSQL, Hotwire (Turbo + Stimulus) with importmap, Tailwind CSS v4 (`tailwindcss-rails`), Devise, Propshaft asset pipeline, Solid Queue / Solid Cache / Solid Cable, HTTParty for the external Golf Course API, Kamal + Railway for deploy.

## Common commands

```bash
bin/setup                 # install gems, prepare DB, then boots bin/dev
bin/dev                   # foreman: rails server + tailwind watcher (Procfile.dev)

bin/rails db:prepare      # create + migrate + seed if empty
bin/rails db:migrate
bin/rails db:seed
bin/rails console

bin/rails test                       # unit / controller tests (Minitest)
bin/rails test test/models/match_test.rb                # single file
bin/rails test test/models/match_test.rb:42             # single test at line
bin/rails test:system                # Capybara + Selenium system tests
bin/rails db:test:prepare test test:system              # what CI runs

bin/rubocop               # rails-omakase style (also runs in CI via -f github)
bin/brakeman --no-pager   # security static analysis (runs in CI)
bin/importmap audit       # JS dependency audit (runs in CI)
```

Dev DB expects local Postgres; connection is driven by `DATABASE_USERNAME` / `DATABASE_PASSWORD` / `DATABASE_HOST` (defaults to current shell user, no password, localhost). Database name is `bullpen_cup_app_development`.

The external Golf Course API needs `GOLF_COURSE_API_KEY` in `.env` (loaded by `dotenv-rails`); `GolfCourseApiService#initialize` raises without it.

## Architecture

### Multi-tenancy: Group is the tenant boundary

Everything belongs to a `Group`. A user can be a member of multiple groups and switches between them.

- `Current` (`app/models/current.rb`) is an `ActiveSupport::CurrentAttributes` holding `user` and `group` for the request. Cached associations on `Current` (`group_tournaments`, `group_teams`, `group_users`) are cleared when `group` is reassigned.
- `GroupContext` concern (included by `ApplicationController`) resolves the current group per request from (in priority order) `params[:group_slug]`, subdomain, `params[:group_id]`, or session. It sets `Current.group`, enforces membership, and exposes helpers (`current_group`, `user_is_group_admin?`, etc.) to views.
- `TenantScoped` concern (on `Tournament`) validates `group_id` presence and provides `.tenant_scoped` / `.in_current_group` scopes. Add this concern to any new model that must be group-scoped.
- Group admin vs group member is stored on `GroupMembership.role` (`"admin"` / `"member"`). The `User#admin` boolean is a separate *global* super-admin flag that bypasses group access checks (see `GroupContext#ensure_group_access` and `Admin::BaseController#ensure_admin_access!`).

### Domain model

```
Group 1─┬─* User (through GroupMembership, role: admin|member)
        └─* Tournament ─* Round ─* Match ─* Score
                        │         │
                        │         └─* MatchPlayer ── User
                        │              (assigns each player to team_a or team_b for the match)
                        └─* Team ─* User (through TeamMembership)
                          Tournament has team_a_id + team_b_id (must be different, check_constraint)
```

- `Tournament#status` is *computed* from `start_date` / `end_date` / `cancelled`. There is no persisted status column and no `start!` / `complete!` methods — only `cancel!`. Scopes `upcoming` / `active` / `completed` use date comparisons.
- `Match#match_type` is a string enum: `fourball_match_play`, `alt_shot_match_play`, `singles_match_play`, `stableford`, `stableford_match_play`, `scramble_match_play`. `Match#expected_player_count` derives players-per-team from the type.
- `Match#winner_team` must be either `team_a` or `team_b` from the parent tournament (validated). Draw is represented by `completed` status with `winner_team` nil.
- Course data flow: at scoring start, the selected tee's per-hole data is copied into `Match#holes_data` (jsonb) so scoring is stable even if the course record changes. `Match#selected_tee_name` records which tee was played.
- Scores: `Score` is one row per (match, user, hole) with `strokes`, `net_strokes`, `handicap_used`, `strokes_received_on_hole`, and `hole_result`. Unique index on `[match_id, user_id, hole_number]`.
- Handicap: `User.handicap` allows negative values for plus handicaps (e.g. +2 stored as `-2.0`); `User#formatted_handicap` handles display. Scramble team handicap is 35% of low + 15% of high (`Match#calculate_scramble_team_handicap`).

### Routing

Two admin surfaces, do not confuse them:

1. **Group-scoped admin** at `/groups/:group_slug/admin/...` (canonical). All admin CRUD for tournaments, rounds, matches, teams, users lives here. `Admin::BaseController` sets `Current.group` from `params[:group_slug]` and gates access via `current_user.group_admin?(current_group)` (or global admin).
2. **Legacy `/admin`** routes redirect to `/select-group`. Don't add routes here.

Group-scoped admin controllers must supply the `group_slug` param on link generation — use the `scoped_*_path` helpers on `Admin::BaseController` rather than the raw path helpers.

Player-facing routes (scoring, leaderboard, group dashboard) sit outside the admin namespace but still resolve `current_group` through `GroupContext`.

### Scoring flow (`ScoringController`)

1. `GET  /matches/:id/select_tees` — must be `upcoming` and `scheduled_for_today?`; renders available tees from `Course` / `holes_data`.
2. `POST /matches/:id/save_tees` — writes `selected_tee_name` + `holes_data` (holes + full course snapshot) and transitions match to `active`.
3. `GET  /matches/:id/next_hole` — routes to the next unscored hole.
4. `GET/POST /matches/:id/score/hole/:hole` — per-hole score entry; `update_score` computes `net_strokes` and `strokes_received_on_hole` per player, then either advances or marks the match `completed`.
5. `GET  /matches/:id/leaderboard` and `GET /tournaments/:id/leaderboard` — read-only views.

`scheduled_for_today?` intentionally allows a ±24h window to tolerate timezone drift between the server and player devices — don't tighten this without discussing.

## Testing

Minitest with fixtures under `test/fixtures/`. `test_helper.rb` uses `parallelize(workers: :number_of_processors)` and loads all fixtures. System tests use Capybara + Selenium (headless Chrome in CI). Add tests under `test/models/`, `test/controllers/`, `test/system/`, or `test/integration/` following the existing per-file convention.

## Deployment

- Production runs on Railway (`railway.toml`, health check `/up`) with the `Procfile` invoking `bundle exec rails server`. Migrations run via the release phase.
- Kamal config exists (`config/deploy.yml`) but placeholder hosts — not the active target unless you're setting up a new environment.
- Multi-DB in prod: primary + `cache` + `queue` + `cable` databases (Solid Cache / Solid Queue / Solid Cable), each with its own `DATABASE_URL` fallback. Solid Queue runs in-process (`SOLID_QUEUE_IN_PUMA=true`).

## Conventions specific to this repo

- Global styling relies on Tailwind utility classes only. Model methods like `status_badge_class` return Tailwind class strings — keep the pattern rather than moving logic into helpers.
- View templates live in ERB (`app/views/**/*.html.erb`); no view components.
- JS is minimal — Hotwire + Stimulus controllers in `app/javascript/controllers/`. Do not add a bundler.
- Rubocop is `rails-omakase` (do not add custom cops without reason). CI runs `bin/rubocop -f github` — fix the lint locally before pushing.
- Keep new group-scoped models routing under `/groups/:group_slug/...` and use `Admin::BaseController`'s `scoped_*` helpers for admin links.
