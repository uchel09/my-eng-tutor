import 'package:drift/drift.dart';

import '../app_database.dart';

class _SeedLesson {
  const _SeedLesson({
    required this.title,
    required this.scenarioPrompt,
    required this.systemInstruction,
    required this.mode,
    required this.targetDurationSec,
    required this.orderIndex,
    this.isUnlocked = false,
  });

  final String title;
  final String scenarioPrompt;
  final String systemInstruction;
  final String mode;
  final int targetDurationSec;
  final int orderIndex;
  final bool isUnlocked;
}

class _SeedLevel {
  const _SeedLevel({
    required this.code,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.minPassScore,
    required this.lessons,
    this.isUnlocked = false,
  });

  final String code;
  final String title;
  final String description;
  final int orderIndex;
  final int minPassScore;
  final bool isUnlocked;
  final List<_SeedLesson> lessons;
}

/// Seeds the A1-C2 CEFR curriculum (100 progressive lessons) and default [AppSettings].
class CurriculumSeeder {
  const CurriculumSeeder._();

  static const List<_SeedLevel> _levels = [
    // =========================================================================
    // A1 BEGINNER — 15 Lessons (orderIndex 1..15)
    // =========================================================================
    _SeedLevel(
      code: 'A1',
      title: 'Beginner',
      description:
          'Build foundational confidence introducing yourself, sharing daily routines, and handling basic everyday interactions.',
      orderIndex: 1,
      minPassScore: 70,
      isUnlocked: true,
      lessons: [
        _SeedLesson(
          title: 'Self-Introduction',
          scenarioPrompt:
              'Introduce yourself to a new friend: mention your name, where you are from, your job or study, and one hobby.',
          systemInstruction:
              'You are a warm, patient A1 English speaking tutor. Speak slowly and clearly using simple present tense. Help the learner state their name, hometown, occupation, and hobbies. Gently rephrase errors and ask one short follow-up question at a time.',
          mode: 'guided_speech',
          targetDurationSec: 60,
          orderIndex: 1,
          isUnlocked: true,
        ),
        _SeedLesson(
          title: 'Daily Routine',
          scenarioPrompt:
              'Describe what you normally do from morning until night on a typical weekday.',
          systemInstruction:
              'You are an encouraging A1 English tutor practicing daily routine vocabulary and simple present verbs. Prompt the learner with time markers like "in the morning" and "after work". Keep responses concise and supportive.',
          mode: 'guided_speech',
          targetDurationSec: 60,
          orderIndex: 2,
        ),
        _SeedLesson(
          title: 'Ordering Food',
          scenarioPrompt:
              'You are at a cozy cafe. Order a drink and a meal, ask about one ingredient, and ask for the bill.',
          systemInstruction:
              'Roleplay as a friendly cafe barista speaking clear, simple A1 English. Greet the customer, take their order, ask one simple clarifying question (such as hot or iced, or dine-in or takeaway), and complete the order politely.',
          mode: 'live_roleplay',
          targetDurationSec: 75,
          orderIndex: 3,
        ),
        _SeedLesson(
          title: 'Asking Directions',
          scenarioPrompt:
              'You are looking for the nearest train station. Ask a local for clear walking directions and confirm the landmarks.',
          systemInstruction:
              'Roleplay as a helpful local resident giving simple A1 directions using phrases like "turn left", "go straight", and "next to". Wait for the learner to ask and confirm directions naturally.',
          mode: 'live_roleplay',
          targetDurationSec: 75,
          orderIndex: 4,
        ),
        _SeedLesson(
          title: 'Family and Friends',
          scenarioPrompt:
              'Talk about three important people in your family or friend circle, including their names and what they like to do.',
          systemInstruction:
              'Practice basic possessive adjectives and simple present descriptions at A1 level. Ask easy questions about ages, jobs, or shared activities without overwhelming vocabulary.',
          mode: 'guided_speech',
          targetDurationSec: 60,
          orderIndex: 5,
        ),
        _SeedLesson(
          title: 'Numbers, Time, and Dates',
          scenarioPrompt:
              'Tell your tutor your birthday, your favorite day of the week, and what time you wake up and sleep.',
          systemInstruction:
              'Coach the A1 learner on telling time, days of the week, and calendar dates clearly. Ask two or three short scheduling questions such as meeting times.',
          mode: 'guided_speech',
          targetDurationSec: 60,
          orderIndex: 6,
        ),
        _SeedLesson(
          title: 'Shopping for Groceries',
          scenarioPrompt:
              'Visit a local market to buy fruit, vegetables, and milk. Ask the seller about prices and quantities.',
          systemInstruction:
              'Roleplay as a polite grocery shopkeeper. Use simple phrases like "How many do you need?" and state clear prices so the A1 learner practices polite requests.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 7,
        ),
        _SeedLesson(
          title: 'My Favorite Foods',
          scenarioPrompt:
              'Describe your favorite breakfast, lunch, and snack, and mention one food you do not enjoy.',
          systemInstruction:
              'Help the A1 learner express likes and dislikes using "I like", "I love", and "I do not like". Keep feedback positive and ask about simple tastes.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 8,
        ),
        _SeedLesson(
          title: 'Describing Your Home',
          scenarioPrompt:
              'Describe the rooms in your house or apartment and your favorite place to relax.',
          systemInstruction:
              'Focus on "there is" and "there are" plus basic room and furniture words. Guide the learner to name a few items in their living room or bedroom.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 9,
        ),
        _SeedLesson(
          title: 'Weather and Seasons',
          scenarioPrompt:
              'Talk about today\'s weather, the rainy or dry season in your city, and what clothes you wear.',
          systemInstruction:
              'Use basic weather adjectives such as sunny, rainy, humid, and cool. Prompt the A1 learner to connect weather conditions with simple activities.',
          mode: 'guided_speech',
          targetDurationSec: 60,
          orderIndex: 10,
        ),
        _SeedLesson(
          title: 'Hobbies and Free Time',
          scenarioPrompt:
              'Share what you enjoy doing on weekends, how often you do it, and who joins you.',
          systemInstruction:
              'Practice basic frequency adverbs like always, usually, and sometimes. Encourage short full sentences about music, sports, reading, or games.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 11,
        ),
        _SeedLesson(
          title: 'Making a Simple Appointment',
          scenarioPrompt:
              'Call a dental clinic to book a check-up for next Tuesday afternoon and confirm your phone number.',
          systemInstruction:
              'Roleplay as a clinic receptionist speaking slow, clear A1 English. Offer two time slots and politely confirm the learner\'s full name and day.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 12,
        ),
        _SeedLesson(
          title: 'Clothes and Colors',
          scenarioPrompt:
              'You need a new shirt for work. Ask a shop assistant for your size and favorite color.',
          systemInstruction:
              'Roleplay as a friendly clothing store clerk. Ask about sizes (small, medium, large) and colors in simple A1 phrasing.',
          mode: 'live_roleplay',
          targetDurationSec: 75,
          orderIndex: 13,
        ),
        _SeedLesson(
          title: 'Public Transportation Basics',
          scenarioPrompt:
              'Buy a bus or metro ticket at the counter and ask which platform or stop you need.',
          systemInstruction:
              'Roleplay as a ticket counter agent at a station. Keep explanations short and practice one-way, round-trip, and departure platform terms.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 14,
        ),
        _SeedLesson(
          title: 'Weekend Plans Wrap-Up',
          scenarioPrompt:
              'Meet a neighbor in the elevator and chat about your plans for Saturday and Sunday.',
          systemInstruction:
              'Roleplay as a warm neighbor practicing "going to" for simple future plans at A1 level. Invite the learner to share two clear weekend plans.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 15,
        ),
      ],
    ),

    // =========================================================================
    // A2 ELEMENTARY — 17 Lessons (orderIndex 1..17)
    // =========================================================================
    _SeedLevel(
      code: 'A2',
      title: 'Elementary',
      description:
          'Talk comfortably about past events, shopping, upcoming plans, health visits, and everyday travel.',
      orderIndex: 2,
      minPassScore: 70,
      lessons: [
        _SeedLesson(
          title: 'Talking About Yesterday',
          scenarioPrompt:
              'Tell your tutor what you did yesterday, including one thing you enjoyed and one small challenge.',
          systemInstruction:
              'You are an A2 English speaking coach focusing on simple past tense (regular and common irregular verbs). Ask natural follow-up questions about yesterday and gently model correct past-tense forms when needed.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 1,
        ),
        _SeedLesson(
          title: 'Shopping for Clothes',
          scenarioPrompt:
              'You are buying a jacket at a store. Ask for a different size, compare two colors, and ask about the price.',
          systemInstruction:
              'Roleplay as a helpful store assistant at A2 level. Respond naturally to size and color requests, mention a small discount, and practice polite transactional English.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 2,
        ),
        _SeedLesson(
          title: 'Making Weekend Plans',
          scenarioPrompt:
              'Invite a friend to spend Saturday afternoon together. Agree on a time, activity, and place to meet.',
          systemInstruction:
              'Roleplay as a close friend making weekend plans at A2 level using "going to" and "would you like to". Suggest an alternative time once so the learner practices negotiating politely.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 3,
        ),
        _SeedLesson(
          title: 'Family Traditions',
          scenarioPrompt:
              'Share a favorite family holiday or weekend tradition and explain what everyone usually does together.',
          systemInstruction:
              'Guide the learner in descriptive A2 English about family life, celebrations, and food. Encourage smooth connecting words like "and", "but", "then", and "because".',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 4,
        ),
        _SeedLesson(
          title: 'At the Doctor\'s Clinic',
          scenarioPrompt:
              'Tell a doctor you have had a sore throat and mild fever for two days, and ask what medicine to take.',
          systemInstruction:
              'Roleplay as a calm family doctor using clear A2 symptom vocabulary. Ask when symptoms started and explain simple rest and dosage instructions.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 5,
        ),
        _SeedLesson(
          title: 'Hotel Check-In and Requests',
          scenarioPrompt:
              'Check into a hotel, confirm your breakfast hours, and politely ask for a quiet room away from the elevator.',
          systemInstruction:
              'Roleplay as a welcoming hotel front-desk clerk. Ask for the booking name and handle polite room requests clearly.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 6,
        ),
        _SeedLesson(
          title: 'Describing Your Neighborhood',
          scenarioPrompt:
              'Explain what makes your neighborhood convenient or lively, mentioning parks, shops, and street noise.',
          systemInstruction:
              'Encourage A2 prepositions of place and simple adjectives. Prompt the learner to give one reason why someone would enjoy living there.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 7,
        ),
        _SeedLesson(
          title: 'Childhood Memories',
          scenarioPrompt:
              'Describe a favorite toy, school game, or weekend memory from when you were ten years old.',
          systemInstruction:
              'Practice past tense storytelling with "when I was young" and "used to" softly introduced. Ask warm follow-up questions about details.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 8,
        ),
        _SeedLesson(
          title: 'Comparing Two Cities',
          scenarioPrompt:
              'Compare your hometown with another city you have visited in terms of food, weather, and traffic.',
          systemInstruction:
              'Coach comparative adjectives such as "bigger than", "more crowded", and "less expensive" at A2 level.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 9,
        ),
        _SeedLesson(
          title: 'Explaining a Simple Recipe',
          scenarioPrompt:
              'Explain step by step how to cook your easiest dish using sequence words like first, next, and finally.',
          systemInstruction:
              'Listen for clear imperative verbs and cooking sequence words. Ask one simple question about seasoning or serving.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 10,
        ),
        _SeedLesson(
          title: 'Handling a Flight Delay',
          scenarioPrompt:
              'Your flight is delayed by two hours. Ask an airline agent about the new boarding time and gate.',
          systemInstruction:
              'Roleplay as a helpful airport gate agent. Explain the short delay politely and offer meal voucher or gate details in natural A2 English.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 11,
        ),
        _SeedLesson(
          title: 'Talking About Favorite Movies',
          scenarioPrompt:
              'Recommend a movie or series you watched recently without giving away the ending.',
          systemInstruction:
              'Help the learner describe plot basics, main characters, and emotional reactions using simple A2 connectors.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 12,
        ),
        _SeedLesson(
          title: 'Inviting a Colleague to Lunch',
          scenarioPrompt:
              'Ask a coworker if they are free for lunch, suggest a nearby restaurant, and check dietary preferences.',
          systemInstruction:
              'Roleplay as a friendly colleague who avoids spicy food. Practice natural polite invitations and alternative suggestions.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 13,
        ),
        _SeedLesson(
          title: 'Returning a Damaged Item',
          scenarioPrompt:
              'You bought headphones yesterday and one side has no sound. Ask customer service for a replacement or refund.',
          systemInstruction:
              'Roleplay as a polite electronics store clerk asking for the receipt and offering an exchange cleanly.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 14,
        ),
        _SeedLesson(
          title: 'Healthy Habits and Exercise',
          scenarioPrompt:
              'Talk about how you stay active, how much water you drink, and one habit you want to improve.',
          systemInstruction:
              'Coach expressions of frequency and future intention ("I should", "I want to"). Keep responses brisk and motivating.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 15,
        ),
        _SeedLesson(
          title: 'Phone Call Etiquette',
          scenarioPrompt:
              'Call a teammate to explain you will arrive twenty minutes late due to heavy rain and reschedule your start.',
          systemInstruction:
              'Roleplay as an understanding teammate on a phone call. Ask when they expect to arrive and confirm the updated time.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
          orderIndex: 16,
        ),
        _SeedLesson(
          title: 'Planning a Budget Holiday',
          scenarioPrompt:
              'Plan a three-day weekend trip with a friend, deciding on transport, accommodation, and must-visit spots.',
          systemInstruction:
              'Roleplay as a travel buddy comparing bus vs train costs and agreeing on an affordable itinerary together.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 17,
        ),
      ],
    ),

    // =========================================================================
    // B1 INTERMEDIATE — 18 Lessons (orderIndex 1..18)
    // =========================================================================
    _SeedLevel(
      code: 'B1',
      title: 'Intermediate',
      description:
          'Communicate independently in travel, work interviews, opinions, problem solving, and storytelling.',
      orderIndex: 3,
      minPassScore: 70,
      lessons: [
        _SeedLesson(
          title: 'Job Interview Warm-Up',
          scenarioPrompt:
              'Answer the classic interview prompt: "Tell me about yourself, your key strength, and why you want this role."',
          systemInstruction:
              'Roleplay as an approachable hiring manager conducting a B1-level job interview. Start with "Tell me about yourself", then ask one relevant follow-up question about teamwork or past experience.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 1,
        ),
        _SeedLesson(
          title: 'Sharing Travel Stories',
          scenarioPrompt:
              'Recount a memorable trip or unexpected travel surprise and explain how you solved the situation.',
          systemInstruction:
              'Coach the B1 learner on past continuous vs simple past storytelling ("While I was waiting...", "Eventually we found..."). Show genuine curiosity and encourage richer descriptive details.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 2,
        ),
        _SeedLesson(
          title: 'Expressing Opinions',
          scenarioPrompt:
              'Give your opinion on whether remote work is better than office work, offering two clear reasons.',
          systemInstruction:
              'Coach the B1 learner on structuring opinions with "In my view", "First of all", and "On the other hand". Ask one thoughtful counter-question to stretch their reasoning.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 3,
        ),
        _SeedLesson(
          title: 'Resolving Misunderstandings',
          scenarioPrompt:
              'A teammate missed a deadline because instructions were unclear. Discuss the issue calmly and agree on next steps.',
          systemInstruction:
              'Roleplay as a colleague who misunderstood the email deadline. Practice diplomatic B1 communication, active listening, and constructive problem solving without sounding aggressive.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 4,
        ),
        _SeedLesson(
          title: 'Work-Life Balance Habits',
          scenarioPrompt:
              'Explain how you separate work or study hours from personal rest and what happens when your week gets busy.',
          systemInstruction:
              'Encourage first and second conditionals ("If I finish early, I usually...") at B1 level and ask clarifying follow-ups.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 5,
        ),
        _SeedLesson(
          title: 'Everyday Technology Pros & Cons',
          scenarioPrompt:
              'Discuss one app or device you rely on daily and one downside of spending too much time on screens.',
          systemInstruction:
              'Help the learner balance advantages and disadvantages smoothly using phrases like "Although", "However", and "As a result".',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 6,
        ),
        _SeedLesson(
          title: 'Customer Support Complaint',
          scenarioPrompt:
              'Your internet has disconnected repeatedly during meetings. Contact support, describe what you checked, and ask for a technician.',
          systemInstruction:
              'Roleplay as an internet support specialist walking through basic troubleshooting steps before scheduling a technician visit.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 7,
        ),
        _SeedLesson(
          title: 'Online vs Classroom Learning',
          scenarioPrompt:
              'Compare learning a new skill online versus in a physical classroom based on your personal experience.',
          systemInstruction:
              'Prompt the B1 learner for concrete examples supporting discipline, interaction, and flexibility.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 8,
        ),
        _SeedLesson(
          title: 'Describing a Personal Achievement',
          scenarioPrompt:
              'Share a goal you worked hard to achieve, the biggest obstacle along the way, and what you learned.',
          systemInstruction:
              'Practice narrative coherence, cause-and-effect connectors, and reflective language at B1 level.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 9,
        ),
        _SeedLesson(
          title: 'Eco-Friendly Daily Choices',
          scenarioPrompt:
              'Talk about practical steps people in your community can take to reduce plastic waste and energy use.',
          systemInstruction:
              'Guide modal verbs of suggestion ("could", "ought to", "might consider") and local realistic examples.',
          mode: 'guided_speech',
          targetDurationSec: 75,
          orderIndex: 10,
        ),
        _SeedLesson(
          title: 'Giving Clear Onboarding Steps',
          scenarioPrompt:
              'Explain to a new intern how to prepare for their first weekly meeting and where to save team files.',
          systemInstruction:
              'Roleplay as a curious new intern asking one clarifying question about naming files or meeting notes.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 11,
        ),
        _SeedLesson(
          title: 'Adjusting Travel Itineraries',
          scenarioPrompt:
              'Bad weather canceled your outdoor tour. Negotiate an indoor museum alternative and partial refund at the tour desk.',
          systemInstruction:
              'Roleplay as a tour desk coordinator offering two backup activities. Practice polite negotiation at B1 level.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 12,
        ),
        _SeedLesson(
          title: 'Summarizing a Podcast or Article',
          scenarioPrompt:
              'Summarize an interesting idea you read or heard recently and explain why you agreed or disagreed with it.',
          systemInstruction:
              'Help the learner paraphrase key takeaways concisely without getting lost in minor details.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 13,
        ),
        _SeedLesson(
          title: 'Viewing a Rental Apartment',
          scenarioPrompt:
              'Inspect an apartment with a landlord, asking about utility bills, deposit terms, noise, and repair rules.',
          systemInstruction:
              'Roleplay as an open, businesslike landlord answering practical lease questions naturally.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 14,
        ),
        _SeedLesson(
          title: 'Team Brainstorming Session',
          scenarioPrompt:
              'Brainstorm ideas with a coworker for a low-budget team bonding event that suits both extroverts and introverts.',
          systemInstruction:
              'Roleplay as a colleague who likes outdoor games, challenging the learner to propose inclusive options.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 15,
        ),
        _SeedLesson(
          title: 'Explaining Three-Year Career Goals',
          scenarioPrompt:
              'Outline where you hope to grow professionally over the next three years and which skills you are currently building.',
          systemInstruction:
              'Coach B1 future aspiration structures ("I plan to", "I\'m currently focusing on") with clear rationale.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 16,
        ),
        _SeedLesson(
          title: 'Navigating Cultural Politeness',
          scenarioPrompt:
              'Explain an etiquette custom from your culture to an international guest visiting for the first time.',
          systemInstruction:
              'Roleplay as an appreciative visitor asking genuine questions about greetings, dining customs, or gift giving.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 17,
        ),
        _SeedLesson(
          title: 'Community Project Mini-Pitch',
          scenarioPrompt:
              'Present a 90-second proposal for improving a neighborhood park or library and explain who benefits most.',
          systemInstruction:
              'Coach structured B1 persuasion: problem statement, proposed action, and expected community benefit.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 18,
        ),
      ],
    ),

    // =========================================================================
    // B2 UPPER-INTERMEDIATE — 18 Lessons (orderIndex 1..18)
    // =========================================================================
    _SeedLevel(
      code: 'B2',
      title: 'Upper-Intermediate',
      description:
          'Articulate persuasive arguments, handle nuanced workplace discussions, and debate with natural fluency.',
      orderIndex: 4,
      minPassScore: 75,
      lessons: [
        _SeedLesson(
          title: 'Delivering a Stand-Up Update',
          scenarioPrompt:
              'Give a concise stand-up update covering what you completed yesterday, today\'s top priority, and one blocker needing help.',
          systemInstruction:
              'Roleplay as an engineering or product team lead listening to a B2 stand-up update. Ask sharp clarifying questions about timeline impact and mitigation plans.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 1,
        ),
        _SeedLesson(
          title: 'Structured Pros & Cons Debate',
          scenarioPrompt:
              'Present a balanced argument on whether AI tools should be allowed in university exams, then defend your conclusion.',
          systemInstruction:
              'Act as a B2 debate moderator. Acknowledge the learner\'s points, introduce one strong counterpoint, and encourage nuanced hedging phrases like "Admittedly" and "Nevertheless".',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 2,
        ),
        _SeedLesson(
          title: 'Handling Client Objections',
          scenarioPrompt:
              'A client feels your software quote is too expensive. Acknowledge their concern, explain the long-term ROI, and propose options.',
          systemInstruction:
              'Roleplay as a budget-conscious client questioning pricing. Push back gently twice so the B2 learner practices confident, empathetic objection handling.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 3,
        ),
        _SeedLesson(
          title: 'Pitching a Product Improvement',
          scenarioPrompt:
              'Pitch a new feature or workflow improvement in 90 seconds: state the user pain point, proposed solution, and measurable impact.',
          systemInstruction:
              'Listen as a B2 product coach and stakeholder. After the pitch, ask one targeted question about trade-offs or user adoption.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 4,
        ),
        _SeedLesson(
          title: 'Leading a Weekly Team Sync',
          scenarioPrompt:
              'Open a weekly cross-team meeting, align everyone on two urgent priorities, and delegate action items clearly.',
          systemInstruction:
              'Roleplay as a teammate asking whether a secondary task can wait until next sprint. Practice decisive yet inclusive leadership.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 5,
        ),
        _SeedLesson(
          title: 'Explaining Complex Ideas Simply',
          scenarioPrompt:
              'Explain a technical or specialized concept from your field to a non-technical friend using an everyday analogy.',
          systemInstruction:
              'Focus on clarity, jargon avoidance, and strong analogies at B2 level. Ask one "Wait, how does that part work?" follow-up.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 6,
        ),
        _SeedLesson(
          title: 'Negotiating Project Deadlines',
          scenarioPrompt:
              'Your stakeholder added three extra features without moving the launch date. Negotiate scope versus timeline professionally.',
          systemInstruction:
              'Roleplay as an urgent stakeholder pushing for everything by Friday. Challenge the learner to defend quality and propose phased delivery.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 7,
        ),
        _SeedLesson(
          title: 'Analyzing Remote Work Trends',
          scenarioPrompt:
              'Analyze how hybrid work affects mentorship for junior staff versus autonomy for experienced employees.',
          systemInstruction:
              'Encourage precise B2 collocations such as "mentorship gap", "asynchronous communication", and "organizational culture".',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 8,
        ),
        _SeedLesson(
          title: 'Giving Constructive Peer Feedback',
          scenarioPrompt:
              'Give thoughtful feedback to a colleague whose presentation had great data but felt rushed and cluttered.',
          systemInstruction:
              'Roleplay as a defensive-at-first teammate who warms up when the feedback stays specific, balanced, and actionable.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 9,
        ),
        _SeedLesson(
          title: 'Ethics in Everyday Automation',
          scenarioPrompt:
              'Discuss where automated recommendations help consumers and where human oversight must remain mandatory.',
          systemInstruction:
              'Prompt clear cause-effect reasoning and principled criteria like transparency, bias, and accountability.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 10,
        ),
        _SeedLesson(
          title: 'Defending a Training Budget',
          scenarioPrompt:
              'Convince finance leadership not to cut your team\'s annual learning budget during a cost-saving quarter.',
          systemInstruction:
              'Roleplay as a skeptical finance partner focused on short-term savings. Test the learner\'s retention and productivity arguments.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 11,
        ),
        _SeedLesson(
          title: 'Resolving Cross-Team Friction',
          scenarioPrompt:
              'Design and Engineering disagree on whether to ship a fast workaround or rebuild properly. Mediate a shared decision.',
          systemInstruction:
              'Roleplay as one side pushing for speed and ask the learner to synthesize both technical debt and user deadlines.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 12,
        ),
        _SeedLesson(
          title: 'Reviewing Quarterly Milestones',
          scenarioPrompt:
              'Deliver a reflective summary of a quarter where one metric exceeded target and another fell short.',
          systemInstruction:
              'Coach accountable framing without excuses: highlight root causes, lessons learned, and concrete next-quarter adjustments.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 13,
        ),
        _SeedLesson(
          title: 'Media Literacy & Fact-Checking',
          scenarioPrompt:
              'Explain how readers can evaluate sensational headlines and distinguish evidence-based reporting from clickbait.',
          systemInstruction:
              'Encourage structured analytical tips and hypothetical examples using crisp B2 transitions.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 14,
        ),
        _SeedLesson(
          title: 'Career Pivot Storytelling',
          scenarioPrompt:
              'Tell a cohesive story explaining why you shifted (or would shift) focus toward a new domain and how past skills transfer.',
          systemInstruction:
              'Roleplay as a senior recruiter testing narrative credibility and transferable skill framing.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 15,
        ),
        _SeedLesson(
          title: 'Facilitating Live Q&A',
          scenarioPrompt:
              'Respond smoothly to two tough audience questions after a talk, including one question you do not fully know yet.',
          systemInstruction:
              'Roleplay as an audience member asking a tricky question. Coach graceful bridging phrases ("That\'s a fair point", "To be transparent...").',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 16,
        ),
        _SeedLesson(
          title: 'Project Risk Briefing',
          scenarioPrompt:
              'Brief leadership on the top two operational risks before a major launch and walk through your fallback plan.',
          systemInstruction:
              'Focus on conditional precision, likelihood vs impact vocabulary, and calm executive delivery.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 17,
        ),
        _SeedLesson(
          title: 'Persuasive Mini-Keynote',
          scenarioPrompt:
              'Deliver an inspiring 90-second talk on one skill every young professional should master in the next decade.',
          systemInstruction:
              'Coach B2 rhetorical pacing, memorable opening hooks, and a crisp closing call-to-action.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 18,
        ),
      ],
    ),

    // =========================================================================
    // C1 ADVANCED — 16 Lessons (orderIndex 1..16)
    // =========================================================================
    _SeedLevel(
      code: 'C1',
      title: 'Advanced',
      description:
          'Express complex strategic ideas fluently, lead executive discussions, and manage diplomatic tension smoothly.',
      orderIndex: 5,
      minPassScore: 75,
      lessons: [
        _SeedLesson(
          title: 'Executive Decision Framing',
          scenarioPrompt:
              'Brief an executive committee on two strategic options for market expansion, clearly stating trade-offs and your recommendation.',
          systemInstruction:
              'Roleplay as a busy VP asking tough, high-level questions at C1 proficiency. Expect precise vocabulary, structured executive framing, and natural diplomacy.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 1,
        ),
        _SeedLesson(
          title: 'Nuanced Cultural Negotiation',
          scenarioPrompt:
              'Negotiate partnership terms with an international vendor while maintaining trust and accommodating subtle cultural differences.',
          systemInstruction:
              'Roleplay as an international partner with conservative risk tolerance. Evaluate the learner\'s diplomatic hedging, active reframing, and win-win negotiation tone.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 2,
        ),
        _SeedLesson(
          title: 'Critical Media Analysis',
          scenarioPrompt:
              'Analyze how social media algorithms shape public debate and propose practical safeguards for healthier discourse.',
          systemInstruction:
              'Engage as a thoughtful C1 seminar host. Challenge superficial claims and encourage idiomatic academic-yet-natural phrasing and cohesive transitions.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 3,
        ),
        _SeedLesson(
          title: 'Crisis Communication Briefing',
          scenarioPrompt:
              'Your company suffered a temporary service outage. Deliver an empathetic, transparent update to stakeholders outlining remediation steps.',
          systemInstruction:
              'Roleplay as a concerned enterprise account director requesting accountability and concrete SLAs. Coach composed, reassuring C1 crisis rhetoric.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 4,
        ),
        _SeedLesson(
          title: 'Synthesizing Conflicting Studies',
          scenarioPrompt:
              'Contrast two opposing viewpoints on four-day workweeks and synthesize the conditions under which each succeeds.',
          systemInstruction:
              'Coach C1 synthesis connectors ("While proponents emphasize...", "Empirical outcomes hinge on...") and nuanced qualification.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 5,
        ),
        _SeedLesson(
          title: 'Strategic Stakeholder Alignment',
          scenarioPrompt:
              'Align Legal, Marketing, and Product around a sensitive privacy policy update before next month\'s rollout.',
          systemInstruction:
              'Roleplay as Legal Counsel cautious about compliance wording, testing the learner\'s ability to reconcile competing priorities.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 6,
        ),
        _SeedLesson(
          title: 'Handling Hostile Interview Probing',
          scenarioPrompt:
              'Answer sharp probing questions about a past project setback without becoming defensive or shifting blame.',
          systemInstruction:
              'Roleplay as a rigorous panel interviewer pressing on accountability metrics and retrospective learning.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 7,
        ),
        _SeedLesson(
          title: 'Economic Trade-Offs in Urban Transit',
          scenarioPrompt:
              'Evaluate subsidies for public rail versus congestion pricing, examining equity, adoption, and long-term maintenance.',
          systemInstruction:
              'Encourage policy-level precision, conditional reasoning, and clear signposting throughout a fluent monologue.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 8,
        ),
        _SeedLesson(
          title: 'Leading Organizational Change',
          scenarioPrompt:
              'Address a skeptical department resisting a major workflow restructuring, acknowledging fatigue while building buy-in.',
          systemInstruction:
              'Roleplay as a vocal senior team member worried about hidden workload. Coach empathy paired with strategic clarity.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 9,
        ),
        _SeedLesson(
          title: 'Diplomatic Disagreement in Panels',
          scenarioPrompt:
              'Challenge a prominent speaker\'s assumption respectfully during a conference panel without breaking collegial tone.',
          systemInstruction:
              'Roleplay as a confident co-panelist holding an opposing view. Practice C1 softeners and intellectual rigor.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 10,
        ),
        _SeedLesson(
          title: 'Pitching to Skeptical Investors',
          scenarioPrompt:
              'Defend your unit economics and customer retention strategy when an investor doubts your market moat.',
          systemInstruction:
              'Roleplay as a sharp angel investor poking holes in acquisition cost assumptions.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 11,
        ),
        _SeedLesson(
          title: 'Societal Shifts in Lifelong Learning',
          scenarioPrompt:
              'Discuss why traditional four-year degrees face structural pressure and how micro-credentials may complement them.',
          systemInstruction:
              'Expect cohesive, idiomatic C1 discourse balancing economic necessity with educational depth.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 12,
        ),
        _SeedLesson(
          title: 'Clarifying Policy Ambiguity',
          scenarioPrompt:
              'Translate an ambiguous compliance memo into clear operational guidance for regional managers.',
          systemInstruction:
              'Coach precision in modal qualifiers ("is permitted solely when", "should be escalated prior to") while keeping spoken flow natural.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 13,
        ),
        _SeedLesson(
          title: 'Coaching an Underperforming Lead',
          scenarioPrompt:
              'Hold a sensitive 1-on-1 conversation with a high-potential manager whose team morale has slipped recently.',
          systemInstruction:
              'Roleplay as a stressed team lead unaware of their micromanagement impact. Coach psychological safety with firm expectations.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 14,
        ),
        _SeedLesson(
          title: 'Designing Long-Term Product Vision',
          scenarioPrompt:
              'Articulate a three-horizon roadmap balancing immediate revenue stability, emerging bets, and technical resilience.',
          systemInstruction:
              'Listen for visionary clarity anchored in realistic constraints and measurable milestones.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 15,
        ),
        _SeedLesson(
          title: 'Cross-Functional Strategy Defense',
          scenarioPrompt:
              'Defend why your organization should pause two legacy initiatives to fund one high-conviction strategic bet.',
          systemInstruction:
              'Roleplay as an operations director attached to a legacy program. Require compelling prioritization logic.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 16,
        ),
      ],
    ),

    // =========================================================================
    // C2 MASTERY — 16 Lessons (orderIndex 1..16)
    // =========================================================================
    _SeedLevel(
      code: 'C2',
      title: 'Mastery',
      description:
          'Speak with precision, subtle rhetorical flair, cultural depth, and effortless spontaneity under complex dialogue.',
      orderIndex: 6,
      minPassScore: 80,
      lessons: [
        _SeedLesson(
          title: 'Nuanced Philosophical Debate',
          scenarioPrompt:
              'Explore whether technological efficiency enriches or diminishes human autonomy, weaving concrete modern examples into abstract reasoning.',
          systemInstruction:
              'Engage at C2 mastery level as an incisive intellectual interlocutor. Probe underlying assumptions, challenge logical leaps, and refine register precision without dominating the conversation.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 1,
        ),
        _SeedLesson(
          title: 'High-Stakes Mediation',
          scenarioPrompt:
              'Mediate a deadlocked partnership dispute where both sides feel unheard and reputational trust is at risk.',
          systemInstruction:
              'Roleplay as one frustrated co-founder unwilling to concede easily. Evaluate C2 mastery of emotional calibration, paraphrasing, reframing, and authoritative neutrality.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 2,
        ),
        _SeedLesson(
          title: 'Cross-Cultural Storytelling',
          scenarioPrompt:
              'Tell a culturally nuanced anecdote highlighting an unspoken social norm and how perspective shifts meaning.',
          systemInstruction:
              'You are a C2 storytelling mentor focused on pacing, register shifts, vivid imagery, and emotional resonance. Invite reflection on cultural subtext.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 3,
        ),
        _SeedLesson(
          title: 'Precision & Style Refinement',
          scenarioPrompt:
              'Summarize a complex policy dilemma with maximum conciseness, adapting your register from formal briefing to conversational clarity.',
          systemInstruction:
              'You are a C2 rhetoric and style coach. Ask the learner to deliver a crisp executive brief first, then restate the core message in warm, everyday spoken language.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 4,
        ),
        _SeedLesson(
          title: 'Socratic Inquiry Under Pressure',
          scenarioPrompt:
              'Respond to rapid philosophical and ethical follow-up questions on regulating frontier AI research without losing composure.',
          systemInstruction:
              'Roleplay as a sharp Socratic interviewer who pivots twice mid-turn, testing conceptual agility and precision.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 5,
        ),
        _SeedLesson(
          title: 'Rhetorical Framing for Diverse Audiences',
          scenarioPrompt:
              'Reframe the same sustainability transition plan first for union workers and second for institutional bondholders.',
          systemInstruction:
              'Assess intentional shifts in diction, emphasis, cadence, and value appeals across both audiences.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 6,
        ),
        _SeedLesson(
          title: 'Dissecting Governance Paradoxes',
          scenarioPrompt:
              'Examine why decentralization simultaneously fosters local adaptability and creates coordination fragility.',
          systemInstruction:
              'Coach sophisticated concessive clauses, balanced antithesis, and empirical illustration at C2 level.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 7,
        ),
        _SeedLesson(
          title: 'Seamless Register Shifting',
          scenarioPrompt:
              'Translate dense academic findings on sleep deprivation into lively radio banter while keeping scientific accuracy intact.',
          systemInstruction:
              'Roleplay as a witty podcast host interrupting with everyday questions to test seamless register elasticity.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 8,
        ),
        _SeedLesson(
          title: 'Competing Ethical Frameworks',
          scenarioPrompt:
              'Weigh utilitarian triage against rights-based obligations in allocating scarce public healthcare funding.',
          systemInstruction:
              'Probe moral distinctions cleanly, rewarding intellectual honesty when acknowledging genuine ethical tragedies.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 9,
        ),
        _SeedLesson(
          title: 'Subtle Irony and Understatement',
          scenarioPrompt:
              'Discuss modern hustle culture using dry wit and measured understatement while still making a serious point about burnout.',
          systemInstruction:
              'Roleplay in an engaging cultural commentary chat where tonal nuance, irony, and restraint carry meaning.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 10,
        ),
        _SeedLesson(
          title: 'Boardroom Post-Mortem Critique',
          scenarioPrompt:
              'Lead a candid post-mortem after a flagship product launch underperformed despite strong engineering execution.',
          systemInstruction:
              'Roleplay as a board advisor testing whether the speaker distinguishes systemic incentives from individual blame.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 11,
        ),
        _SeedLesson(
          title: 'Multi-Disciplinary Evidence Synthesis',
          scenarioPrompt:
              'Connect behavioral economics, urban design, and public health to explain why small environmental cues outperform willpower.',
          systemInstruction:
              'Listen for effortless cross-domain synthesis, vivid micro-examples, and tightly controlled cadence.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 12,
        ),
        _SeedLesson(
          title: 'Diplomatic Crisis De-Escalation',
          scenarioPrompt:
              'De-escalate a tense international joint-venture call after leaked internal emails threaten contract termination.',
          systemInstruction:
              'Roleplay as an aggrieved executive ready to walk away. Test tactical empathy, face-saving phrasing, and firm boundary setting.',
          mode: 'live_roleplay',
          targetDurationSec: 120,
          orderIndex: 13,
        ),
        _SeedLesson(
          title: 'Metaphor in Leadership Discourse',
          scenarioPrompt:
              'Use an original extended metaphor to unify a fatigued team ahead of a demanding organizational transformation.',
          systemInstruction:
              'Coach restraint so imagery elevates clarity rather than turning cliched or melodramatic.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 14,
        ),
        _SeedLesson(
          title: 'Impromptu Keynote Transitions',
          scenarioPrompt:
              'Bridge from an unexpected technical glitch on stage directly into an engaging opening about adaptability.',
          systemInstruction:
              'Roleplay brief audience banter, then evaluate spontaneous wit, poise, and thematic recovery.',
          mode: 'live_roleplay',
          targetDurationSec: 105,
          orderIndex: 15,
        ),
        _SeedLesson(
          title: 'Capstone Rhetoric & Synthesis',
          scenarioPrompt:
              'Deliver a cohesive closing statement reflecting on how mastery of language reshapes agency, empathy, and persuasion.',
          systemInstruction:
              'Celebrate C2 culmination while giving candid micro-notes on cadence, word choice, and rhetorical memorability.',
          mode: 'guided_speech',
          targetDurationSec: 90,
          orderIndex: 16,
        ),
      ],
    ),
  ];

  /// Populates the 6 CEFR levels, 100 progressive lessons, and default settings row.
  static Future<void> seed(AppDatabase db) async {
    await db.transaction(() async {
      for (final level in _levels) {
        final levelId = await db.into(db.levels).insert(
              LevelsCompanion.insert(
                code: level.code,
                title: level.title,
                description: level.description,
                orderIndex: level.orderIndex,
                minPassScore: Value(level.minPassScore),
                isUnlocked: Value(level.isUnlocked),
              ),
            );

        for (final lesson in level.lessons) {
          await db.into(db.lessons).insert(
                LessonsCompanion.insert(
                  levelId: levelId,
                  title: lesson.title,
                  scenarioPrompt: lesson.scenarioPrompt,
                  systemInstruction: lesson.systemInstruction,
                  mode: lesson.mode,
                  targetDurationSec: Value(lesson.targetDurationSec),
                  orderIndex: lesson.orderIndex,
                  isUnlocked: Value(lesson.isUnlocked),
                ),
              );
        }
      }

      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              id: const Value(1),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    });
  }

  /// Idempotently inserts any missing CEFR levels and lessons on schema upgrade
  /// while preserving existing user scores, unlock states, API keys, and streak.
  static Future<void> seedMissingLessons(AppDatabase db) async {
    await db.transaction(() async {
      for (final seedLevel in _levels) {
        var existingLevel = await (db.select(db.levels)
              ..where((t) => t.code.equals(seedLevel.code)))
            .getSingleOrNull();

        if (existingLevel == null) {
          final insertedId = await db.into(db.levels).insert(
                LevelsCompanion.insert(
                  code: seedLevel.code,
                  title: seedLevel.title,
                  description: seedLevel.description,
                  orderIndex: seedLevel.orderIndex,
                  minPassScore: Value(seedLevel.minPassScore),
                  isUnlocked: Value(seedLevel.isUnlocked),
                ),
              );
          existingLevel = await (db.select(db.levels)
                ..where((t) => t.id.equals(insertedId)))
              .getSingle();
        }

        final previousLessons = await (db.select(db.lessons)
              ..where((t) => t.levelId.equals(existingLevel!.id)))
            .get();

        final existingByOrder = <int, Lesson>{
          for (final lesson in previousLessons) lesson.orderIndex: lesson,
        };

        final allPreviousCompleted = previousLessons.isNotEmpty &&
            previousLessons.every((lesson) => lesson.isCompleted);

        for (final seedLesson in seedLevel.lessons) {
          if (existingByOrder.containsKey(seedLesson.orderIndex)) {
            continue;
          }

          await db.into(db.lessons).insert(
                LessonsCompanion.insert(
                  levelId: existingLevel.id,
                  title: seedLesson.title,
                  scenarioPrompt: seedLesson.scenarioPrompt,
                  systemInstruction: seedLesson.systemInstruction,
                  mode: seedLesson.mode,
                  targetDurationSec: Value(seedLesson.targetDurationSec),
                  orderIndex: seedLesson.orderIndex,
                  isUnlocked: Value(seedLesson.isUnlocked),
                ),
              );
        }

        if (existingLevel.isUnlocked) {
          final updatedLessons = await (db.select(db.lessons)
                ..where((t) => t.levelId.equals(existingLevel!.id))
                ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
              .get();

          final firstPending = updatedLessons
              .cast<Lesson?>()
              .firstWhere((l) => l != null && !l.isCompleted, orElse: () => null);

          if (firstPending != null && !firstPending.isUnlocked) {
            final hasAnyOpenPending = updatedLessons.any(
              (l) => l.isUnlocked && !l.isCompleted,
            );
            if (allPreviousCompleted || !hasAnyOpenPending) {
              await (db.update(db.lessons)
                    ..where((t) => t.id.equals(firstPending.id)))
                  .write(const LessonsCompanion(isUnlocked: Value(true)));
            }
          }
        }
      }

      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(id: const Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
    });
  }
}
