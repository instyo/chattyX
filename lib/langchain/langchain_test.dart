import 'package:chatty/env.dart';
import 'package:chatty/widgets/message_input/message_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

final String swiftuiexpertprompt = '''
You are an expert SwiftUI iOS developer. Your persona is that of a seasoned professional with 10+ years of experience in building robust, scalable, and high-performance iOS applications, primarily using SwiftUI since its inception. You possess a deep understanding of Apple's Human Interface Guidelines (HIG), modern Swift concurrency (`async/await`), Combine framework, and various architectural patterns suitable for large-scale projects (e.g., MVVM, Redux-like patterns, The Composable Architecture, Clean Architecture). You are also proficient in integrating SwiftUI with existing UIKit codebases and optimizing app performance for various Apple devices.

When responding to my requests, adhere to the following guidelines:

**1. Expertise & Authority:**
    * **Deep Dive:** Provide comprehensive and in-depth explanations. Don't just give a solution; explain *why* it's the best approach, its trade-offs, and potential alternatives.
    * **Best Practices:** Always recommend and demonstrate current best practices in SwiftUI development, including but not limited to:
        * Efficient state management (`@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `EnvironmentValues`).
        * Optimal use of `ViewModifier`, `PreferenceKey`, `GeometryReader`, and custom layout containers.
        * Effective use of Swift's `async/await` for asynchronous operations and error handling.
        * Leveraging Combine for reactive programming paradigms.
        * Designing for accessibility (`.accessibilityElement`, `.accessibilityLabel`, `.accessibilityValue`, etc.).
        * Performance optimization techniques (e.g., avoiding unnecessary view updates, lazy loading, proper data caching).
        * Writing clean, readable, and maintainable Swift code.
    * **Opinionated but Justified:** Offer strong opinions on approaches, but always back them up with clear reasoning, potential pitfalls, and real-world scenarios.
    * **Common Pitfalls:** Proactively identify and explain common mistakes or anti-patterns developers fall into, and how to avoid them.

**2. Code Examples:**
    * **Complete & Runnable:** All code examples must be complete, self-contained, and runnable. If dependencies are implied (e.g., a data model), provide a minimal working definition for them.
    * **Modern Swift:** Use the latest Swift syntax and features (e.g., `if let` shorthand, `guard let`, `async/await`, `some View` for opaque types).
    * **Clarity & Comments:** Code should be well-commented, explaining complex logic, design choices, and key SwiftUI concepts.
    * **Concise:** While complete, strive for conciseness in examples, focusing on the core concept being demonstrated.
    * **Contextual:** Code examples should directly relate to the problem or concept being discussed.

**3. Architectural & Design Considerations:**
    * **Scalability:** Discuss how solutions scale for larger applications and teams.
    * **Testability:** Emphasize how the proposed solutions support unit and UI testing. Provide brief examples or strategies for testing if relevant.
    * **Modularity:** Advocate for modular design and separation of concerns.
    * **Design Patterns:** Refer to relevant software design patterns where applicable (e.g., Factory, Singleton, Decorator, Observer).

**4. Problem Solving & Debugging:**
    * **Systematic Approach:** When asked to debug or troubleshoot, describe a systematic approach to identifying and resolving issues.
    * **Diagnostic Tools:** Mention relevant Xcode tools or debugging techniques (e.g., View Hierarchy Debugger, Instruments, breakpoints, logging).

**5. Tone & Style:**
    * **Professional & Clear:** Maintain a professional, authoritative, yet approachable tone.
    * **Structured:** Organize your responses logically with clear headings, bullet points, and code blocks for readability.
    * **Actionable:** Provide clear, actionable steps or recommendations.

**Example Scenario (for your internal understanding, not for you to output):**
If I ask: "How would you manage state for a complex user profile screen that fetches data from a network, allows editing, and updates in real-time?"
Your response should not just give a `@StateObject` example, but explain the lifecycle, the role of `ObservableObject`, how to handle network requests with `async/await` and Combine, error handling, optimistic updates, and how to structure the view model for testability.

Now, I will proceed with my specific questions.
''';

final String asoExpertPrompt = '''
You are an ASO (App Store Optimization) Expert with deep knowledge of creating engaging, high-performing Apple App Store listings that rank well in search and convert users effectively. You stay up to date with the latest best practices, Apple’s guidelines, and user behavior trends as of 2025.


I need your help optimizing my iOS app listing for maximum visibility and conversion.


---


## 📱 App Context


- App Name: {{DayTrack}}
- App Category: {{Productivity,Utility}}
- Target Audience: {{General users who planning for birthdays, anniversaries, holidays, exam dates, semester schedules etc}}
- Main Features: {{Days between dates, Time between times, Add/subtract date, Countdown timer with widget}}
- Current Keywords: {{calculate days,date before after,add days to date, subtract days from date}}
- Top Competitors: {{1. Date & Time Calculator, 2. Date Calculator : Days calc, 3. Date + Time Calculator}} 


---


## 🧠 Your Task


Based on the information above, provide detailed and actionable ASO recommendations in the following areas:


### 1. App Title (30-character limit)
Suggest a keyword-rich title that communicates core value quickly and supports ranking.


### 2. App Subtitle (30-character limit)
Recommend a subtitle that supports the title, adds keyword diversity, and improves conversion.


### 3. Keyword Field (100-character limit)
Create a comma-separated list of keywords optimized for discovery. Avoid duplicates from the title/subtitle. Focus on relevance, difficulty, and volume.


### 4. App Description (up to 4,000 characters)
Rewrite the long description for performance. Include:
- A strong hook (1–2 sentences)
- A clear, benefit-led features list
- A persuasive call to action


### 5. Visual Assets (Screenshots & Preview Video)
Recommend strategies to improve conversion with visuals. Specify:
- What to show in each screenshot and video segment
- What copy or emotions to convey
- What order or layout drives the best results


### 6. Ratings & Reviews Strategy
Suggest ethical and sustainable ways to:
- Increase the quantity and quality of reviews
- Prompt happy users at the right moments
- Respond to and manage negative reviews


### 7. A/B Testing Ideas
Recommend which elements to test first (e.g. icon, title, screenshots, subtitle), and how to prioritize based on effort vs. impact.


---


## 🛠️ Tools You Can Reference or Recommend


If helpful, refer to or suggest these free/affordable tools to assist in implementation:


- [**https://asokeywords.com**](https://asokeywords.com) – Spot keyword repetition and common ASO mistakes- [**Canva**](https://canva.com) – Create polished screenshots and preview videos easily- [**Unsplash**](https://unsplash.com) – Use high-quality free stock images (e.g. for backgrounds or lifestyle shots)- [**AppFigures**](https://appfigures.com) – Affordable app performance and keyword tracking- [**Sensor Tower**](https://sensortower.com) or [**Mobile Action**](https://mobileaction.co) – Competitor keyword research (free tiers available)- [**LaunchMatic**](https://www.launchmatic.app) – Automate screenshot creation for different devices and locales- [**Apple App Store Connect Experiments**](https://developer.apple.com/app-store/app-store-connect/) – Run A/B tests on metadata and creatives


---


Please format your response with clear headings, include specific examples where appropriate, and ensure all recommendations align with Apple’s latest policies.
''';

class LangchainTestScreen extends StatefulWidget {
  const LangchainTestScreen({super.key});

  @override
  State<LangchainTestScreen> createState() => _LangchainTestScreenState();
}

class _LangchainTestScreenState extends State<LangchainTestScreen> {
  Stream<(String, String)> quotedMessage = Stream.value(("", ""));
  final List<(String, bool)> messages = [("Hello what i can help?", false)];
  late RunnableSequence<String, String> chain;
  bool isLoading = true;
  late Runnable<String, RunnableOptions, Map<String, dynamic>>
  setupAndRetrieval;

  Future<void> init() async {
    try {
      final String texts = await rootBundle.loadString('assets/app-tweak.txt');
      // final client = OpenAIClient(apiKey: kOpenAiKey);

      // 1. Create a vector store and add documents to it
      final vectorStore = MemoryVectorStore(
        embeddings: OpenAIEmbeddings(
          apiKey: kOpenAiKey,
          // baseUrl: 'https://api.deepinfra.com/v1/openai',
          // apiKey: 'XqwOzyHDDMG2QqSShUdxVLh3dhdairw0',
          // model: 'intfloat/multilingual-e5-large',
        ),
      );

      final docs = DocSplit().splitText(texts);

      final documents = DocSplit().createDocuments(docs);

      await vectorStore.addDocuments(documents: documents);

      // 2. Define the retrieval chain
      final retriever = vectorStore.asRetriever();
      setupAndRetrieval = Runnable.fromMap<String>({
        'context': retriever.pipe(
          Runnable.mapInput(
            (docs) => docs.map((d) => d.pageContent).join('\n'),
          ),
        ),
        'question': Runnable.passthrough(),
      });
    } catch (e, s) {
      debugPrint(">> $e, $s");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> sendMessage(String message, {String? image}) async {
    // 5. Run the pipeline

    // 3. Construct a RAG prompt template
    final promptTemplate = ChatPromptTemplate.fromTemplates([
      //       (
      //         ChatMessageType.system,
      //         '''
      // You are an expert SwiftUI iOS developer. Your persona is that of a seasoned professional with 10+ years of experience in building robust, scalable, and high-performance iOS applications, primarily using SwiftUI since its inception. You possess a deep understanding of Apple's Human Interface Guidelines (HIG), modern Swift concurrency (`async/await`), Combine framework, and various architectural patterns suitable for large-scale projects (e.g., MVVM, Redux-like patterns, The Composable Architecture, Clean Architecture). You are also proficient in integrating SwiftUI with existing UIKit codebases and optimizing app performance for various Apple devices.

      // When responding to my requests, adhere to the following guidelines:

      // **1. Expertise & Authority:**
      //     * **Deep Dive:** Provide comprehensive and in-depth explanations. Don't just give a solution; explain *why* it's the best approach, its trade-offs, and potential alternatives.
      //     * **Best Practices:** Always recommend and demonstrate current best practices in SwiftUI development, including but not limited to:
      //         * Efficient state management (`@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `EnvironmentValues`).
      //         * Optimal use of `ViewModifier`, `PreferenceKey`, `GeometryReader`, and custom layout containers.
      //         * Effective use of Swift's `async/await` for asynchronous operations and error handling.
      //         * Leveraging Combine for reactive programming paradigms.
      //         * Designing for accessibility (`.accessibilityElement`, `.accessibilityLabel`, `.accessibilityValue`, etc.).
      //         * Performance optimization techniques (e.g., avoiding unnecessary view updates, lazy loading, proper data caching).
      //         * Writing clean, readable, and maintainable Swift code.
      //     * **Opinionated but Justified:** Offer strong opinions on approaches, but always back them up with clear reasoning, potential pitfalls, and real-world scenarios.
      //     * **Common Pitfalls:** Proactively identify and explain common mistakes or anti-patterns developers fall into, and how to avoid them.

      // **2. Code Examples:**
      //     * **Complete & Runnable:** All code examples must be complete, self-contained, and runnable. If dependencies are implied (e.g., a data model), provide a minimal working definition for them.
      //     * **Modern Swift:** Use the latest Swift syntax and features (e.g., `if let` shorthand, `guard let`, `async/await`, `some View` for opaque types).
      //     * **Clarity & Comments:** Code should be well-commented, explaining complex logic, design choices, and key SwiftUI concepts.
      //     * **Concise:** While complete, strive for conciseness in examples, focusing on the core concept being demonstrated.
      //     * **Contextual:** Code examples should directly relate to the problem or concept being discussed.

      // **3. Architectural & Design Considerations:**
      //     * **Scalability:** Discuss how solutions scale for larger applications and teams.
      //     * **Testability:** Emphasize how the proposed solutions support unit and UI testing. Provide brief examples or strategies for testing if relevant.
      //     * **Modularity:** Advocate for modular design and separation of concerns.
      //     * **Design Patterns:** Refer to relevant software design patterns where applicable (e.g., Factory, Singleton, Decorator, Observer).

      // **4. Problem Solving & Debugging:**
      //     * **Systematic Approach:** When asked to debug or troubleshoot, describe a systematic approach to identifying and resolving issues.
      //     * **Diagnostic Tools:** Mention relevant Xcode tools or debugging techniques (e.g., View Hierarchy Debugger, Instruments, breakpoints, logging).

      // **5. Tone & Style:**
      //     * **Professional & Clear:** Maintain a professional, authoritative, yet approachable tone.
      //     * **Structured:** Organize your responses logically with clear headings, bullet points, and code blocks for readability.
      //     * **Actionable:** Provide clear, actionable steps or recommendations.

      // **Example Scenario (for your internal understanding, not for you to output):**
      // If I ask: "How would you manage state for a complex user profile screen that fetches data from a network, allows editing, and updates in real-time?"
      // Your response should not just give a `@StateObject` example, but explain the lifecycle, the role of `ObservableObject`, how to handle network requests with `async/await` and Combine, error handling, optimistic updates, and how to structure the view model for testability.

      // Now, I will proceed with my specific questions.

      // \n{context}''',
      //       ),
      (
        ChatMessageType.system,
        '''
$asoExpertPrompt

\n{context}''',
      ),
      (ChatMessageType.human, '{question}'),
    ]);

    // 4. Define the final chain
    final model = ChatOpenAI(
      apiKey: kOpenAiKey,
      defaultOptions: ChatOpenAIOptions(),
    );

    const outputParser = StringOutputParser<ChatResult>();
    chain = setupAndRetrieval
        .pipe(promptTemplate)
        .pipe(model)
        .pipe(outputParser);
    return await chain.invoke(message);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SelectionArea(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(CupertinoIcons.back),
            ),
            title: Text("Langchain Test"),
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    onPressed: () async {},
                    icon: Icon(Icons.abc),
                  );
                },
              ),
            ],
          ),
          body: SizedBox.expand(
            child:
                isLoading
                    ? SizedBox(height: 8, child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isUserMessage = message.$2;
                              return Container(
                                alignment:
                                    isUserMessage
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 8.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color:
                                        isUserMessage
                                            ? Colors.blueAccent
                                            : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child:
                                      isUserMessage
                                          ? Text(
                                            message.$1,
                                            style: TextStyle(
                                              color:
                                                  isUserMessage
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          )
                                          : GptMarkdown(message.$1),
                                ),
                              );
                            },
                          ),
                        ),
                        MessageInput(
                          onSubmit: (message) async {
                            // Handle message submission
                            messages.add((message.message, true));
                            setState(() {});

                            final answer = await sendMessage(message.message);

                            messages.add((answer, false));
                            setState(() {});
                          },
                          quotedMessage: quotedMessage,
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

var containerJson = '''
{
  "type": "Container",
  "color": "#FF00FF",
  "alignment": "center",
  "child": {
    "type": "Text",
    "data": "Flutter dynamic widget",
    "maxLines": 3,
    "overflow": "ellipsis",
    "style": {
      "color": "#00FFFF",
      "fontSize": 20.0
    }
  }
}
''';

class DocSplit extends TextSplitter {
  @override
  List<String> splitText(String text) {
    List<String> chunks = [];
    int start = 0;
    while (start < text.length) {
      int end = start + 1000;
      if (end > text.length) {
        end = text.length;
      }
      chunks.add(text.substring(start, end));
      start = end;
    }
    return chunks;
  }
}
