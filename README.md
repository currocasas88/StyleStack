# StyleStack

AI-powered closet management. Upload photos of your wardrobe, get outfit suggestions based on what you own and what's trending.

**Status: Validation phase** — not yet building. Repo scaffolded for when we do.

## The Bet
Existing closet apps have an AI credibility problem. Suggestions are random, weather-blind, and repeat the same combos. StyleStack wins by getting suggestions right from day one.

## Stack (decided, not yet built)
- React Native (Expo) + TypeScript
- Supabase (auth + Postgres + storage)
- Anthropic API (garment classification + outfit logic)
- Photoroom API (background removal)
- Zustand (state), Expo Router (navigation)

## Project Structure
```
src/
  api/          # Anthropic, Photoroom, weather API clients
  components/   # Shared UI components
  hooks/        # Custom React hooks
  lib/          # Supabase client, utilities
  screens/      # App screens (Expo Router pages)
  store/        # Zustand stores
  types/        # TypeScript types — data model lives here
docs/           # Architecture, decisions, API contracts
tests/          # Unit + integration tests
.claude/        # Claude Code context (CLAUDE.md)
```

## Setup (when building starts)
```bash
npm install
cp .env.example .env.local   # fill in your keys
npx expo start
```

## Validation
Data and findings: Google Drive → 05 - StyleStack → 02 — Research & Validation
Context doc: Google Drive → 05 - StyleStack → 00 — Context & Decisions
