# SCOTUS Justices in Essentials — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the 9 current U.S. Supreme Court justices to the Essentials module so they appear for every address search, with a `NATIONAL_JUDICIAL` district type foundation for future federal judiciary expansion.

**Architecture:** New `JudgeDetail` GORM model + `NATIONAL_JUDICIAL` district type. Backend queries updated to always include `NATIONAL_JUDICIAL` alongside `NATIONAL_EXEC`. Frontend classify/sort logic extended with "Federal Judiciary" group. Go CLI import command seeds all 9 justices with idempotent upserts.

**Tech Stack:** Go 1.24.3, GORM, PostgreSQL, Chi router, React 19, Vite, Tailwind CSS 4

**Spec:** `docs/superpowers/specs/2026-03-15-scotus-essentials-design.md`

---

## Chunk 1: Data Model & Backend

### Task 1: Add JudgeDetail model

**Files:**
- Modify: `EV-Backend/internal/essentials/models.go` (after line 306, before TableName functions)
- Modify: `EV-Backend/internal/essentials/setup.go:36-75` (AutoMigrate list)

- [ ] **Step 1: Add JudgeDetail struct to models.go**

Add after the `BuildingPhoto` struct (line 306) and before the `TableName()` functions (line 308):

```go
// JudgeDetail stores judge-specific metadata not applicable to elected officials.
// 1:1 with Politician via PoliticianID.
type JudgeDetail struct {
	ID                      uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	PoliticianID            uuid.UUID `json:"politician_id" gorm:"type:uuid;uniqueIndex"`
	AppointedBy             string    `json:"appointed_by"`               // President name, e.g. "Barack Obama"
	AppointingPresidentParty string   `json:"appointing_president_party"` // "Democratic", "Republican"
	ConfirmationVote        string    `json:"confirmation_vote"`          // e.g. "68-31", empty for voice votes
	CourtRole               string    `json:"court_role"`                 // "Chief Justice", "Associate Justice"
	CreatedAt               time.Time `json:"created_at"`
	UpdatedAt               time.Time `json:"updated_at"`
}
```

- [ ] **Step 2: Add TableName method**

Add with the other `TableName()` functions (after line ~340):

```go
func (JudgeDetail) TableName() string {
	return "essentials.judge_details"
}
```

- [ ] **Step 3: Register in AutoMigrate**

In `setup.go`, add `&JudgeDetail{}` to the `AutoMigrate` call, after `&LegislativePoliticianIDMap{}` (line 71):

```go
		&LegislativePoliticianIDMap{},
		// SCOTUS: Judge-specific metadata
		&JudgeDetail{},
```

- [ ] **Step 4: Verify compilation**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...`
Expected: Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add EV-Backend/internal/essentials/models.go EV-Backend/internal/essentials/setup.go
git commit -m "feat(essentials): add JudgeDetail model for judge-specific metadata"
```

---

### Task 2: Update backend queries to include NATIONAL_JUDICIAL

**Files:**
- Modify: `EV-Backend/internal/essentials/handlers.go:1241` (fetchOfficialsFromDB)
- Modify: `EV-Backend/internal/essentials/handlers.go:1571` (fetchFederalAndStateFromDBFiltered)
- Modify: `EV-Backend/internal/essentials/geofence_lookup.go:108-118` (FindPoliticiansByGeoMatches)

- [ ] **Step 1: Update fetchOfficialsFromDB**

In `handlers.go`, find the WHERE clause at line ~1241:

```go
		  d.district_type = 'NATIONAL_EXEC'
```

Replace with:

```go
		  d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL')
```

- [ ] **Step 2: Update fetchFederalAndStateFromDBFiltered**

In `handlers.go`, find the WHERE clause at line ~1571:

```go
		  d.district_type = 'NATIONAL_EXEC'
```

Replace with:

```go
		  d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL')
```

- [ ] **Step 3: Update FindPoliticiansByGeoMatches**

In `geofence_lookup.go`, after the state-level judicial block (line ~118), add a new block to always include NATIONAL_JUDICIAL:

```go
	// Include U.S. Supreme Court (and future federal judiciary) for all searches.
	// NATIONAL_JUDICIAL has no geofence — always injected like NATIONAL_EXEC.
	conditions = append(conditions, fmt.Sprintf(
		"(d.district_type = $%d)",
		argIdx,
	))
	args = append(args, "NATIONAL_JUDICIAL")
	argIdx++
```

This goes right after line 118 (closing brace of the `for fips := range stateFIPSSeen` loop) and before line 120 (`whereClause := strings.Join(...)`).

- [ ] **Step 4: Verify compilation**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...`
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add EV-Backend/internal/essentials/handlers.go EV-Backend/internal/essentials/geofence_lookup.go
git commit -m "feat(essentials): include NATIONAL_JUDICIAL in all address search queries"
```

---

### Task 3: Create SCOTUS import command

**Files:**
- Create: `EV-Backend/internal/essentials/import_scotus.go`
- Modify: `EV-Backend/main.go` (add CLI case after existing import commands)

- [ ] **Step 1: Create import_scotus.go**

Create file at `EV-Backend/internal/essentials/import_scotus.go`:

```go
package essentials

import (
	"fmt"
	"log"
	"time"

	"github.com/EmpoweredVote/EV-Backend/internal/db"
	"github.com/google/uuid"
)

type scotusJustice struct {
	FirstName       string
	MiddleInitial   string
	LastName        string
	NameSuffix      string
	FullName        string
	CourtRole       string // "Chief Justice" or "Associate Justice"
	AppointedBy     string
	PresidentParty  string
	ConfirmationVote string
	AppointmentDate string // YYYY-MM-DD
	PhotoOriginURL  string // supremecourt.gov URL (backup)
	PhotoCDNURL     string // Supabase CDN URL (primary)
}

var scotusJustices = []scotusJustice{
	{
		FirstName: "John", MiddleInitial: "G.", LastName: "Roberts", NameSuffix: "Jr.",
		FullName: "John G. Roberts Jr.", CourtRole: "Chief Justice",
		AppointedBy: "George W. Bush", PresidentParty: "Republican",
		ConfirmationVote: "78-22", AppointmentDate: "2005-09-29",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/CJRoberts.aspx",
	},
	{
		FirstName: "Clarence", LastName: "Thomas",
		FullName: "Clarence Thomas", CourtRole: "Associate Justice",
		AppointedBy: "George H.W. Bush", PresidentParty: "Republican",
		ConfirmationVote: "52-48", AppointmentDate: "1991-10-23",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JThomas.aspx",
	},
	{
		FirstName: "Samuel", MiddleInitial: "A.", LastName: "Alito", NameSuffix: "Jr.",
		FullName: "Samuel A. Alito Jr.", CourtRole: "Associate Justice",
		AppointedBy: "George W. Bush", PresidentParty: "Republican",
		ConfirmationVote: "58-42", AppointmentDate: "2006-01-31",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JAlito.aspx",
	},
	{
		FirstName: "Sonia", LastName: "Sotomayor",
		FullName: "Sonia Sotomayor", CourtRole: "Associate Justice",
		AppointedBy: "Barack Obama", PresidentParty: "Democratic",
		ConfirmationVote: "68-31", AppointmentDate: "2009-08-08",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JSotomayor.aspx",
	},
	{
		FirstName: "Elena", LastName: "Kagan",
		FullName: "Elena Kagan", CourtRole: "Associate Justice",
		AppointedBy: "Barack Obama", PresidentParty: "Democratic",
		ConfirmationVote: "63-37", AppointmentDate: "2010-08-07",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JKagan.aspx",
	},
	{
		FirstName: "Neil", MiddleInitial: "M.", LastName: "Gorsuch",
		FullName: "Neil M. Gorsuch", CourtRole: "Associate Justice",
		AppointedBy: "Donald Trump", PresidentParty: "Republican",
		ConfirmationVote: "54-45", AppointmentDate: "2017-04-10",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JGorsuch.aspx",
	},
	{
		FirstName: "Brett", MiddleInitial: "M.", LastName: "Kavanaugh",
		FullName: "Brett M. Kavanaugh", CourtRole: "Associate Justice",
		AppointedBy: "Donald Trump", PresidentParty: "Republican",
		ConfirmationVote: "50-48", AppointmentDate: "2018-10-06",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JKavanaugh.aspx",
	},
	{
		FirstName: "Amy", LastName: "Coney Barrett",
		FullName: "Amy Coney Barrett", CourtRole: "Associate Justice",
		AppointedBy: "Donald Trump", PresidentParty: "Republican",
		ConfirmationVote: "52-48", AppointmentDate: "2020-10-27",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JBarrett.aspx",
	},
	{
		FirstName: "Ketanji", LastName: "Brown Jackson",
		FullName: "Ketanji Brown Jackson", CourtRole: "Associate Justice",
		AppointedBy: "Joe Biden", PresidentParty: "Democratic",
		ConfirmationVote: "53-47", AppointmentDate: "2022-06-30",
		PhotoOriginURL: "https://www.supremecourt.gov/about/biographies/JJackson.aspx",
	},
}

// ImportSCOTUS seeds all 9 current Supreme Court justices into the database.
// Idempotent: safe to re-run. Matches justices by full_name to avoid duplicates.
func ImportSCOTUS(dryRun bool) error {
	log.Println("=== SCOTUS Import ===")

	// 1. Ensure Government record exists
	var gov Government
	if err := db.DB.Where("name = ? AND type = ?", "United States Federal Government", "federal").
		FirstOrCreate(&gov, Government{
			Name:  "United States Federal Government",
			Type:  "federal",
			State: "US",
		}).Error; err != nil {
		return fmt.Errorf("create government: %w", err)
	}
	log.Printf("Government: %s (id=%s)", gov.Name, gov.ID)

	// 2. Ensure Chamber exists (negative ExternalID to avoid conflict with external sources)
	var chamber Chamber
	if err := db.DB.Where("external_id = ?", -100).FirstOrCreate(&chamber, Chamber{
		ExternalID:        -100,
		GovernmentID:      gov.ID,
		Name:              "U.S. Supreme Court",
		NameFormal:        "Supreme Court of the United States",
		OfficialCount:     9,
		ElectionFrequency: "life_tenure",
		VacancyRules:      "Presidential nomination with Senate confirmation",
	}).Error; err != nil {
		return fmt.Errorf("create chamber: %w", err)
	}
	log.Printf("Chamber: %s (id=%s)", chamber.Name, chamber.ID)

	// 3. Ensure District exists
	var district District
	if err := db.DB.Where("external_id = ?", -100).FirstOrCreate(&district, District{
		ExternalID:   -100,
		DistrictType: "NATIONAL_JUDICIAL",
		Label:        "United States",
		State:        "US",
		GeoID:        "US",
		IsJudicial:   true,
		NumOfficials: 9,
	}).Error; err != nil {
		return fmt.Errorf("create district: %w", err)
	}
	log.Printf("District: %s type=%s (id=%s)", district.Label, district.DistrictType, district.ID)

	// 4. Ensure GovernmentBody exists (for display name/URL in queries)
	var govBody GovernmentBody
	if err := db.DB.Where("state = ? AND geo_id = ? AND body_key = ?", "US", "US", "Supreme Court of the United States").
		FirstOrCreate(&govBody, GovernmentBody{
			State:       "US",
			GeoID:       "US",
			BodyKey:     "Supreme Court of the United States",
			DisplayName: "U.S. Supreme Court",
			WebsiteURL:  "https://www.supremecourt.gov",
		}).Error; err != nil {
		return fmt.Errorf("create government body: %w", err)
	}
	log.Printf("GovernmentBody: %s (id=%s)", govBody.DisplayName, govBody.ID)

	if dryRun {
		log.Println("[DRY RUN] Would create/update justices:")
		for _, j := range scotusJustices {
			log.Printf("  - %s (%s)", j.FullName, j.CourtRole)
		}
		return nil
	}

	// 5. Upsert each justice
	created, updated := 0, 0
	for i, j := range scotusJustices {
		externalID := -200 - i // -200, -201, ... -208

		// Find or create Politician
		var pol Politician
		result := db.DB.Where("full_name = ? AND source = ?", j.FullName, "manual_scotus").First(&pol)
		isNew := result.Error != nil

		if isNew {
			pol = Politician{
				ExternalID:     externalID,
				FirstName:      j.FirstName,
				MiddleInitial:  j.MiddleInitial,
				LastName:       j.LastName,
				NameSuffix:     j.NameSuffix,
				FullName:       j.FullName,
				Party:          "Nonpartisan",
				IsAppointed:    true,
				IsActive:       true,
				IsIncumbent:    true,
				Source:         "manual_scotus",
				DataSource:     "manual",
				PhotoOriginURL: j.PhotoOriginURL,
			}
			if j.AppointmentDate != "" {
				pol.AppointmentDate = &j.AppointmentDate
			}
			if err := db.DB.Create(&pol).Error; err != nil {
				return fmt.Errorf("create politician %s: %w", j.FullName, err)
			}
			created++
		} else {
			// Update existing record
			updates := map[string]interface{}{
				"is_active":        true,
				"is_incumbent":     true,
				"photo_origin_url": j.PhotoOriginURL,
			}
			if j.AppointmentDate != "" {
				updates["appointment_date"] = j.AppointmentDate
			}
			db.DB.Model(&pol).Updates(updates)
			updated++
		}

		// Upsert Office
		var office Office
		polID := pol.ID
		if err := db.DB.Where("politician_id = ? AND chamber_id = ?", pol.ID, chamber.ID).
			FirstOrCreate(&office, Office{
				PoliticianID:          &polID,
				ChamberID:             chamber.ID,
				DistrictID:            district.ID,
				Title:                 j.CourtRole,
				RepresentingState:     "US",
				Seats:                 1,
				NormalizedPositionName: j.CourtRole,
				IsAppointedPosition:   true,
			}).Error; err != nil {
			return fmt.Errorf("create office for %s: %w", j.FullName, err)
		}

		// Update politician's OfficeID
		db.DB.Model(&pol).Update("office_id", office.ID)

		// Upsert JudgeDetail
		var jd JudgeDetail
		if err := db.DB.Where("politician_id = ?", pol.ID).FirstOrCreate(&jd, JudgeDetail{
			PoliticianID:             pol.ID,
			AppointedBy:             j.AppointedBy,
			AppointingPresidentParty: j.PresidentParty,
			ConfirmationVote:        j.ConfirmationVote,
			CourtRole:               j.CourtRole,
		}).Error; err != nil {
			return fmt.Errorf("create judge detail for %s: %w", j.FullName, err)
		}

		// Update JudgeDetail if it already existed (in case data changed)
		db.DB.Model(&jd).Updates(map[string]interface{}{
			"appointed_by":              j.AppointedBy,
			"appointing_president_party": j.PresidentParty,
			"confirmation_vote":         j.ConfirmationVote,
			"court_role":                j.CourtRole,
		})

		// Upsert PoliticianImage (CDN URL — placeholder until photos uploaded to Supabase)
		if j.PhotoCDNURL != "" {
			var img PoliticianImage
			db.DB.Where("politician_id = ? AND type = ?", pol.ID, "default").
				FirstOrCreate(&img, PoliticianImage{
					PoliticianID: pol.ID,
					URL:          j.PhotoCDNURL,
					Type:         "default",
					PhotoLicense: "us_government_work",
				})
		}

		log.Printf("  [%d/9] %s %s — %s", i+1,
			map[bool]string{true: "CREATED", false: "UPDATED"}[isNew],
			j.FullName, j.CourtRole)
	}

	log.Printf("=== SCOTUS Import Complete: %d created, %d updated ===", created, updated)
	return nil
}
```

- [ ] **Step 2: Wire CLI subcommand in main.go**

In `main.go`, add a new case inside the `switch os.Args[1]` block (after the last existing import case):

```go
		case "import-scotus":
			dryRun := false
			for _, arg := range os.Args[2:] {
				if arg == "--dry-run" {
					dryRun = true
				}
			}
			if err := essentials.ImportSCOTUS(dryRun); err != nil {
				log.Fatal("import-scotus failed: ", err)
			}
			os.Exit(0)
```

- [ ] **Step 3: Verify compilation**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add EV-Backend/internal/essentials/import_scotus.go EV-Backend/main.go
git commit -m "feat(essentials): add SCOTUS import command with 9 justices"
```

---

## Chunk 2: Frontend & Integration

### Task 4: Update frontend classification

**Files:**
- Modify: `essentials/src/lib/classify.js:8-15` (FEDERAL_ORDER)
- Modify: `essentials/src/lib/classify.js:101-228` (classifyCategory)
- Modify: `essentials/src/lib/classify.js:241-270` (CATEGORY_DISPLAY_NAMES)

- [ ] **Step 1: Add "Federal Judiciary" to FEDERAL_ORDER**

In `classify.js`, update line 8-15:

```javascript
export const FEDERAL_ORDER = [
  "U.S. Senate",
  "U.S. House",
  "President / VP",
  "Cabinet",
  "Independent Agencies & Commissions",
  "Executive (Other)",
  "Federal Judiciary",
];
```

- [ ] **Step 2: Add NATIONAL_JUDICIAL classification**

In `classifyCategory()`, add before the `NATIONAL_EXEC` block (before line 112):

```javascript
  if (dt === "NATIONAL_JUDICIAL") {
    return { tier: "Federal", group: "Federal Judiciary" };
  }
```

- [ ] **Step 3: Add display name mapping**

In `CATEGORY_DISPLAY_NAMES`, add after `"Executive (Other)"` entry (line 248):

```javascript
  "Federal Judiciary": "U.S. Supreme Court",
```

- [ ] **Step 4: Verify frontend builds**

Run: `cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build`
Expected: Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add essentials/src/lib/classify.js
git commit -m "feat(essentials-ui): add Federal Judiciary classification for SCOTUS"
```

---

### Task 5: Add Federal Judiciary sort options

**Files:**
- Modify: `essentials/src/utils/sorters.js:461` (GROUP_SORT_OPTIONS, before closing brace)

- [ ] **Step 1: Add "Federal Judiciary" sort group**

In `sorters.js`, add before the closing `};` of `GROUP_SORT_OPTIONS` (after the "Local Judiciary" block ending at line 460):

```javascript
  "Federal Judiciary": [
    {
      id: "court_role",
      label: "Role",
      cmp: (dir) => makeComparator(chiefJusticeFirstKey, dir),
    },
    {
      id: "seniority",
      label: "Seniority",
      cmp: (dir) => makeComparator(appointmentDateKey, dir),
    },
    {
      id: "name",
      label: "Name",
      cmp: (dir) => makeComparator(lastNameKey, dir),
    },
  ],
```

- [ ] **Step 2: Verify frontend builds**

Run: `cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add essentials/src/utils/sorters.js
git commit -m "feat(essentials-ui): add Federal Judiciary sort options (role, seniority, name)"
```

---

### Task 6: Run import and verify end-to-end

**Files:** No new files — this is a verification task.

- [ ] **Step 1: Run import in dry-run mode**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go run . import-scotus --dry-run`
Expected: Logs showing "Would create/update justices" with all 9 names listed. No database changes.

- [ ] **Step 2: Run import for real**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go run . import-scotus`
Expected: Logs showing "CREATED" for each of 9 justices, "SCOTUS Import Complete: 9 created, 0 updated".

- [ ] **Step 3: Verify idempotency**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go run . import-scotus`
Expected: Logs showing "UPDATED" for each of 9 justices, "SCOTUS Import Complete: 0 created, 9 updated".

- [ ] **Step 4: Test address search returns SCOTUS justices**

Start the backend server and test with an address search. The response should include 9 additional results with `district_type: "NATIONAL_JUDICIAL"` and `chamber_name_formal: "Supreme Court of the United States"`.

- [ ] **Step 5: Test frontend classification**

Start the frontend dev server. Search any address. Verify:
- "U.S. Supreme Court" section appears at the bottom of the Federal tier
- Chief Justice Roberts appears first
- Remaining justices sorted by seniority (appointment date)

---

### Task 7: Upload official portraits to Supabase Storage

**Files:**
- Modify: `EV-Backend/internal/essentials/import_scotus.go` (update `PhotoCDNURL` fields once URLs are known)

- [ ] **Step 1: Download official SCOTUS portraits**

Download the 9 official portraits from supremecourt.gov. These are U.S. government works and in the public domain.

- [ ] **Step 2: Upload to Supabase Storage**

Upload each portrait to the existing Supabase Storage bucket used for politician headshots. Name files consistently: `scotus-roberts.jpg`, `scotus-thomas.jpg`, etc.

- [ ] **Step 3: Update PhotoCDNURL values in import_scotus.go**

Update each justice's `PhotoCDNURL` field in the `scotusJustices` slice with the Supabase CDN URLs.

- [ ] **Step 4: Re-run import to populate images**

Run: `cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go run . import-scotus`
Expected: PoliticianImage records created with Supabase CDN URLs.

- [ ] **Step 5: Commit**

```bash
git add EV-Backend/internal/essentials/import_scotus.go
git commit -m "feat(essentials): add SCOTUS portrait CDN URLs"
```
