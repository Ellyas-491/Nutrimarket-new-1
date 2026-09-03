-- ========================================================
-- NUTRIMARKET - COMPLETE SUPABASE CLOUD DATABASE SCHEMA
-- Jalankan skrip ini di: Supabase Dashboard -> SQL Editor
-- ========================================================

-- 1. TABEL PROFIL PENGGUNA (profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT DEFAULT '',
  age INT DEFAULT 26,
  height_cm NUMERIC DEFAULT 170.0,
  weight_kg NUMERIC DEFAULT 65.0,
  activity_level TEXT DEFAULT 'Moderate',
  dietary_type TEXT DEFAULT 'General Sehat',
  dietary_preferences TEXT[] DEFAULT ARRAY['Rendah Gula', 'Tinggi Serat'],
  food_allergies TEXT[] DEFAULT ARRAY[]::TEXT[],
  health_goal TEXT DEFAULT 'Gaya Hidup Sehat Seimbang',
  is_premium BOOLEAN DEFAULT FALSE,
  is_setup_completed BOOLEAN DEFAULT FALSE,
  address TEXT DEFAULT '',
  address_label TEXT DEFAULT 'Pilih Alamat',
  address_detail TEXT DEFAULT '',
  target_calories INT DEFAULT 2000,
  max_sugar_grams INT DEFAULT 25,
  max_sodium_mg INT DEFAULT 2000,
  target_protein_grams INT DEFAULT 75,
  target_fiber_grams INT DEFAULT 30,
  ai_response_style TEXT DEFAULT 'Medis & Edukatif',
  auto_validate_cart BOOLEAN DEFAULT TRUE,
  ai_voice_output BOOLEAN DEFAULT FALSE,
  default_payment_method TEXT DEFAULT 'QRIS Instant Pay',
  eco_packaging BOOLEAN DEFAULT TRUE,
  include_cutlery BOOLEAN DEFAULT FALSE,
  contactless_delivery BOOLEAN DEFAULT FALSE,
  pin_code TEXT DEFAULT '123456',
  biometrics_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. TABEL KATALOG PRODUK (products)
CREATE TABLE IF NOT EXISTS public.products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  price NUMERIC NOT NULL,
  rating NUMERIC DEFAULT 4.8,
  review_count INT DEFAULT 0,
  image_url TEXT NOT NULL,
  calories INT NOT NULL,
  protein NUMERIC NOT NULL,
  carbs NUMERIC NOT NULL,
  fat NUMERIC NOT NULL,
  fiber NUMERIC NOT NULL,
  sugar NUMERIC NOT NULL,
  sodium NUMERIC NOT NULL,
  suitable_for TEXT[] DEFAULT ARRAY[]::TEXT[],
  ingredients TEXT[] DEFAULT ARRAY[]::TEXT[],
  allergens TEXT[] DEFAULT ARRAY[]::TEXT[],
  nutritionist_name TEXT,
  nutritionist_review TEXT,
  verification_status TEXT DEFAULT 'VERIFIED',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. TABEL FAVORIT PENGGUNA (favorites)
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  product_id TEXT REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, product_id)
);

-- 4. TABEL ALAMAT TERSIMPAN (saved_addresses)
CREATE TABLE IF NOT EXISTS public.saved_addresses (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  label TEXT NOT NULL,
  recipient_name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  full_address TEXT NOT NULL,
  notes TEXT DEFAULT '',
  latitude NUMERIC DEFAULT -6.2255,
  longitude NUMERIC DEFAULT 106.8090,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 5. TABEL PESANAN / TRANSAKSI (orders & order_items)
CREATE TABLE IF NOT EXISTS public.orders (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subtotal NUMERIC NOT NULL,
  delivery_fee NUMERIC NOT NULL,
  service_fee NUMERIC DEFAULT 2000,
  discount NUMERIC DEFAULT 0,
  total NUMERIC NOT NULL,
  status INT DEFAULT 0,
  estimated_delivery TEXT NOT NULL,
  delivery_address TEXT NOT NULL,
  delivery_option TEXT DEFAULT 'Instant Delivery (20-30 Menit)',
  order_notes TEXT DEFAULT '',
  payment_method TEXT NOT NULL,
  payment_reference TEXT DEFAULT 'QRIS-NM-994821',
  delivery_photo_url TEXT DEFAULT '',
  review_json JSONB DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id TEXT REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_image TEXT NOT NULL,
  product_price NUMERIC NOT NULL,
  quantity INT NOT NULL,
  seller_notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. TABEL SESI KONSULTASI AI (chat_sessions & chat_messages)
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  preview TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id TEXT REFERENCES public.chat_sessions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  text TEXT NOT NULL,
  is_user BOOLEAN NOT NULL,
  analysis_json JSONB,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 7. TABEL KERANJANG PENGGUNA CLOUD (user_cart)
CREATE TABLE IF NOT EXISTS public.user_cart (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_image TEXT NOT NULL,
  product_price NUMERIC NOT NULL,
  quantity INT DEFAULT 1,
  seller_notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, product_id)
);

-- ========================================================
-- KEAMANAN: ROW LEVEL SECURITY (RLS)
-- ========================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_cart ENABLE ROW LEVEL SECURITY;

-- Products: Publik bisa membaca (SELECT) & pengguna terotentikasi bisa menambah makanan
CREATE POLICY "Public products are viewable by everyone" ON public.products FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert products" ON public.products FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update products" ON public.products FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete products" ON public.products FOR DELETE TO authenticated USING (true);

-- Profiles: Pengguna hanya bisa baca & ubah data mereka sendiri
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Favorites: Isolasi per User
CREATE POLICY "Users can view own favorites" ON public.favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own favorites" ON public.favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own favorites" ON public.favorites FOR DELETE USING (auth.uid() = user_id);

-- Cart: Isolasi per User
CREATE POLICY "Users can view own cart" ON public.user_cart FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own cart" ON public.user_cart FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own cart" ON public.user_cart FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own cart" ON public.user_cart FOR DELETE USING (auth.uid() = user_id);

-- Addresses: Isolasi per User
CREATE POLICY "Users can view own addresses" ON public.saved_addresses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own addresses" ON public.saved_addresses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own addresses" ON public.saved_addresses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own addresses" ON public.saved_addresses FOR DELETE USING (auth.uid() = user_id);

-- Orders: Isolasi per User
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own order items" ON public.order_items FOR SELECT USING (EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));
CREATE POLICY "Users can insert own order items" ON public.order_items FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

-- Chat: Isolasi per User
CREATE POLICY "Users can view own chat sessions" ON public.chat_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own chat sessions" ON public.chat_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own chat sessions" ON public.chat_sessions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own chat messages" ON public.chat_messages FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own chat messages" ON public.chat_messages FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ========================================================
-- AUTOMATIC TRIGGER: ON NEW USER REGISTER
-- ========================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================================
-- SEED DATA: KATALOG AWAL PRODUK NUTRIMARKET
-- ========================================================
INSERT INTO public.products (id, name, category, price, rating, review_count, image_url, calories, protein, carbs, fat, fiber, sugar, sodium, suitable_for, ingredients, allergens, nutritionist_name, nutritionist_review, verification_status)
VALUES
('prod_1', 'Nasi Merah Ayam Panggang', 'Healthy Meals', 38000, 4.8, 128, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80', 420, 32, 45, 8, 6, 2, 380, ARRAY['Diabetes-friendly', 'Low Sugar', 'High Protein', 'High Fiber', 'Weight Management'], ARRAY['Nasi Merah Organik', 'Dada Ayam Panggang Herb', 'Tumis Buncis & Wortel', 'Minyak Zaitun'], ARRAY[]::TEXT[], 'dr. Alika Rahma, M.Gizi', 'Rendah indeks glikemik, kaya serat dari nasi merah organik dan protein tinggi dada ayam tanpa kulit. Sangat cocok untuk kontrol gula darah.', 'VERIFIED'),
('prod_2', 'Salmon Panggang Saos Lemon', 'Healthy Meals', 45000, 4.9, 95, 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80', 460, 36, 22, 14, 4, 1, 340, ARRAY['Heart-Friendly', 'High Protein', 'Low Sugar', 'Diabetes-friendly', 'Gluten-Free'], ARRAY['Fillet Salmon Segar', 'Saos Lemon Peras', 'Kentang Panggang Herb', 'Asparagus'], ARRAY['Ikan'], 'dr. Budi Santoso, Sp.GK', 'Kaya asam lemak Omega-3 dan protein berkualitas tinggi untuk kesehatan jantung dan pembuluh darah. Tanpa gula tambahan.', 'VERIFIED'),
('prod_3', 'Sup Sayur Ayam Kampung', 'Healthy Meals', 22000, 4.7, 64, 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80', 280, 24, 18, 5, 5, 3, 420, ARRAY['Low Calorie', 'High Protein', 'Geriatric Care', 'Diabetes-friendly'], ARRAY['Daging Ayam Kampung', 'Wortel', 'Brokoli', 'Kentang', 'Seledri'], ARRAY[]::TEXT[], 'dr. Alika Rahma, M.Gizi', 'Kaldu alami tanpa MSG buatan, mudah dicerna dan kaya mikronutrien penting untuk daya tahan tubuh.', 'VERIFIED'),
('prod_4', 'Greek Salad Quinoa Bowl', 'Healthy Meals', 35000, 4.8, 82, 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80', 340, 14, 38, 12, 8, 4, 290, ARRAY['Vegetarian', 'High Fiber', 'Low Sodium', 'Low Sugar', 'Weight Management'], ARRAY['Quinoa Merah & Putih', 'Selada Romaine Organik', 'Tomat Ceri', 'Mentimun', 'Keju Feta', 'Extra Virgin Olive Oil'], ARRAY['Susu'], 'dr. Cindy Permata, M.Sc', 'Sumber serat prebiotik dan antioksidan tinggi. Quinoa memberikan profil asam amino esensial lengkap nabati.', 'VERIFIED'),
('prod_5', 'Greek Yogurt Berries Granola', 'Healthy Snacks', 28000, 4.9, 142, 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=800&q=80', 260, 18, 28, 6, 5, 6, 65, ARRAY['High Protein', 'Probiotic-rich', 'Low Sugar', 'Vegetarian'], ARRAY['Greek Yogurt Plain Tanpa Gula', 'Blueberry Segar', 'Strawberry', 'Granola Oat Bebas Gluten', 'Biji Chia'], ARRAY['Susu'], 'dr. Alika Rahma, M.Gizi', 'Kaya probiotik hidup untuk mikrobioma usus sehat. Gula murni berasal dari buah berry asli.', 'VERIFIED'),
('prod_6', 'Chia Seed Pudding Mangga', 'Healthy Snacks', 20000, 4.6, 53, 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80', 210, 8, 24, 7, 9, 8, 45, ARRAY['High Fiber', 'Vegan', 'Gluten-Free', 'Low Sodium'], ARRAY['Biji Chia Organik', 'Susu Almond Tanpa Gula', 'Puree Mangga Gedong Asli', 'Kelapa Parut Kering'], ARRAY['Kacang Pohon'], 'dr. Cindy Permata, M.Sc', 'Kandungan serat larut air sangat tinggi (9g/porsi) menjaga rasa kenyang lebih lama dan mengontrol penyerapan kolesterol.', 'VERIFIED'),
('prod_7', 'Cold Pressed Green Detox Juice', 'Drinks', 26000, 4.7, 88, 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=800&q=80', 110, 3, 22, 1, 3, 12, 35, ARRAY['Detox', 'No Added Sugar', 'Vegan', 'Low Sodium'], ARRAY['Kale Organik', 'Bayam Jepang', 'Apel Hijau Malang', 'Mentimun', 'Lemon', 'Jahe'], ARRAY[]::TEXT[], 'dr. Budi Santoso, Sp.GK', 'Ekstraksi dingin mempertahankan 100% enzim dan vitamin C alami. Sangat menyegarkan dan rendah kalori.', 'VERIFIED'),
('prod_8', 'Sourdough Roti Gandum Murni', 'Bakery & Cereals', 32000, 4.8, 71, 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80', 180, 7, 34, 2, 4, 1, 190, ARRAY['Low Glycemic', 'Vegan', 'High Fiber', 'No Preservatives'], ARRAY['Tepung Gandum Utuh Organik', 'Air Mineral', 'Ragi Alami (Wild Sourdough Starter)', 'Garam Laut'], ARRAY['Gluten'], 'dr. Cindy Permata, M.Sc', 'Fermentasi lambat 24 jam memecah fitat dan sebagian gluten, menjadikannya jauh lebih ramah lambung dan ramah gula darah.', 'VERIFIED')
ON CONFLICT (id) DO NOTHING;
