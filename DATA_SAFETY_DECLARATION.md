# NutriMarket - Google Play Data Safety Declaration

**Application Name:** NutriMarket (clev_ai)  
**Package Name:** com.clevai.clev_ai  
**Target Release Track:** Internal Testing & Production  
**Target CPMK:** CPMK 6 - Security, Automated CI/CD Pipeline, & App Store Release  

---

## 1. Overview of Data Safety Policies
NutriMarket is committed to user data privacy, transparency, and data minimization. This document outlines all user data types collected, shared, and encrypted within the application, conforming strictly to the Google Play Store Data Safety Guidelines and Indonesian Personal Data Protection Law (UU PDP No. 27 Tahun 2022).

---

## 2. Security Practices
* **Encryption in Transit:** All data sent between the NutriMarket client application and backend servers (Supabase Cloud BaaS and Groq Cloud LLM) is encrypted in transit using industry-standard TLS 1.3 / HTTPS.
* **Encryption at Rest:** Sensitive authentication credentials and user session tokens are encrypted using `SecureStorageService` with AES / salted obfuscation before persisting to local storage.
* **Account Deletion:** Users can request the permanent deletion of their account, health profile, dietary history, and order logs through the in-app settings or by contacting privacy@nutrimarket.id.
* **Independent Security Review:** Code obfuscated using ProGuard/R8 rules and Flutter Dart binary obfuscation (`--obfuscate --split-debug-info`).

---

## 3. Data Collection and Sharing Matrix

| Data Category | Data Type | Collected? | Shared? | Purpose of Processing | Ephemeral / Stored |
|:---|:---|:---:|:---:|:---|:---|
| **Personal Info** | Name (Nama Lengkap) | Yes | No | Account management, order delivery recipient | Stored (Cloud Database) |
| **Personal Info** | Email Address | Yes | No | Authentication (Supabase Auth), account recovery, invoices | Stored (Cloud Database) |
| **Personal Info** | User IDs (UUID) | Yes | No | Multitenant Row Level Security (RLS) data partitioning | Stored (Encrypted) |
| **Financial Info** | Purchase History | Yes | No | Order tracking, transaction history, billing reconciliation | Stored (Cloud Database) |
| **Financial Info** | Payment Method (VA/QRIS) | Yes | Shared (Sandbox Gateway) | Payment processing via Midtrans Gateway simulator | Ephemeral / Reference Only |
| **Health & Fitness** | Dietary Preferences & Allergies | Yes | No | AI nutritionist dietary recommendations, safe meal filtering | Stored (Cloud Database) |
| **Health & Fitness** | Age, Height, Weight, Activity | Yes | No | Health profile setup, personalized daily caloric targets | Stored (Cloud Database) |
| **Location** | Approximate / Delivery Address | Yes | No | Courier delivery routing, shipping fee calculation | Stored (User Addresses) |
| **Messages** | AI Nutritionist Consultation Logs | Yes | Shared (AI Cloud API) | Generating tailored nutritional advice via Groq LLM API | Stored (Cloud Sync) |
| **App Activity** | Crash Logs & Diagnostics | Yes | No | NetworkRetryHelper error logging, performance telemetry | Ephemeral (Session-only) |
| **Device Identifiers** | Device Notification Token | Yes | No | Push notification delivery for order status & promotions | Stored (Local Service) |

---

## 4. Third-Party Service Disclosure
1. **Supabase Cloud (PostgreSQL BaaS & Auth):** Used for backend database storage, identity provider (Email & Google OAuth), and Row Level Security isolation.
2. **Groq Cloud LLM API:** Used exclusively for ephemeral natural language processing of nutritional queries without permanent storage of user identities.
3. **Midtrans / QRIS Payment Gateway Sandbox:** Used for payment authorization and webhook callback verification. No raw credit card credentials are ever stored by NutriMarket.
4. **Flutter Local Notifications Plugin:** Used exclusively on-device for status bar alerts.
