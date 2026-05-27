<div align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" style="display: inline-block; margin: 2px;" />
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" style="display: inline-block; margin: 2px;" />
  </a>
  <a href="https://supabase.com">
    <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" style="display: inline-block; margin: 2px;" />
  </a>
  <a href="https://deepmind.google/technologies/gemini/">
    <img src="https://img.shields.io/badge/Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white" style="display: inline-block; margin: 2px;" />
  </a>
</div>
<br/>

<h1 align="center">DietLog: AI-Powered Nutrition Orchestration</h1>

DietLog is a high-fidelity Health & Fitness platform designed to bridge the gap between complex nutritional tracking and seamless user experience. It transforms live camera feeds into actionable dietary intelligence using multimodal AI analysis and deterministic state management.

---

## 🚀 Project Perspective

### What is DietLog?
DietLog is a premium AI orchestration engine for automated nutrition logging. It moves beyond manual calorie counting by providing deep technical insights into user meals, allowing users to understand their macro-nutritional intake simply by pointing their device camera at their food.

### Core Capabilities
* **Multimodal Feature Extraction:** Analyzes live camera frames utilizing the `gemini-2.0-flash` model via Base64 payload encoding to accurately identify food items.
* **Strict Schema Inference:** Enforces a rigid JSON guardrail on the Large Language Model (LLM) to extract highly structured macro-nutritional data (Calories, Proteins, Carbs, Fats) with calculated confidence scores.
* **Synchronous Cloud Authentication:** Utilizes Supabase Auth with cached session pointers to ensure zero-latency routing and secure inference pipeline execution.
* **Hybrid Data Persistence:** Combines local Hive NoSQL caching for instantaneous metric loads with secure Supabase PostgreSQL storage for cloud-synced nutrition logs.
* **Real-time UX Updates:** Implements Riverpod StateNotifier streams for reactive, lag-free UI state synchronization during asynchronous database operations.

---

## 🛠 Architecture & Tech Stack

Built on a robust **Clean Architecture** utilizing the Repository Pattern to maintain strict separation of concerns across the Presentation, Logic, and Data layers.

* **Frontend Engineering:** Flutter (Mobile), Dart, Riverpod (State Management), Camera & Image Picker plugins.
* **AI & Machine Learning Engine:** Google Gemini Vision API (Multimodal LLM Inference via Dio HTTP Client).
* **Backend Infrastructure (BaaS):** Supabase (PostgreSQL, JWT Authentication, Cloud Storage).
* **Local Caching:** Hive (NoSQL, Encrypted Key-Value pairs).
* **Database Security:** Row-Level Security (RLS) on storage buckets ensuring strict `authenticated` access only.

---

## ⚙️ Deployment & Execution

### Prerequisites
* Flutter SDK (3.x.x+)
* Dart SDK
* Supabase Project (Database & Storage configured with strict RLS policies)
* Google Gemini API Key

### Build Instructions

1. **Clone the repository**
```bash
   git clone [https://github.com/Osamsami/dietlog.git](https://github.com/Osamsami/dietlog.git)
   cd dietlog
   ```

2. **Fetch Dependencies**
```bash
   flutter pub get
   ```

3. **Environment Configuration**
   Create a `.env` file in the root directory to securely inject credentials:
```env
   SUPABASE_URL="[https://your-project.supabase.co](https://your-project.supabase.co)"
   SUPABASE_ANON_KEY="your-anon-key"
   GEMINI_API_KEY="your-gemini-key"
   ```

4. **Compile & Run**
```bash
   flutter run
   ```
   *(For optimized production execution with Ahead-Of-Time compilation, execute `flutter build apk --release`)*

---

## 🧠 Engineering Leadership

The DietLog ecosystem was architected with a strict focus on high-precision state management, secure database interactions, and seamless AI workflows.

* **Osam Sami** - *System Architect & AI/ML Lead* 
  * Engineered the generative AI Inference Pipeline, implemented Clean Architecture scaffolding, and deployed the Cloud Database Infrastructure.

<div align="center">
  <br/>
  <i>DietLog: Precision in Every Pixel, Nutrition in Every Scan.</i>
</div>
