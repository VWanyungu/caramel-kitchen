# Caramel Kitchen — Elixir/Phoenix Backend

> *"A warm digital kitchen that thinks, tastes, plans, and guides."*

Production-ready backend for **Caramel Kitchen v2.0** — a taste-intelligent recipe discovery and AI-powered meal planning platform.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Language | Elixir 1.16 + OTP 26 |
| Framework | Phoenix 1.7 (REST + WebSocket Channels) |
| Database | PostgreSQL 16 + pgvector extension |
| Cache | Redis (L2) + ConCache ETS (L1) |
| Background Jobs | Oban (PostgreSQL-backed) |
| AI | OpenAI GPT-4o (streaming) · Whisper STT · OpenAI TTS |
| Auth | Guardian JWT · Bcrypt · Google OAuth |
| Payments | Stripe · RevenueCat |
| Storage | AWS S3 + CloudFront CDN |
| Deploy | Fly.io (2 nodes, rolling deploy) |
| Observability | Telemetry · PromEx · Sentry |

---

## Quick Start

### Prerequisites
- Elixir 1.16+ & Erlang/OTP 26+
- PostgreSQL 16+ with `pgvector` extension: `CREATE EXTENSION vector;`
- Redis 7+

### Setup

```bash
# Clone and install
git clone <repo-url>
cd caramel_kitchen
mix setup          # deps.get + ecto.setup + assets.setup

# Set required env vars (add to ~/.zshrc or .env)
export OPENAI_API_KEY="sk-..."
export GUARDIAN_SECRET_KEY="your-64-char-secret-here"

# Start server
mix phx.server
# API: http://localhost:4000
# LiveDashboard: http://localhost:4000/dev/dashboard
```

### Seed initial data (Phase 0)

```bash
mix run priv/repo/seeds.exs
# Creates: creator@caramelkitchen.app / ChangeMeInProd1
```

---

## Project Structure

```
lib/
├── caramel_kitchen/          # Business logic (no HTTP)
│   ├── accounts/             # Users, auth, taste vectors
│   ├── recipes/              # Recipe CRUD, 6-dim filtering, FTS
│   ├── taste_engine/         # Vector updates (GenServer), feed ranking (ETS)
│   ├── ai/                   # GPT-4o streaming, Whisper, prompt builder
│   ├── meal_plans/           # AI 7-day plan generation, meal swapping
│   ├── shopping/             # Auto-generated lists, WhatsApp share
│   ├── content/              # S3 upload pipeline, video processing
│   ├── monetisation/         # Stripe webhooks, subscription management
│   ├── analytics/            # Telemetry, creator dashboard stats
│   └── workers/              # Oban background jobs
└── caramel_kitchen_web/      # HTTP layer only
    ├── endpoint.ex
    ├── router.ex             # 40+ routes, 5 pipelines
    ├── plugs/                # Auth, RateLimit, VerifyStripe
    ├── channels/             # AI streaming, feed updates, voice cooking
    └── controllers/          # 14 controllers
```

---

## Key Architectural Decisions

### Taste Engine
- Each user has a **VECTOR(8)** column (`taste_vector`) in PostgreSQL via pgvector
- Dimensions: `[sour, sweet, tangy, spicy, savory, bitter, umami, mild]`
- Each recipe has a matching `taste_profile` VECTOR(8)
- Feed ranking uses **cosine similarity** (`<=>` operator) + engagement score
- Updates buffered in `VectorUpdater` GenServer, flushed every 2s or 100 events

### Two-Tier Cache
- **L1 (ConCache/ETS):** In-process, nanosecond reads, 30s TTL
- **L2 (Redis):** Cluster-shared, survives restarts, configurable TTL
- `Cache.get_or_store/3` handles fallthrough automatically

### AI Streaming
- `AI.Orchestrator` GenServer holds session history (last 10 turns)
- GPT-4o response streams via `Req` → parsed SSE → `Phoenix.PubSub.broadcast`
- WebSocket channel `ai:{session_id}` pushes tokens to client in real-time

### OTP Supervision (ordered)
```
Repo → PubSub → Redis → Hammer → Oban →
TasteEngine.Supervisor → AI.Supervisor → MealPlans.Supervisor →
Content.Supervisor → FunWithFlags → Endpoint
```

---

## API Overview

| Auth Level | Routes |
|-----------|--------|
| Public | `POST /auth/*`, `GET /recipes/*`, `GET /categories`, `GET /health` |
| JWT Required | Feed, interactions, taste, shopping, profile, courses |
| JWT + Premium | AI chat/voice, meal plan generation, offline downloads |
| JWT + Creator | Admin recipe CRUD, video upload, analytics |
| JWT + Admin | User management, system stats |
| Stripe Signature | `POST /webhooks/stripe` |

Full endpoint list: see `lib/caramel_kitchen_web/router.ex`

---

## Running Tests

```bash
mix test                        # All tests
mix test --only accounts        # Tag-filtered
mix test test/caramel_kitchen/  # Context tests only
mix coveralls                   # With coverage report
mix credo --strict              # Linting
mix dialyzer                    # Type checking
mix sobelow --config            # Security scan
```

---

## Background Jobs (Oban)

| Queue | Workers | Purpose |
|-------|---------|---------|
| `content` | PublishRecipeWorker | Scheduled recipe publishing |
| `email` | SendEmailWorker | Transactional emails (5 retries) |
| `analytics` | EngagementWorker | Async view/save/cook counters |
| `maintenance` | TasteVectorCleanupWorker | Daily vector normalisation at 2AM |

---

## Deployment (Fly.io)

```bash
# Deploy to staging
fly deploy --app caramel-kitchen-api-staging --remote-only

# Run migrations (zero-downtime)
fly ssh console -a caramel-kitchen-api \
  --command "/app/bin/caramel_kitchen eval 'CaramelKitchen.Release.migrate()'"

# Scale to 3 nodes
fly scale count 3 --app caramel-kitchen-api
```

### Required Fly Secrets
```bash
fly secrets set \
  DATABASE_URL="postgres://..." \
  SECRET_KEY_BASE="..." \
  GUARDIAN_SECRET_KEY="..." \
  OPENAI_API_KEY="sk-..." \
  STRIPE_SECRET_KEY="sk_live_..." \
  STRIPE_WEBHOOK_SECRET="whsec_..." \
  STRIPE_PREMIUM_PRICE_ID="price_..." \
  AWS_ACCESS_KEY_ID="..." \
  AWS_SECRET_ACCESS_KEY="..." \
  S3_BUCKET="caramel-kitchen-videos" \
  CDN_URL="https://cdn.caramelkitchen.app" \
  REDIS_URL="redis://..."
```

---

## Phase 0 Go-Live Checklist

- [ ] `mix ecto.migrate` succeeds with all 4 migrations
- [ ] Seeds create creator account successfully
- [ ] 30+ recipes uploaded and published via Admin API
- [ ] Each recipe has: taste_tags, primary_method, dish_category, dietary_flags, video_url
- [ ] `GET /ready` returns `{status: "ready"}` (DB + Redis both healthy)
- [ ] Stripe webhook endpoint configured: `POST https://api.caramelkitchen.app/webhooks/stripe`
- [ ] STRIPE_PREMIUM_PRICE_ID and STRIPE_CREATOR_PRICE_ID set in production
- [ ] OpenAI API key active and quota sufficient
- [ ] S3 bucket created with CORS policy allowing PUT from app domain
- [ ] CloudFront distribution pointing to S3 bucket
- [ ] Sentry DSN configured for error tracking
- [ ] GitHub Actions CI passing on `main` branch

---

## Architecture Reference

See `caramel-kitchen-backend-reference.pdf` for:
- Full file structure with annotations
- Database schema + index strategy
- Complete API endpoint contract
- OTP supervision tree diagram
- Taste engine algorithm detail
- AI integration + prompt templates
- Security architecture
- Environment variables reference
- Getting started guide

---

*Caramel Kitchen Backend — Development Plan v2.0 · 54 files · 6,296 lines · 9 contexts · 40+ routes*
