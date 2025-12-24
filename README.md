# 🧠 Dementia Care Application

## 📌 Overview
The **Dementia Care Application** is a mobile-based system designed to support individuals living with dementia by helping them track emotional well-being and preserve meaningful memories.  
The application enables patients to record moods, store images in a personal gallery, and manage personal profile information securely.

To enhance accessibility and cognitive support, the system integrates the **Gemini API** to automatically generate textual descriptions for uploaded images.

---

## 🎯 Objectives
- Support emotional tracking for dementia patients through mood logging.
- Provide a visual memory gallery enhanced with automatically generated image descriptions.
- Improve accessibility for users with memory or visual challenges.
- Securely store and manage patient data.

---

## 🛠️ Technologies Used
- **Frontend:** Flutter  
- **Backend & Database:** Supabase (PostgreSQL)  
- **Authentication:** Supabase Auth  
- **Storage:** Supabase Storage  
- **AI Integration:** Google Gemini API (Image Description Generation)  
- **Design:** Figma  

---

## 🧩 System Features

### 👤 User Profile Management
- Create and manage patient profiles
- Store personal details such as name, email, date of birth, and country
- Upload and display profile pictures

---

### 😊 Mood Tracking
- Select predefined moods
- Add optional descriptions to mood entries
- Automatically timestamp mood logs
- View historical mood records

---

### 🖼️ Image Gallery with AI Descriptions
- Upload personal images to the gallery
- Automatically generate image descriptions using the **Gemini API**
- Store AI-generated descriptions alongside images
- Improve memory recall and accessibility through descriptive text

---

### 🤖 AI Image Description (Gemini API)
When a user uploads an image, the system:
1. Sends the image to the **Gemini API**
2. Receives an AI-generated textual description
3. Stores the description in the `gallery` table
4. Displays the description alongside the image in the application

This feature supports users who may struggle to remember visual context or interpret images independently.

---

### 🔐 Authentication
- Secure login and registration using Supabase Authentication
- Each user profile is linked to a unique authenticated account

---

## 🗄️ Database Structure
The system uses a relational database with the following tables:
- **profile** – stores patient personal information
- **mood** – predefined mood categories
- **patient_mood** – logs patient mood entries
- **gallery** – stores uploaded images and AI-generated descriptions

---

## 🧠 System Architecture
- Flutter handles user interaction and presentation
- Supabase manages authentication, data storage, and file storage
- Gemini API provides AI-powered image description generation
- Data flow is documented using Gane–Sarson Data Flow Diagrams (DFDs)

---

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK
- Supabase account
- Google Gemini API key
- Git

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/dementia-care-app.git
2. Navigate into the project directory:
    ```bash
    cd dementia-care-app
3. Install dependencies:
    ```bash
    flutter pub get
4. Configure environment variables:

  - Supabase URL
  
  - Supabase Anon Key
  
  - Gemini API Key

5. Run the application:
    ```bash
    flutter run

### 🔮 Future Enhancements

- Caregiver monitoring dashboard

- Mood trend visualizations

- Text-to-speech for image descriptions

- Reminder notifications

- Multi-language support

### 👨‍🎓 Author

Bret Muchoni
Final Year Computer Systems Engineering Student

### 📄 License

This project is intended for academic and learning purposes.
