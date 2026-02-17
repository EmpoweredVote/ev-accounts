# Technology Stack

**Analysis Date:** 2026-02-17

## Languages

**Primary:**
- Go 1.24.3 - Backend API server (`EV-Backend/`)
- JavaScript/TypeScript - React frontend applications

**Secondary:**
- TypeScript (optional) - Used in some projects for type safety with tsup bundler

## Runtime

**Backend:**
- Go 1.24.3 (Linux amd64 on AWS App Runner, Docker support)

**Frontend:**
- Node.js (via npm/package managers)
- Browser runtime (ES2020+ with React 19)

**Package Managers:**
- npm (primary)
- Lockfile: package-lock.json present in all Node projects

## Frameworks & Core Dependencies

**Backend HTTP/Routing:**
- Chi v5.2.1 - HTTP router (`EV-Backend/main.go`)
  - Lightweight, composable middleware support
  - Used for all route mounting: `/auth`, `/compass`, `/essentials`, `/treasury`, `/staging`, `/webhooks`

**Frontend UI:**
- React 19.1+ - All frontend applications
  - CompassV2: React 19.1.0
  - essentials: React 19.1.1
  - EV-prototypes sub-projects: React 19.0-19.2
  - ev-ui: Peer dependency React >=17

**Frontend Build/Dev:**
- Vite 6-7 - Modern bundler and dev server
  - CompassV2: Vite 6.3.5
  - essentials: Vite 7.1.2
  - EV-prototypes: Vite 6-7.2.4 (varies per sub-project)
- tsup 8.0.0 - Component library bundler (`ev-ui/`)

**Styling:**
- Tailwind CSS 4.1+ - Utility-first CSS framework (all projects)
  - @tailwindcss/vite - Vite plugin integration
  - PostCSS + Autoprefixer for CSS processing

**Frontend State Management:**
- React Context - CompassV2 (CompassContext)
- Zustand 5.0.9 - read-rank prototype and fallacy-finders (reactive store)
- Local component state - essentials, other projects

**Animation & Motion:**
- Framer Motion 12.23+ - All animation effects
  - Used in: CompassV2, EV-prototypes sub-projects
- @react-spring/web 10.0.1+ - Spring physics animations
  - Used in: CompassV2, essentials, ev-ui, read-rank

**Drag & Drop:**
- @dnd-kit (core, sortable, utilities, modifiers) - Composable drag-drop library
  - CompassV2: @dnd-kit/core 6.3.1, sortable 10.0.0, modifiers 9.0.0
  - read-rank: @dnd-kit/core 6.3.1, sortable 10.0.0, utilities 3.2.2

**Routing:**
- React Router 7.1+ - Frontend navigation
  - CompassV2: react-router 7.6.2
  - essentials: react-router-dom 7.8.2
  - EV-prototypes: react-router-dom 7.1+

**Data Visualization:**
- D3 7.9.0 - Data-driven visualization library (treasury-tracker)
- Recharts 3.5.1 - Composable React charting library (treasury-tracker)
- RadarChart - Custom component (`ev-ui/src/components/RadarChartCore.jsx`)
  - Built with react-spring for animations
  - Published in @chrisandrewsedu/ev-ui package

**Icons & UI Components:**
- Lucide React 0.562.0 - Icon library (empowered-badges, treasury-tracker)
- react-icons 5.5.0 - Icon library (read-rank)

**Gesture/Input:**
- @use-gesture/react 10.3.1 - Gesture detection for swipe/drag (read-rank)

**Database (Backend):**
- GORM 1.30.0 - Go ORM with auto-migration
  - Database driver: gorm.io/driver/postgres 1.6.0
  - Database: PostgreSQL (via Supabase)

**Utilities:**
- uuid 11.1.0 (frontend), google/uuid v1.6.0 (backend) - UUID generation
- tldts 7.0.10 - TLD parsing (CompassV2)
- joho/godotenv v1.5.1 - .env file loading
- golang.org/x/crypto v0.38.0 - Cryptography (bcrypt for passwords)

## Configuration

**Backend Environment:**
- Loaded from `.env.local` via `godotenv` (development)
- AWS Secrets Manager via `apprunner.yaml` (production on AWS App Runner)

**Frontend Environment (Vite):**
- VITE_API_URL - API endpoint override (essentials, CompassV2)
- VITE_BASE - Base URL for builds (CompassV2)
- VITE_GOOGLE_MAPS_API_KEY - Google Maps JavaScript API (essentials)
- Loaded from `.env`, `.env.local`, `.env.production` files
- Also supports shell environment variables with `VITE_` prefix

**Build Configuration:**
- Backend: AppRunner native Go build (1.24.3) with CGO disabled
- Frontend: Vite production builds to `dist/` directory
- Component library: tsup builds to ESM + CJS bundles

## Package Publishing

**Component Library Publishing:**
- Registry: npm.pkg.github.com (GitHub npm registry)
- Package: @chrisandrewsedu/ev-ui
- Main export: `dist/index.js` (CJS), `dist/index.mjs` (ESM)
- Consumed by: CompassV2 (@0.1.12), essentials (@0.1.14), EV-prototypes (@0.1.6)
- Built with: tsup (no Babel/TypeScript compilation—simple bundling)

## Platform Requirements

**Development:**
- Go 1.24.3 (backend)
- Node.js + npm (frontend)
- PostgreSQL database or Supabase connection string
- Optional: Docker for local backend testing

**Production:**
- AWS App Runner (backend Go binary)
- Netlify (CompassV2, essentials, EV-prototypes static deployments)
- Render.com (fallback API endpoint for Netlify redirects)
- PostgreSQL via Supabase (database)
- AWS Secrets Manager (credentials)
- Google Maps API key (for essentials address search)
- BallotReady API key (for politician data)

## Docker Support

**Backend Containerization:**
- Dockerfile: Multi-stage build (golang:1.24.3 → distroless/base-debian12)
- Binary: Static Linux amd64 executable
- Port: 5050 (internal)
- Non-root user: nonroot:nonroot
- Purpose: Local testing or alternative deployment

---

*Stack analysis: 2026-02-17*
