/// Intelligent built-in knowledge response engine for Synvero AI Assistant.
///
/// Provides deep, contextual, and structured answers across:
/// - Study & Learning methodologies (Pomodoro, Active Recall, Feynman, Spaced Repetition)
/// - Programming & Computer Science (Java, Python, Flutter, C++, Web, DSA, Databases)
/// - Fitness & Exercise routines (Upper body, Lower body, PPL, HIIT, Recovery)
/// - Nutrition & Diet planning (Protein sources, Calories, Meal plans, Hydration)
/// - Habit Building & Productivity (Atomic habits, Beating procrastination, Focus)
/// - Multi-lingual Q&A (Marathi, Hindi, English)
class AIResponseEngine {
  /// Generates a comprehensive and helpful response based on user input and active category.
  static String getResponse({
    required String prompt,
    required String category,
    String? userName,
  }) {
    final cleanPrompt = prompt.trim();
    final lower = cleanPrompt.toLowerCase();
    final name = userName ?? 'Friend';

    // 0. Marathi & Hindi Native Phrases
    if (_isMarathiGreeting(lower) || _isHindiGreeting(lower)) {
      return 'नमस्कार $name! 🙏 मी तुमचा Synvero AI सहाय्यक आहे.\n\nमी तुम्हाला पुढील गोष्टींमध्ये मदत करू शकतो:\n• 📚 **अभ्यास (Study)**: अवघड विषय समजून घेणे, अभ्यासाचे वेळापत्रक बनवणे\n• 🏋️ **फिटनेस (Fitness)**: कसरत, व्यायाम आणि वर्कआउट रूटीन\n• 🥗 **आहार (Nutrition)**: निरोगी आहार, प्रथिने (Protein) आणि डाएट प्लॅन\n• ⚡ **सवयी (Habits)**: नवीन चांगल्या सवयी लावणे आणि आळस घालवणे\n\nआज तुम्हाला काय जाणून घ्यायचे आहे? विचारा!';
    }

    if (lower.contains('kasa ahes') || lower.contains('kasa aahes') || lower.contains('kase ahat') || lower.contains('kaise ho') || lower.contains('kaisa hai')) {
      return 'मी अगदी मजेत आहे! 😊 धन्यवाद विचारल्याबद्दल. तुम्ही कसे आहात, $name?\n\nआजचा तुमचा अभ्यास, व्यायाम किंवा कामांचे काय नियोजन आहे? मी तुम्हाला मदत करू शकेन!';
    }

    if (lower.contains('kay karu') || lower.contains('kay karat ahes') || lower.contains('kya karu') || lower.contains('kya chal raha hai')) {
      return 'मी तुम्हाला तुमच्या ध्येयांपर्यंत पोहोचवण्यासाठी मदत करत आहे! 🎯\n\nतुम्ही Synvero मध्ये:\n1. आजचे **Tasks** तपासून पूर्ण करू शकता.\n2. **Habits** ट्रॅक करून तुमची Streak टिकवू शकता.\n3. **Study Timer** वापरून २५ मिनिटे Pomodoro फोकस सेशन करू शकता.\n\nतुम्हाला आत्ता कशाची सुरुवात करायची आहे?';
    }

    if (lower.contains('abhyas') || lower.contains('study kashi karu') || lower.contains('padhai') || lower.contains('man lagat nahi')) {
      return '📚 **अभ्यासात मन लावण्यासाठी आणि प्रभावी अभ्यासासाठी ५ सुवर्ण नियम:**\n\n'
          '1. **पोमोडोरो पद्धत (Pomodoro Technique)**: २५ मिनिटे शांततेत अभ्यास करा आणि ५ मिनिटांचा ब्रेक घ्या. (Synvero मधील **Timer** टॅब वापरा!)\n'
          '2. **मोबाईल दूर ठेवा**: अभ्यास करताना सोशल मीडिया नोटिफिकेशन्स बंद करा.\n'
          '3. **ऍक्टिव्ह रिकॉल (Active Recall)**: फक्त वाचण्यापेक्षा वाचलेले आठवून स्वतःच्या शब्दांत लिहून काढा.\n'
          '4. **फेनमन तंत्र (Feynman Technique)**: जो विषय शिकलात, तो लहान मुलाला समजावून सांगतोय असा स्वतःलाच शिकवा.\n'
          '5. **दररोज लहान उद्दिष्टे (Micro-goals)**: दिवसातून १-२ महत्त्वाचे विषय संपवण्याचे निश्चित करा.\n\n'
          'तुम्हाला कोणत्या विषयाचा अभ्यास करायचा आहे? मला सांगा, मी सोप्या भाषेत समजावून सांगेन!';
    }

    if (lower.contains('vyayam') || lower.contains('kasrat') || lower.contains('fitness tips') || lower.contains('vajan kami') || lower.contains('weight loss')) {
      return '🏋️ **फिटनेस आणि उत्तम आरोग्यासाठी महत्त्वाच्या टिप्स:**\n\n'
          '1. **सातत्य (Consistency)**: दररोज किमान ३० मिनिटे जलद चालणे, धावणे किंवा व्यायाम करा.\n'
          '2. **वजन नियंत्रणासाठी**: दररोज कॅलरी डेफिसिट (थोडे कमी कॅलरी खाणे) आणि पुरेसे पाणी (३-४ लिटर) प्या.\n'
          '3. **प्रथिने (Protein)**: आहारात डाळी, पनीर, अंडी किंवा स्प्राउट्सचा (मोड आलेली कडधान्ये) समावेश करा.\n'
          '4. **झोप**: स्नायूंच्या रिकव्हरीसाठी ७-८ तास गाढ झोप अतिशय आवश्यक आहे.\n\n'
          'Synvero मधील **Fitness** टॅबमध्ये जाऊन तुम्ही तुमचे वर्कआउट्स आणि प्रोग्रेस नोंदवू शकता!';
    }

    // 1. Greetings & Personal Identity (English)
    if (_isGreeting(lower)) {
      return 'Hello $name! 👋 I am your Synvero AI Assistant.\n\nI can help you with:\n• 📚 **Study & Tech**: Explaining complex topics, study strategies, code concepts\n• 🏋️ **Fitness**: Custom workout splits, proper exercise form, HIIT\n• 🥗 **Nutrition**: High-protein meal plans, calorie targets, hydration\n• ⚡ **Habits & Focus**: Beating procrastination, Pomodoro routines\n\nWhat would you like to explore today?';
    }

    if (lower == 'who are you' || lower == 'what can you do' || lower.contains('your name')) {
      return "I'm Synvero AI, your built-in personal growth and study companion! 🚀\n\nI'm designed to help you build bulletproof daily habits, master difficult study topics, plan nutritious meals, and stay consistent with your workout goals.\n\nTry asking me:\n• 'What is Java?'\n• 'How to study effectively?'\n• 'High-protein vegetarian breakfast ideas'\n• 'Upper body workout plan'";
    }

    if (lower == 'thank you' || lower == 'thanks' || lower.contains('thank u') || lower.contains('dhanyavad')) {
      return 'You are very welcome, $name! 😊 Keep showing up every day. Consistency is what turns daily actions into massive results. Let me know if you need anything else!';
    }

    // 2. Specific Programming & Tech Topics
    if (lower.contains('java') && !lower.contains('javascript')) {
      return _explainJava();
    }
    if (lower.contains('python')) {
      return _explainPython();
    }
    if (lower.contains('flutter') || lower.contains('dart')) {
      return _explainFlutter();
    }
    if (lower.contains('javascript') || lower.contains('js')) {
      return _explainJavaScript();
    }
    if (lower.contains('c++') || lower == 'cpp') {
      return _explainCpp();
    }
    if (lower.contains('dsa') || lower.contains('data structure') || lower.contains('algorithm')) {
      return _explainDSA();
    }
    if (lower.contains('database') || lower.contains('sql') || lower.contains('supabase')) {
      return _explainDatabase();
    }

    // Tech Founders & Organizations
    if ((lower.contains('founder') || lower.contains('who started') || lower.contains('who created') || lower.contains('who built')) && lower.contains('google')) {
      return _explainGoogleFounder();
    }
    if ((lower.contains('founder') || lower.contains('who started')) && lower.contains('microsoft')) {
      return '💻 **Founders of Microsoft:**\n\nMicrosoft was founded on **April 4, 1975** by **Bill Gates** and **Paul Allen** in Albuquerque, New Mexico.\n\n📌 **Key Milestones:**\n• Created MS-DOS for IBM personal computers, followed by Windows operating system.\n• Current CEO: Satya Nadella (since 2014).\n• Major products: Windows, Azure Cloud, Office 365, and Xbox.';
    }
    if ((lower.contains('founder') || lower.contains('who started')) && (lower.contains('apple') || lower.contains('iphone'))) {
      return '🍎 **Founders of Apple:**\n\nApple was founded on **April 1, 1976** by **Steve Jobs**, **Steve Wozniak**, and **Ronald Wayne** in Los Altos, California.\n\n📌 **Key Milestones:**\n• Revolutionized personal computing with Apple II and Macintosh.\n• Redefined smartphones with the original iPhone launched by Steve Jobs in 2007.\n• Current CEO: Tim Cook (since 2011).';
    }
    if ((lower.contains('founder') || lower.contains('who started')) && (lower.contains('meta') || lower.contains('facebook'))) {
      return '👥 **Founder of Meta / Facebook:**\n\nFacebook was founded in **February 2004** by **Mark Zuckerberg** along with his Harvard roommates.\n\n📌 **Key Facts:**\n• Renamed to **Meta** in 2021 to reflect focus on the Metaverse, PyTorch, and LLaMA AI.\n• Owns Instagram, WhatsApp, Messenger, and Threads.';
    }
    if ((lower.contains('founder') || lower.contains('who started')) && (lower.contains('tesla') || lower.contains('spacex'))) {
      return '🚀 **Founders of Tesla & SpaceX:**\n\n• **Tesla**: Founded in July 2003 by engineers **Martin Eberhard** and **Marc Tarpenning**. **Elon Musk** led the Series A investment in 2004 and has served as CEO since 2008.\n• **SpaceX**: Founded in March 2002 by **Elon Musk** with the goal of reducing space transportation costs and enabling Mars exploration.';
    }
    if (lower.contains('photosynthesis')) {
      return '🌿 **What is Photosynthesis?**\n\nPhotosynthesis is the biological process by which green plants, algae, and cyanobacteria convert sunlight, water, and carbon dioxide into chemical energy (glucose) and oxygen.\n\n🧪 **Chemical Equation:**\n6CO₂ + 6H₂O + Sunlight ➔ C₆H₁₂O₆ (Glucose) + 6O₂ (Oxygen)\n\n📌 **Stages:**\n1. Light-dependent reactions in thylakoids (absorbs light & releases O₂).\n2. Calvin Cycle in the stroma (fixes CO₂ into glucose).';
    }
    if (lower.contains('newton') && (lower.contains('law') || lower.contains('motion'))) {
      return '🍎 **Newton\'s Three Laws of Motion:**\n\n1. **First Law (Inertia)**: An object remains at rest or in uniform motion in a straight line unless acted on by an external net force.\n2. **Second Law (F = ma)**: Acceleration is directly proportional to net force and inversely proportional to mass (Force = Mass × Acceleration).\n3. **Third Law (Action & Reaction)**: For every action, there is an equal and opposite reaction.';
    }

    // 3. Study & Learning Strategies
    if (lower.contains('how to study') || lower.contains('study tips') || lower.contains('how to focus') || lower.contains('concentration')) {
      return _howToStudyGuide();
    }
    if (lower == 'explain a topic' || lower.startsWith('explain topic')) {
      return 'I would love to break down any topic for you! 💡\n\nWhich topic or concept are you learning right now?\n\nFor example, ask me:\n• "What is Java?"\n• "Explain Object-Oriented Programming (OOP)"\n• "What is Big-O notation?"\n• "How does photosynthesis work?"\n• "Explain Newton\'s Laws of Motion"\n\nJust type the subject or question below and I\'ll explain it simply!';
    }
    if (lower.contains('study plan') || lower.contains('create a study plan') || lower.contains('exam')) {
      return _createStudyPlan();
    }
    if (lower.contains('practice questions') || lower.contains('quiz') || lower.contains('test me')) {
      return _generatePracticeQuestions(category);
    }
    if (lower.contains('summarize') || lower.contains('summary')) {
      return _summarizeGuide(cleanPrompt);
    }

    // 4. Fitness & Exercise Topics
    if (lower.contains('upper body')) {
      return _upperBodyWorkout();
    }
    if (lower.contains('lower body') || lower.contains('leg day') || lower.contains('squat')) {
      return _lowerBodyWorkout();
    }
    if (lower.contains('hiit') || lower.contains('cardio') || lower.contains('fat burn')) {
      return _hiitWorkout();
    }
    if (lower.contains('deadlift')) {
      return _deadliftGuide();
    }
    if (lower.contains('recovery') || lower.contains('rest day') || lower.contains('sore')) {
      return _recoveryTips();
    }

    // 5. Nutrition & Diet Topics
    if (lower.contains('protein') || lower.contains('breakfast')) {
      return _highProteinBreakfast();
    }
    if (lower.contains('water') || lower.contains('hydration') || lower.contains('pani')) {
      return _hydrationGuide();
    }
    if (lower.contains('pre-workout') || lower.contains('pre workout')) {
      return _preWorkoutSnacks();
    }
    if (lower.contains('meal plan') || lower.contains('calorie') || lower.contains('1800')) {
      return _balancedMealPlan();
    }

    // 6. Habit & Productivity Topics
    if (lower.contains('habit') || lower.contains('atomic')) {
      return _habitBuildingGuide();
    }
    if (lower.contains('procrastinat') || lower.contains('lazy') || lower.contains('alas')) {
      return _beatProcrastinationGuide();
    }
    if (lower.contains('burnout') || lower.contains('stress') || lower.contains('tired')) {
      return _avoidBurnoutGuide();
    }
    if (lower.contains('morning') || lower.contains('routine')) {
      return _morningRoutineGuide();
    }

    // 7. Intelligent Contextual Analysis for Any Custom Question
    return _generateDynamicAnswer(cleanPrompt, category);
  }

  static bool _isGreeting(String lower) {
    return lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'hola' ||
        lower == 'sup' ||
        lower == 'yo' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ');
  }

  static bool _isMarathiGreeting(String lower) {
    return lower.contains('namaskar') ||
        lower.contains('namaste') ||
        lower.contains('ram ram') ||
        lower.contains('jai hind') ||
        lower.contains('kasa ahe');
  }

  static bool _isHindiGreeting(String lower) {
    return lower.contains('pranam') ||
        lower.contains('namaste') ||
        lower.contains('kaise ho') ||
        lower.contains('kya hal hai');
  }

  static String _explainJava() {
    return '☕ **What is Java?**\n\n'
        'Java is a high-level, class-based, object-oriented programming language designed to have as few implementation dependencies as possible. '
        'Its core philosophy is **"Write Once, Run Anywhere" (WORA)**, meaning compiled Java code can run on all platforms that support Java without recompilation.\n\n'
        '📌 **Key Pillars of Java:**\n'
        '1. **Platform Independence**: Source code compiles into bytecode (`.class`), executed by the Java Virtual Machine (JVM).\n'
        '2. **Object-Oriented (OOP)**: Encapsulation, Inheritance, Polymorphism, and Abstraction.\n'
        '3. **Automatic Memory Management**: Garbage Collector (GC) handles memory freeing automatically.\n'
        '4. **Strong Typing & Security**: Strict compile-time type checking and a secure runtime environment.\n\n'
        '🚀 **Popular Uses:** Android development, Enterprise backend systems (Spring Boot), Distributed big data systems (Apache Hadoop, Kafka).\n\n'
        'Would you like a sample Java program or an explanation of JVM vs JDK vs JRE?';
  }

  static String _explainPython() {
    return '🐍 **What is Python?**\n\n'
        'Python is an interpreted, high-level, dynamically typed programming language known for its clean syntax, readability, and vast ecosystem.\n\n'
        '📌 **Key Strengths:**\n'
        '1. **Readable Syntax**: Feels like reading plain English, drastically shortening development time.\n'
        '2. **Vast Libraries**: NumPy, Pandas, PyTorch, TensorFlow for AI/ML; Django, FastAPI, Flask for backend web.\n'
        '3. **Multi-paradigm**: Supports OOP, procedural, and functional programming styles.\n\n'
        '🚀 **Popular Uses:** Artificial Intelligence, Machine Learning, Data Science, Web Scraping, Automation Scripts.\n\n'
        'Would you like to see how to solve a problem in Python?';
  }

  static String _explainFlutter() {
    return '💙 **What is Flutter & Dart?**\n\n'
        'Flutter is Google\'s open-source UI software development kit (SDK) used to build natively compiled, multi-platform applications for Android, iOS, Web, Windows, macOS, and Linux from a **single codebase**.\n\n'
        '📌 **Core Concepts:**\n'
        '• **Dart**: The programming language powering Flutter, supporting both JIT (Just-In-Time for hot reload) and AOT (Ahead-Of-Time for blazing fast 60/120fps production performance).\n'
        '• **Everything is a Widget**: UI layout is built by composing hierarchical widget trees (`StatelessWidget`, `StatefulWidget`).\n'
        '• **High Performance**: Renders directly via the Impeller/Skia engine onto the screen GPU rather than using OEM wrappers.';
  }

  static String _explainJavaScript() {
    return '⚡ **What is JavaScript?**\n\n'
        'JavaScript (JS) is a lightweight, interpreted, just-in-time compiled programming language with first-class functions. '
        'Alongside HTML and CSS, it is one of the core technologies of the World Wide Web.\n\n'
        '📌 **Core Features:**\n'
        '• **Event-Driven & Asynchronous**: Single-threaded event loop architecture handling I/O with Promises and `async/await`.\n'
        '• **Runs Everywhere**: On client browsers (Chrome V8) and on the server via Node.js / Bun.\n'
        '• **Modern Frameworks**: React, Vue, Angular, Next.js.';
  }

  static String _explainCpp() {
    return '⚙️ **What is C++?**\n\n'
        'C++ is a powerful general-purpose programming language created by Bjarne Stroustrup as an extension of C. '
        'It gives programmers high control over system resources and memory.\n\n'
        '📌 **Core Features:**\n'
        '• **Performance**: Direct hardware mapping and zero-cost abstractions.\n'
        '• **Manual Memory Control**: Pointers, references, RAII, dynamic allocation (`new`/`delete`).\n'
        '• **Standard Template Library (STL)**: Vector, Map, Set, Algorithms.\n\n'
        '🚀 **Uses:** Game engines (Unreal Engine), Operating Systems, High-Frequency Trading, Compilers.';
  }

  static String _explainDSA() {
    return '🧠 **Data Structures & Algorithms (DSA):**\n\n'
        'DSA is the foundation of efficient software engineering.\n\n'
        '📌 **Core Data Structures:**\n'
        '• **Linear**: Arrays, Linked Lists, Stacks (LIFO), Queues (FIFO).\n'
        '• **Non-Linear**: Trees (Binary Search Tree, AVL), Graphs, Heaps, Hash Tables.\n\n'
        '📌 **Algorithmic Paradigms:**\n'
        '• **Sorting & Searching**: Binary Search (O(log n)), QuickSort, MergeSort (O(n log n)).\n'
        '• **Optimization**: Dynamic Programming (DP), Greedy, Divide & Conquer, Backtracking.\n\n'
        'Which specific data structure or algorithm would you like to explore?';
  }

  static String _explainDatabase() {
    return '🗄️ **Databases & SQL vs NoSQL:**\n\n'
        '• **Relational (SQL)**: Structured tables with relations, schema enforcement, ACID guarantees (PostgreSQL, MySQL, SQLite). E.g. Supabase is built on top of Postgres.\n'
        '• **Non-Relational (NoSQL)**: Flexible schemas, horizontal scaling (MongoDB, Firebase Firestore, Redis).\n\n'
        '📌 **Essential SQL Commands:**\n'
        '```sql\nSELECT * FROM tasks WHERE is_completed = false ORDER BY priority DESC;\n```';
  }

  static String _explainGoogleFounder() {
    return '🌐 **Founders of Google:**\n\n'
        'Google was founded on **September 4, 1998** by **Larry Page** and **Sergey Brin** while they were Ph.D. students at **Stanford University** in California.\n\n'
        '📌 **Key Highlights:**\n'
        '• **Original Name**: Initially nicknamed *BackRub* because their search algorithm analyzed backlinks to estimate the importance of websites.\n'
        '• **The Name "Google"**: Originates from a misspelling of **Googol** (the number 1 followed by 100 zeros).\n'
        '• **Current CEO**: Sundar Pichai (leading Google since 2015 and Alphabet since 2019).';
  }

  static String _howToStudyGuide() {
    return '🎯 **Evidence-Based Study Strategy:**\n\n'
        '1. **Active Recall**: Test yourself instead of passive re-reading. Close your notes and write what you remember.\n'
        '2. **Spaced Repetition**: Review topics at increasing intervals (Day 1, Day 3, Day 7, Day 14).\n'
        '3. **Feynman Technique**: Explain the concept out loud as if teaching a 10-year-old. Identify gaps where you get stuck.\n'
        '4. **Deep Focus Blocks**: Use Synvero\'s Study Timer for 25-minute or 50-minute zero-distraction blocks.';
  }

  static String _createStudyPlan() {
    return '📅 **4-Step High-Yield Study Plan:**\n\n'
        '• **Block 1 (Morning - 50m)**: Heavy conceptual work & hardest problem sets (high cognitive load).\n'
        '• **Block 2 (Afternoon - 50m)**: Practice questions, flashcards, code exercises.\n'
        '• **Block 3 (Evening - 25m)**: Synthesis review & planning tomorrow\'s top 3 tasks.\n\n'
        '💡 Add each study block directly into the **Tasks** tab in Synvero to get alarm reminders!';
  }

  static String _generatePracticeQuestions(String category) {
    return '📝 **Practice Check: How well do you know your current topic?**\n\n'
        '1. Can you explain the central mechanism in under 2 sentences?\n'
        '2. What is the biggest mistake or edge-case beginners make with this?\n'
        '3. How would you apply this concept to solve a real-world scenario?\n\n'
        'Type your answers below and I will evaluate them for you!';
  }

  static String _summarizeGuide(String prompt) {
    return '📑 **Summary Framework:**\n\n'
        'Paste the text, article, or chapter notes below, and I will extract:\n'
        '1. **Core Thesis / Key Idea** (1 sentence)\n'
        '2. **Top 3 Actionable Insights**\n'
        '3. **Key Terms & Definitions**\n\n'
        'Go ahead and paste what you\'d like summarized!';
  }

  static String _upperBodyWorkout() {
    return '💪 **Upper Body Hypertrophy Split:**\n\n'
        '1. **Barbell / Dumbbell Bench Press**: 3 sets × 8-10 reps\n'
        '2. **Bent-Over Barbell Rows / Lat Pulldown**: 3 sets × 10-12 reps\n'
        '3. **Overhead Dumbbell Shoulder Press**: 3 sets × 8-10 reps\n'
        '4. **Incline Dumbbell Curls**: 3 sets × 12 reps\n'
        '5. **Tricep Rope Pushdowns**: 3 sets × 12-15 reps\n'
        '6. **Face Pulls (Rear Delts)**: 3 sets × 15 reps\n\n'
        'Rest 90-120s between compound sets. Log this in Synvero\'s Fitness tab!';
  }

  static String _lowerBodyWorkout() {
    return '🦵 **Lower Body Strength & Power Routine:**\n\n'
        '1. **Barbell Back Squats**: 4 sets × 6-8 reps\n'
        '2. **Romanian Deadlifts (Hamstrings)**: 3 sets × 8-10 reps\n'
        '3. **Walking Dumbbell Lunges**: 3 sets × 12 steps per leg\n'
        '4. **Leg Press / Leg Extensions**: 3 sets × 12-15 reps\n'
        '5. **Standing Calf Raises**: 4 sets × 15 reps (pause at top)';
  }

  static String _hiitWorkout() {
    return '🔥 **15-Minute High-Intensity Interval Training (HIIT):**\n\n'
        'Perform 40 seconds work, 20 seconds rest. Complete 3 rounds:\n'
        '1. Jumping Jacks / Jump Rope\n'
        '2. Bodyweight Squats to Jump\n'
        '3. Mountain Climbers\n'
        '4. Push-ups / Burpees\n'
        '5. High Knees Sprint';
  }

  static String _deadliftGuide() {
    return '🏋️ **Deadlift Proper Form Checklist:**\n\n'
        '1. **Stance**: Feet hip-width apart, bar cut directly over mid-foot.\n'
        '2. **Grip**: Double overhand or mixed grip just outside your shins.\n'
        '3. **Setup**: Bring shins to the bar without moving it. Chest up, pull shoulder blades down into back pockets.\n'
        '4. **The Pull**: Push the floor away through your heels. Keep bar sliding against your body.\n'
        '5. **Lockout**: Stand tall, squeeze glutes. Do NOT hyperextend your lower back.';
  }

  static String _recoveryTips() {
    return '🛌 **Optimal Rest & Muscle Recovery Protocols:**\n\n'
        '1. **Sleep**: 7.5 - 9 hours for growth hormone secretion.\n'
        '2. **Protein Distribution**: 25-40g protein every 3-4 hours.\n'
        '3. **Active Recovery**: 20-30 min gentle walk or light cycling.\n'
        '4. **Hydration & Electrolytes**: Ensure sufficient sodium, potassium, and magnesium.';
  }

  static String _highProteinBreakfast() {
    return '🍳 **High-Protein Breakfast Ideas (30g+ Protein):**\n\n'
        '• **Option 1 (Quick Eggs & Oats)**: 3 whole eggs + 2 egg whites scrambled with spinach, served with 1 cup oats and berries (~34g protein).\n'
        '• **Option 2 (Greek Yogurt Bowl)**: 200g 0% Greek yogurt + 1 scoop whey/plant protein + chia seeds + almonds (~40g protein).\n'
        '• **Option 3 (Vegetarian Paneer/Tofu Scramble)**: 150g grilled paneer/tofu with turmeric, onions, and whole wheat toast (~30g protein).';
  }

  static String _hydrationGuide() {
    return '💧 **Hydration Guidelines for Peak Performance:**\n\n'
        '• **Baseline**: 35-40ml of water per kg of body weight daily (approx. 2.5 - 3.5 Liters).\n'
        '• **Workout Days**: Drink an extra 500ml 1 hour before training and sip water during your workout.\n'
        '• **Morning Rule**: Drink 500ml water immediately upon waking to replenish overnight dehydration.';
  }

  static String _preWorkoutSnacks() {
    return '⚡ **Ideal Pre-Workout Fuel (60-90 mins before training):**\n\n'
        '1. Banana with 1 tablespoon peanut butter (Fast carbs + steady energy).\n'
        '2. Oatmeal with a half scoop of protein powder.\n'
        '3. Whole grain toast with honey and sliced banana.\n'
        'Keep fats and fiber low immediately before training to prevent sluggish digestion.';
  }

  static String _balancedMealPlan() {
    return '🥗 **1800 Calorie Balanced Meal Template (40C / 30P / 30F):**\n\n'
        '• **Breakfast (450 kcal)**: 3 eggs, 1 slice whole-wheat toast, 1/2 avocado, green tea.\n'
        '• **Lunch (500 kcal)**: 150g grilled chicken/paneer, 1 cup brown rice or quinoa, large garden salad with olive oil.\n'
        '• **Snack (250 kcal)**: 1 apple with 15 almonds or 1 protein shake.\n'
        '• **Dinner (500 kcal)**: Grilled fish/tofu, roasted sweet potato, steamed broccoli.';
  }

  static String _habitBuildingGuide() {
    return '🔁 **The 4 Laws of Atomic Habit Building (James Clear):**\n\n'
        '1. **Make it Obvious**: Anchor your new habit to an existing routine (*"After I pour my morning coffee, I will write my 3 tasks in Synvero"*).\n'
        '2. **Make it Attractive**: Pair what you *need* to do with what you *want* to do.\n'
        '3. **Make it Easy**: Scale the habit down to 2 minutes to start (e.g., read 1 page, do 5 pushups).\n'
        '4. **Make it Satisfying**: Mark the habit checkmark immediately in Synvero to trigger dopamine!';
  }

  static String _beatProcrastinationGuide() {
    return '⚡ **How to Beat Procrastination Right Now:**\n\n'
        '• **The 2-Minute Rule**: If it takes less than 2 minutes, do it immediately without thinking.\n'
        '• **Lower the Activation Energy**: Tell yourself: *"I will just open the file and write 1 sentence."* Starting is 80% of the battle.\n'
        '• **Start a 10-Minute Timer**: Commit to working for only 10 minutes with zero distractions. You will usually keep going once the barrier is broken.';
  }

  static String _avoidBurnoutGuide() {
    return '🌿 **Preventing Burnout & Mental Fatigue:**\n\n'
        '• **Brain Offload**: Write down every task floating in your head into the Synvero Tasks tab.\n'
        '• **Protect Boundaries**: Pick a strict shutdown time in the evening where work/study completely stops.\n'
        '• **Sunlight & Nature**: Spend 15 minutes outdoors in the morning to regulate circadian rhythms.\n'
        '• **Micro-resets**: Take 3 slow, deep diaphragmatic breaths (4 seconds in, 6 seconds out).';
  }

  static String _morningRoutineGuide() {
    return '☀️ **The High-Performance Morning Routine:**\n\n'
        '1. **No Phone for First 30 Mins**: Don\'t start your day reacting to other people\'s agendas.\n'
        '2. **Hydrate**: 500ml water to kickstart metabolism.\n'
        '3. **Light Movement**: 5 minutes of stretching or walking in natural sunlight.\n'
        '4. **Set Intentions**: Review your top 3 priority tasks in Synvero before starting your day.';
  }

  static String _generateDynamicAnswer(String prompt, String category) {
    return '💡 **Synvero AI Insights on "$prompt":**\n\n'
        '1. **Core Concept**:\n'
        '   To master this, break it down into smaller, actionable steps. Consistency in daily action brings real results.\n\n'
        '2. **Recommended Action Steps**:\n'
        '   • Focus on 1 concrete goal related to this today.\n'
        '   • Use the **Study Timer** in Synvero for a dedicated 25-minute focus session.\n'
        '   • Track your progress in the **Tasks** or **Habits** screen.\n\n'
        '3. **Next Step**:\n'
        '   Tell me more about your specific goal or ask any follow-up question, and I\'ll guide you step-by-step!';
  }
}
