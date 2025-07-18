# 🏌️ Bullpen Cup Web App – Developer To-Do List

A full-featured Ruby on Rails app to manage a Ryder Cup-style golf trip with live scoring, team management, golf course integration, and advanced handicap calculations.

---

## ✅ PHASE 1: Project Setup ✅
- [x] Create new Rails app (`rails new bullpen_cup --database=postgresql`)
- [x] Initialize Git repository and connect to GitHub
- [x] Set up Railway, Render, or Fly.io for deployment
- [x] Add basic home controller and landing page
- [x] Install Tailwind CSS or Bootstrap for styling
- [x] Set up environment variables (e.g., credentials for email, DB, etc.)

---

## ✅ PHASE 2: Authentication & Users ✅
- [x] Install and configure Devise for user authentication
- [x] Enable sign up, login, password reset
- [x] Add User model fields:
  - [x] `name`
  - [x] `email`
  - [x] `handicap`
  - [x] `team` (enum or foreign key)
  - [x] `is_admin` (boolean)
- [x] Add user profile page
- [x] Add profile picture upload (Cloudinary or ActiveStorage)
- [x] Admin ability to invite or edit users

---

## ✅ PHASE 3: Trip & Team Structure ✅
- [x] Create models:
  - [x] `Tournament` (year, location, etc.)
  - [x] `Team` (name, color, captain)
  - [x] `UserTournament` (join table between users and tournaments)
- [x] Admin UI to assign teams
- [x] Designate team captains
- [x] Track past winners
- [x] Tournament status management (automatic based on dates)

---

## 🆕 PHASE 4: Golf Course API Integration
- [ ] Set up Golf Course API credentials and configuration
- [ ] Create `GolfCourse` model with API integration:
  - [ ] `api_course_id` (external course ID)
  - [ ] `name`, `location`, `phone`, `website`
  - [ ] `slope_rating`, `course_rating` per tee
  - [ ] `par_data` and `yardage_data` per hole
- [ ] Create `Tee` model for different tee options:
  - [ ] `name` (e.g., "Championship", "Men's", "Senior")
  - [ ] `color`, `slope_rating`, `course_rating`
  - [ ] `total_yardage`, `total_par`
- [ ] Admin interface to:
  - [ ] Search and select golf courses via API
  - [ ] Choose available tees for tournament
  - [ ] Preview course layout and hole details
- [ ] Course information display pages:
  - [ ] Course overview with contact info
  - [ ] Hole-by-hole details (par, yardage, handicap)
  - [ ] Tee comparison chart

---

## ✅ PHASE 5: Scheduling & Rounds ✅
- [x] Create `Round` model for tournament structure
- [x] Admin UI to create and manage rounds
- [x] Display rounds and scheduling to users
- [x] Integration with golf course selection

---

## ✅ PHASE 6: Matches & Basic Scoring ✅
- [x] Create `Match` model with:
  - [x] `match_type` (singles, fourball, alternate shot, stableford)
  - [x] `round_id`, team assignments, player assignments
  - [x] Status tracking and winner determination
- [x] Create `MatchPlayer` join table
- [x] Basic match management UI
- [x] Match creation and player assignment

---

## 🆕 PHASE 7: Advanced Golf Scoring & Handicap System
- [ ] Create `CourseHandicap` model for calculated handicaps:
  - [ ] `user_id`, `tee_id`, `tournament_id`
  - [ ] `course_handicap` (calculated from index + slope/course rating)
  - [ ] API integration for official handicap calculations
- [ ] Create `StrokeAllocation` model:
  - [ ] `match_id`, `user_id`, `hole_number`
  - [ ] `strokes_received` (based on hole handicap and course handicap)
  - [ ] `net_strokes_given` for match play calculations
- [ ] Handicap calculation engine:
  - [ ] Fetch course data via Golf Course API
  - [ ] Calculate course handicaps based on tee selection
  - [ ] Determine stroke allocation per hole per player
  - [ ] Handle different match formats (match play vs stroke play)
- [ ] Enhanced scoring UI:
  - [ ] Show each player's strokes received per hole
  - [ ] Display gross vs net scores
  - [ ] Real-time match status with handicap adjustments
  - [ ] Hole-by-hole match play scoring (up/down, AS)

---

## 🆕 PHASE 8: Live Scoring & Match Analytics
- [ ] Create `Score` model with handicap integration:
  - [ ] `user_id`, `match_id`, `hole_number`
  - [ ] `gross_score`, `net_score`, `points_earned`
  - [ ] `strokes_received_on_hole`
- [ ] Live scoring interface:
  - [ ] Players enter gross scores per hole
  - [ ] Automatic net score calculation
  - [ ] Live leaderboard with handicap adjustments
  - [ ] Match play hole winners with stroke allocation
- [ ] Enhanced match displays:
  - [ ] Pre-round stroke allocation cards
  - [ ] Live match status (dormie, etc.)
  - [ ] Team point summaries with match results

---

## 📊 PHASE 9: Stats & History
- [ ] Display past tournament results with handicap data
- [ ] Player stats with gross/net averages
- [ ] Course performance analytics
- [ ] Handicap trending and improvements
- [ ] Head-to-head records with stroke differentials

---

## 💬 PHASE 10: Trash Talk & Social
- [ ] Create `Post` or `Comment` model
- [ ] Add bulletin board / trash talk feature
- [ ] Allow players to post, like, and reply to messages
- [ ] Add light moderation (admin delete)
- [ ] Match prediction and side bet features

---

## 📸 PHASE 11: Extras & Polish
- [ ] Add photo gallery (ActiveStorage or Cloudinary)
- [ ] Upload and tag players in photos
- [ ] Display "Past Champions" trophy wall
- [ ] Mobile app features:
  - [ ] GPS yardage integration
  - [ ] Course maps and hole layouts
  - [ ] Push notifications for tee times
- [ ] Seed database with realistic golf course data

---

## 🌐 PHASE 12: Deploy & Launch
- [ ] Set up production environment with API keys
- [ ] Configure domain and SSL
- [ ] Set up email notifications (SendGrid or similar)
- [ ] Write onboarding instructions for players
- [ ] Test with real golf course data
- [ ] Launch app 🎉

---

## 🔧 Technical Notes

### Golf Course API Integration
- **API Endpoint**: `https://api.golfcourseapi.com`
- **Key Features**:
  - Course search and details
  - Tee information (slope/course ratings)
  - Hole-by-hole data (par, yardage, handicap)
  - Official handicap calculation support

### Handicap Calculation Formula
```
Course Handicap = Handicap Index × (Slope Rating ÷ 113) + (Course Rating - Par)
```

### Stroke Allocation Rules
- Strokes allocated based on hole handicap rankings
- Lower handicap vs higher handicap determines net strokes
- Match play: strokes given on specific holes
- Stroke play: total strokes subtracted from gross score

### Match Types & Scoring
- **Singles Match Play**: Individual vs individual with stroke allocation
- **Fourball Match Play**: Best ball of partnership with individual handicaps
- **Alternate Shot**: Partnership plays one ball with combined handicap
- **Stableford**: Points-based scoring with handicap adjustments 