# Caramel Kitchen v2.0 - Project Documentation & Phases

Caramel Kitchen v2.0 is a next-generation recipe and meal-planning platform powered by AI and a pgvector-based Taste Engine. The backend is built with Elixir and Phoenix, prioritizing high concurrency, fault tolerance, and low-latency vector similarity searches.

Below is the comprehensive roadmap detailing completed work and upcoming phases.

---

## 🟢 Phase 0: Environment & Database Architecture (Completed)

We established the foundational infrastructure, ensuring strict compilation, robust caching, and a highly optimized database schema.

- [x] **Supabase Integration**: Connected to hosted PostgreSQL via Session Pooler.
- [x] **Vector Database**: Enabled `pgvector` and configured Ecto Postgrex custom types to handle vector embeddings.
- [x] **HNSW Indexing**: Created high-performance `HNSW` indexes for cosine similarity searches on the `taste_vector` columns in `users` and `recipes`.
- [x] **Core Schemas**: Built robust Ecto schemas for Users, Recipes, Interactions, Meal Plans, and Shopping Lists.
- [x] **Background Jobs**: Integrated Oban for async processing (video transcoding, taste vector recalculations).
- [x] **Database Seeding**: Created an idempotent `seeds.exs` script that provisions an admin creator account and generates 30 comprehensive recipes with macronutrients and taste tags.
- [x] **Strict Compilation**: Cleared all Dialyzer warnings, fixed unreachable patterns, enforced type checking, and implemented resilient try/catch blocks for the `ConCache`/`Redix` caching layers.

---

## 🟡 Phase 1: Core API & Security (In Progress)

This phase focuses on exposing the data securely and implementing the complex 6-dimensional filtering system.

- [x] **Server Configuration**: Replaced missing Bandit adapter with standard `plug_cowboy` and stabilized endpoint boot sequence.
- [x] **Guardian JWT**: Implemented access and refresh token generation. Added explicit `typ: "access"` checks in the authentication plugs.
- [x] **6-Dimensional Filtering**: Built Ecto query builders to filter recipes by dietary flags, taste profiles, max prep/cook time, difficulty, dish category, and primary cooking method.
- [x] **Rate Limiting Setup**: Configured the `Hammer` backend to protect auth, API, and AI routes.
- [ ] **Security Testing**: Validate Guardian refresh token rotation logic and write unit tests for Hammer rate limiting to ensure legitimate traffic isn't blocked.
- [x] **API Documentation**: Generate Swagger/OpenAPI specifications for the mobile team.

---

## ⚪ Phase 2: Taste System & Engagement Tracking (Upcoming)

Bringing the platform to life by making the feed respond intelligently to user interactions.

- [x] **Vector Updater GenServer**: Finalize the `TasteEngine.VectorUpdater` which listens to user actions (cook, save, rate) and computes a weighted delta to apply to the user's personal taste vector in the background.
- [x] **Personalised Feed Ranker**: Implement the `FeedRanker` to query `pgvector` using cosine distance `<=>` operator, returning recipes that mathematically align with a user's evolving palate.
- [x] **Engagement Workers**: Schedule Oban cron jobs (`EngagementWorker`) to aggregate raw interaction events into `view_count`, `save_count`, and `avg_rating` fields on the recipes table.
- [x] **Cache Invalidation**: Ensure that when a user's taste vector shifts, their L2 Redis feed cache is invalidated and rebuilt.

---

## ⚪ Phase 3: AI Orchestrator & WebSockets (Upcoming)

Integrating GPT-4o and Whisper to create a conversational cooking assistant.

- [ ] **OpenAI Integration**: Connect `AI.Orchestrator` to OpenAI's chat completions API.
- [ ] **Whisper Transcription**: Accept audio blobs from the mobile app, transcribing voice commands into text via the Whisper API.
- [ ] **Streaming Responses (SSE)**: Hook up Phoenix Channels to stream AI text generation chunks via WebSockets back to the client in real-time.
- [ ] **Mocking Adapters**: Build `Mox` and `Bypass` adapters for the test suite to simulate OpenAI responses without consuming actual API credits during CI/CD.

---

## ⚪ Phase 4: Goal-Driven Meal Plans & Monetisation (Upcoming)

Implementing the premium tier features.

- [ ] **Strict JSON Generation**: Prompt engineer GPT-4o to return strictly typed 7-day meal plans based on calorie goals and dietary flags.
- [ ] **Automated Shopping Lists**: Map generated meal plans to shopping lists. Write aggregation logic to sum identical ingredients and group them by supermarket aisle (Produce, Protein, Dairy, etc.).
- [ ] **Stripe Checkout**: Configure Stripe Checkout Sessions for premium subscription upgrades.
- [ ] **Webhook Security**: Implement a custom Phoenix plug to read raw request bodies and verify Stripe HMAC webhook signatures before updating a user's `subscription_tier`.

---

## ⚪ Phase 5: Observability & Production Scale (Upcoming)

Preparing the backend for live user traffic.

- [ ] **CI/CD Pipeline**: Write GitHub Actions workflows to run `mix format`, `mix credo --strict`, `mix dialyzer`, and `mix test` on every pull request.
- [ ] **Clustering**: Configure `libcluster` for Fly.io deployment, ensuring Phoenix PubSub events broadcast across multiple physical server nodes.
- [x] **Telemetry Dashboard**: Expose Erlang VM metrics, Oban queue lengths, and Ecto query latencies to the Phoenix LiveDashboard for real-time monitoring.
- [x] **Log Aggregation**: Integrate Sentry for error tracking and crash reporting.
