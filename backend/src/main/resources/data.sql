-- Fix photo_url column size: Google photo URLs can be 800+ characters
ALTER TABLE users ALTER COLUMN photo_url TYPE TEXT;

-- Remove mock/seed users that were not created through Google Sign-In
DELETE FROM users WHERE google_id IS NULL OR google_id = '';
