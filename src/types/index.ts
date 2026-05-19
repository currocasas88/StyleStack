/**
 * StyleStack — Core Data Model
 *
 * Design principles:
 * - Minimal: only fields needed for core features (upload, tag, suggest, track)
 * - Privacy-first: no PII beyond auth; image paths are internal, URLs generated on-demand
 * - Extensible: nullable fields allow gradual enrichment without schema breaks
 * - Single source of truth: Supabase Postgres; types mirrored here for TypeScript
 */

// ─── User ─────────────────────────────────────────────────────────────────────

export interface UserPreferences {
  style_tags?: string[];        // ['minimal', 'streetwear', 'classic'] — user-selected at onboarding
  location?: string;            // city only, for weather API — never stored with PII
  units: 'metric' | 'imperial';
}

// ─── Garment ──────────────────────────────────────────────────────────────────
// Core entity. One row per physical item of clothing.

export type GarmentCategory =
  | 'top' | 'bottom' | 'dress' | 'outerwear'
  | 'shoes' | 'bag' | 'accessory' | 'other';

export type Season = 'spring' | 'summer' | 'autumn' | 'winter' | 'all';

export interface Garment {
  id: string;
  user_id: string;
  created_at: string;

  // Storage path (internal). Call getSignedUrl() to get a time-limited URL.
  image_path: string;

  // AI-extracted metadata — null until async processing completes
  category: GarmentCategory | null;
  colors: string[];             // ['navy', 'white'] — primary colors detected
  brand: string | null;
  tags: string[];               // ['casual', 'linen', 'lightweight']
  season: Season[];             // can belong to multiple seasons

  // User overrides — user can correct any AI mistake
  user_category?: GarmentCategory;
  user_tags?: string[];
  user_notes?: string;

  // Wear tracking — drives "most worn" and "unworn" surfaces
  times_worn: number;
  last_worn_at: string | null;

  is_archived: boolean;         // soft delete only — never hard delete
}

// ─── Outfit ───────────────────────────────────────────────────────────────────
// A combination of garments. AI-suggested or user-created.

export type OutfitOccasion = 'casual' | 'work' | 'evening' | 'sport' | 'travel';

export interface WeatherContext {
  temp_c: number;
  condition: string;            // 'sunny' | 'rainy' | 'cold' — from OpenWeather
  location: string;             // city name only
}

export interface Outfit {
  id: string;
  user_id: string;
  created_at: string;
  garment_ids: string[];        // ordered: top → bottom → shoes → accessories

  source: 'ai' | 'user';
  occasion?: OutfitOccasion;
  weather_context?: WeatherContext;

  // Feedback loop — what trains future suggestions
  rating?: 1 | 2 | 3 | 4 | 5;
  worn_at?: string;             // null = suggested but not logged as worn
  is_saved: boolean;
}

// ─── Upload Job ───────────────────────────────────────────────────────────────
// Tracks async batch upload progress. Users see this in the UI while processing.

export type UploadStatus = 'pending' | 'processing' | 'done' | 'failed';

export interface UploadJob {
  id: string;
  user_id: string;
  created_at: string;
  garment_ids: string[];        // populated as each garment is processed
  total: number;
  processed: number;
  status: UploadStatus;
  error?: string;
}

// ─── API Response Shapes ──────────────────────────────────────────────────────

export interface GarmentClassification {
  category: GarmentCategory;
  colors: string[];
  brand: string | null;
  tags: string[];
  season: Season[];
  confidence: number;           // 0–1
}

export interface OutfitSuggestion {
  garments: Pick<Garment, 'id' | 'image_path' | 'category' | 'colors'>[];
  reasoning: string;
  occasion: OutfitOccasion;
  weather_relevant: boolean;
}
