-- ============================================================
-- Razak Travel - Supabase SQL Migration
-- Run this in the Supabase SQL Editor (https://mofafnvimnrbonhzyzwr.supabase.co)
-- ============================================================

-- 1. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  names JSONB DEFAULT '{}'::jsonb,
  name TEXT DEFAULT '',
  imageUrl TEXT DEFAULT '',
  image TEXT DEFAULT '',
  descriptions JSONB DEFAULT '{}'::jsonb,
  description TEXT DEFAULT '',
  "createdAt" TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TOURS TABLE
CREATE TABLE IF NOT EXISTS tours (
  id TEXT PRIMARY KEY,
  title JSONB DEFAULT '{}'::jsonb,
  names JSONB DEFAULT '{}'::jsonb,
  name TEXT DEFAULT '',
  "categoryId" TEXT DEFAULT '',
  destination TEXT DEFAULT '',
  description JSONB DEFAULT '{}'::jsonb,
  "descriptionText" TEXT DEFAULT '',
  descriptions JSONB DEFAULT '{}'::jsonb,
  included JSONB DEFAULT '{}'::jsonb,
  "includedItems" JSONB DEFAULT '{}'::jsonb,
  "notIncluded" JSONB DEFAULT '{}'::jsonb,
  "placesToVisit" JSONB DEFAULT '{}'::jsonb,
  "meetingPoint" JSONB DEFAULT '{}'::jsonb,
  "pickupDetails" JSONB DEFAULT '{}'::jsonb,
  "extraInfo" JSONB DEFAULT '{}'::jsonb,
  "whatToBring" JSONB DEFAULT '{}'::jsonb,
  landmark JSONB DEFAULT '{}'::jsonb,
  "guidePhone" JSONB DEFAULT '{}'::jsonb,
  whatsapp JSONB DEFAULT '{}'::jsonb,
  "departureTime" JSONB DEFAULT '{}'::jsonb,
  "returnTime" JSONB DEFAULT '{}'::jsonb,
  "imageUrl" TEXT DEFAULT '',
  "imageUrls" JSONB DEFAULT '[]'::jsonb,
  images JSONB DEFAULT '[]'::jsonb,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  price DOUBLE PRECISION DEFAULT 0,
  date TEXT DEFAULT '',
  "totalSeats" INTEGER DEFAULT 0,
  "bookedSeats" INTEGER DEFAULT 0,
  "reservedSeats" INTEGER DEFAULT 0,
  "booking_count" INTEGER DEFAULT 0,
  "remainingSeats" INTEGER DEFAULT 0,
  "discountEndTime" TEXT DEFAULT '',
  rating DOUBLE PRECISION DEFAULT 0,
  "reviewTexts" JSONB DEFAULT '[]'::jsonb
);

-- 3. DEPARTURES TABLE
CREATE TABLE IF NOT EXISTS departures (
  id TEXT PRIMARY KEY,
  "tourId" TEXT DEFAULT '',
  "departureDate" TEXT DEFAULT '',
  "returnDate" TEXT DEFAULT '',
  "totalSeats" INTEGER DEFAULT 0,
  "bookedSeats" INTEGER DEFAULT 0,
  "availableSeats" INTEGER DEFAULT 0,
  price DOUBLE PRECISION DEFAULT 0,
  status TEXT DEFAULT 'available',
  "meetingPointName" JSONB DEFAULT '{}'::jsonb,
  "meetingAddress" JSONB DEFAULT '{}'::jsonb,
  landmark JSONB DEFAULT '{}'::jsonb,
  "pickupType" TEXT DEFAULT 'meeting_point',
  "pickupInstructions" JSONB DEFAULT '{}'::jsonb,
  "googleMapsUrl" TEXT DEFAULT '',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  "guidePhone" TEXT DEFAULT '',
  "guideWhatsapp" TEXT DEFAULT ''
);

-- 4. BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  "userId" TEXT DEFAULT '',
  "userName" TEXT DEFAULT '',
  "tourId" TEXT DEFAULT '',
  "tourName" TEXT DEFAULT '',
  "categoryId" TEXT DEFAULT '',
  "categoryName" TEXT DEFAULT '',
  price DOUBLE PRECISION DEFAULT 0,
  status TEXT DEFAULT 'pending',
  "createdAt" TEXT DEFAULT '',
  "departureId" TEXT DEFAULT '',
  "departureDate" TEXT DEFAULT '',
  "tourDate" TEXT DEFAULT '',
  "seatCount" INTEGER DEFAULT 1,
  seats INTEGER DEFAULT 1,
  "pickupType" TEXT DEFAULT '',
  "hotelName" TEXT DEFAULT '',
  "userAddress" TEXT DEFAULT '',
  "roomNumber" TEXT DEFAULT '',
  "pickupNotes" TEXT DEFAULT ''
);

-- 5. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  title TEXT DEFAULT '',
  message TEXT DEFAULT '',
  type TEXT DEFAULT '',
  "tourId" TEXT DEFAULT '',
  "targetUserId" TEXT DEFAULT '',
  "read" BOOLEAN DEFAULT FALSE,
  "timestamp" TEXT DEFAULT ''
);

-- 6. USERS TABLE (for admin management)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT DEFAULT '',
  role TEXT DEFAULT 'user',
  "isBanned" BOOLEAN DEFAULT FALSE,
  "fcmToken" TEXT DEFAULT ''
);

-- 7. ENABLE ROW LEVEL SECURITY
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE departures ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 8. CREATE POLICIES FOR PUBLIC ACCESS (anon key)
-- For a travel admin panel, allow full access via the anon key
-- In production, you'd want more restrictive policies

CREATE POLICY "Allow all on categories" ON categories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on tours" ON tours FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on departures" ON departures FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on bookings" ON bookings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on notifications" ON notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on users" ON users FOR ALL USING (true) WITH CHECK (true);

-- 9. STORAGE BUCKETS (run in Storage section of dashboard)
-- Create three buckets:
--   1. 'categories' - public bucket for category images
--   2. 'tours' - public bucket for tour images
--   3. 'reviews' - public bucket for review images
-- Make each bucket public by adding policy:
--   Policy name: "Public Access"
--   SQL: CREATE POLICY "Public Access" ON storage.objects FOR ALL USING (bucket_id = 'categories' OR bucket_id = 'tours' OR bucket_id = 'reviews') WITH CHECK (true);
