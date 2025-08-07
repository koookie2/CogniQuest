import SwiftUI
import AVFoundation // Import the framework for text-to-speech

// --- Data Models ---
// Represents a single question in the exam
struct Question {
    let id: Int
    let text: String
    let type: QuestionType
    let points: Int
}

// Defines the different types of questions we'll have
enum QuestionType {
    case orientation
    case registration // New type for the initial word list
    case calculation
    case animalList
    case fiveWordRecall
    case numberSeriesBackwards // New type for the number series
    case clockDrawing
    case shapeIdentification
    case storyRecall
}

// Represents a single continuous line drawn by the user
struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    let color: Color
    let lineWidth: CGFloat
}

// --- Main Content View (Home Screen) ---
struct ContentView: View {
    @State private var isExamActive = false
    @State private var hasHighSchoolEducation = true // Default value
    @State private var timerDuration: Double = 60.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Text("CogniQuest")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("A screening tool for cognitive function.")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Education Level Toggle
                VStack {
                    Text("First, what is your education level?")
                        .font(.headline)
                    Picker("Education Level", selection: $hasHighSchoolEducation) {
                        Text("High School Grad or More").tag(true)
                        Text("Less Than High School").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.top)

                // Timer Configuration
                VStack {
                    Text("Timer per Question: \(Int(timerDuration)) seconds")
                        .font(.headline)
                    Slider(value: $timerDuration, in: 10...120, step: 5)
                        .padding(.horizontal)
                }
                .padding()


                Spacer()

                // Start Button
                Button(action: {
                    isExamActive = true
                }) {
                    Text("Start Exam")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationDestination(isPresented: $isExamActive) {
                ExamView(hasHighSchoolEducation: hasHighSchoolEducation, timerDuration: timerDuration)
            }
        }
    }
}


// --- Exam View ---
struct ExamView: View {
    let hasHighSchoolEducation: Bool
    let timerDuration: Double

    @State private var currentQuestionIndex = 0
    @State private var answers: [Int: Any] = [:]
    @State private var score = 0
    @State private var showResults = false
    @Environment(\.presentationMode) var presentationMode
    
    // State to track animation direction
    enum NavigationDirection { case forward, backward }
    @State private var navigationDirection: NavigationDirection = .forward

    // Timer state
    @State private var timeRemaining: Double
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isNarrationComplete = true // Default to true for non-voice questions

    // Define all the questions for the exam, reordered and updated
    let questions: [Question] = [
        Question(id: 1, text: "What day of the week is it?", type: .orientation, points: 1),
        Question(id: 2, text: "What is the year?", type: .orientation, points: 1),
        Question(id: 3, text: "What state are we in?", type: .orientation, points: 1),
        Question(id: 4, text: "Please remember these five objects. I will ask you what they are later.", type: .registration, points: 0),
        Question(id: 5, text: "You have $100. You buy a dozen apples for $3 and a tricycle for $20.", type: .calculation, points: 3),
        Question(id: 6, text: "Please name as many animals as you can in one minute.", type: .animalList, points: 3),
        Question(id: 7, text: "What were the five objects I asked you to remember?", type: .fiveWordRecall, points: 5),
        Question(id: 8, text: "I am going to give you a series of numbers and I would like you to give them to me backwards. For example, if I say 42, you would say or type 24.", type: .numberSeriesBackwards, points: 2),
        Question(id: 9, text: "Draw a clock with all the numbers and set the time to ten minutes to eleven o'clock.", type: .clockDrawing, points: 4),
        Question(id: 10, text: "Please place an 'X' in the triangle. Then, identify which of the figures is largest.", type: .shapeIdentification, points: 2),
        Question(id: 11, text: "Listen to this story and answer the questions:\n\nJill was a very successful stockbroker. She made a lot of money on the stock market. She then met Jack, a devastatingly handsome man. She married him and had three children. They lived in Chicago. She then stopped work and stayed at home to bring up her children. When they were teenagers, she went back to work. She and Jack lived happily ever after.", type: .storyRecall, points: 8)
    ]
    
    init(hasHighSchoolEducation: Bool, timerDuration: Double) {
        self.hasHighSchoolEducation = hasHighSchoolEducation
        self.timerDuration = timerDuration
        _timeRemaining = State(initialValue: timerDuration)
    }
    
    // Computed property for dynamic transition
    var questionTransition: AnyTransition {
        let forwardTransition = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        let backwardTransition = AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
        
        return navigationDirection == .forward ? forwardTransition : backwardTransition
    }

    var body: some View {
        VStack {
            if showResults {
                ResultsView(score: score, hasHighSchoolEducation: hasHighSchoolEducation, presentationMode: _presentationMode)
            } else {
                // Timer Display
                VStack {
                    Text("Time Remaining: \(Int(timeRemaining))s")
                        .font(.headline)
                        .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                    ProgressView(value: timeRemaining, total: timerDuration)
                        .progressViewStyle(LinearProgressViewStyle(tint: timeRemaining <= 10 ? .red : .blue))
                }
                .padding(.horizontal)
                
                // Progress Bar
                ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                    .padding()

                // Question View
                VStack {
                    Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        Text(questions[currentQuestionIndex].text)
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding()
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxHeight: 200)

                    questionView(for: questions[currentQuestionIndex])
                }
                .transition(questionTransition) // Use the dynamic transition
                .id(currentQuestionIndex)

                Spacer()

                // Navigation Buttons
                HStack {
                    if currentQuestionIndex > 0 {
                        Button("Back") {
                            // --- FIX: Add guard to prevent index out of range ---
                            guard currentQuestionIndex > 0 else { return }
                            navigationDirection = .backward // Set direction
                            withAnimation {
                                currentQuestionIndex -= 1
                            }
                        }
                        .padding()
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(currentQuestionIndex == questions.count - 1 ? "Finish Exam" : "Next") {
                        moveToNextQuestion()
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onReceive(timer) { _ in
            guard !showResults, isNarrationComplete else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                moveToNextQuestion()
            }
        }
        .onChange(of: currentQuestionIndex) {
            resetTimer()
        }
        .onChange(of: showResults) {
            if showResults {
                self.timer.upstream.connect().cancel()
            }
        }
        .navigationTitle("Exam")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                 Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "house.fill")
                }
            }
        }
    }

    // --- View Builder for Questions ---
    @ViewBuilder
    private func questionView(for question: Question) -> some View {
        switch question.type {
        case .orientation:
            TextInputView(questionId: question.id, answers: $answers, placeholder: "Enter your answer")
        case .registration:
            Text("Apple, Pen, Tie, House, Car")
                .font(.title2.bold())
                .padding()
        case .calculation:
            CalculationInputView(questionId: question.id, answers: $answers)
        case .animalList:
            AnimalListView(questionId: question.id, answers: $answers)
        case .fiveWordRecall:
            FiveWordRecallInputView(questionId: question.id, answers: $answers)
        case .numberSeriesBackwards:
            NumberSeriesView(questionId: question.id, answers: $answers, questionText: question.text, isNarrationComplete: $isNarrationComplete)
        case .clockDrawing:
            DrawingView(questionId: question.id, answers: $answers)
        case .shapeIdentification:
            ShapeIdentificationView(questionId: question.id, answers: $answers)
        case .storyRecall:
            StoryRecallView(questionId: question.id, answers: $answers)
        }
    }
    
    // --- Timer and Navigation Logic ---
    private func resetTimer() {
        isNarrationComplete = true
        timeRemaining = timerDuration
    }

    private func moveToNextQuestion() {
        navigationDirection = .forward // Set direction
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            calculateScore()
            showResults = true
        }
    }

    // --- Scoring Logic ---
    private func calculateScore() {
        var totalScore = 0

        // Questions 1, 2, 3: Orientation (3 pts)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let currentDay = dateFormatter.string(from: Date())
        if let answer = answers[1] as? String, answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == currentDay.lowercased() { totalScore += 1 }
        let currentYear = Calendar.current.component(.year, from: Date())
        if let answer = answers[2] as? Int, answer == currentYear { totalScore += 1 }
        if let answer = answers[3] as? String, !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { totalScore += 1 }

        // Question 4 is unscored registration
        
        // Question 5: Calculation (3 pts)
        if let calcAnswers = answers[5] as? [String: Int] {
            if calcAnswers["spent"] == 23 {
                totalScore += 1
            }
            if calcAnswers["left"] == 77 {
                totalScore += 2
            }
        }
        
        // Question 6: Animal List (3 pts)
        if let count = answers[6] as? Int {
            if count >= 15 {
                totalScore += 3
            } else if count >= 10 {
                totalScore += 2
            } else if count >= 5 {
                totalScore += 1
            }
        }

        // Question 7: Five Word Recall (5 pts)
        if let recalledWords = answers[7] as? [String] {
            let correctWords: Set<String> = ["apple", "pen", "tie", "house", "car"]
            var correctCount = 0
            for word in recalledWords {
                if correctWords.contains(word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
                    correctCount += 1
                }
            }
            totalScore += correctCount
        }
        
        // Question 8: Number Series Backwards (2 pts)
        if let numberAnswers = answers[8] as? [String: String] {
            if numberAnswers["series2"] == "846" { totalScore += 1 }
            if numberAnswers["series3"] == "7358" { totalScore += 1 }
        }
        
        // Question 9 is a placeholder (drawing is not scored automatically)

        // Question 10: Shape Identification (2 pts)
        if let shapeAnswers = answers[10] as? [String: String?] {
            if shapeAnswers["tappedShape"] ?? nil == "Triangle" {
                totalScore += 1
            }
            if shapeAnswers["largestShape"] ?? nil == "Square" {
                totalScore += 1
            }
        }

        // Question 11: Story Recall (8 pts)
        if let storyAnswers = answers[11] as? [String: String] {
            if (storyAnswers["womanName"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "") == "jill" { totalScore += 2 }
            if (storyAnswers["profession"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "") == "stockbroker" { totalScore += 2 }
            if (storyAnswers["when"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "").contains("teenagers") { totalScore += 2 }
            if (storyAnswers["state"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "") == "illinois" { totalScore += 2 } // Chicago is in Illinois
        }

        self.score = totalScore
    }
}

// --- Question Input Views ---

struct TextInputView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    let placeholder: String
    @State private var text: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .padding()
            .onChange(of: text) {
                if let num = Int(text) {
                    answers[questionId] = num
                } else {
                    answers[questionId] = text
                }
            }
            .onAppear {
                if let savedAnswer = answers[questionId] as? String {
                    text = savedAnswer
                } else if let savedAnswer = answers[questionId] as? Int {
                    text = "\(savedAnswer)"
                } else {
                    text = ""
                }
            }
    }
}

struct CalculationInputView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    @State private var amountSpent: String = ""
    @State private var amountLeft: String = ""

    var body: some View {
        VStack(spacing: 15) {
            TextField("How much did you spend?", text: $amountSpent)
                .keyboardType(.numberPad)
            TextField("How much do you have left?", text: $amountLeft)
                .keyboardType(.numberPad)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onChange(of: amountSpent) { updateAnswers() }
        .onChange(of: amountLeft) { updateAnswers() }
        .onAppear {
            if let saved = answers[questionId] as? [String: Int] {
                amountSpent = saved["spent"].map { "\($0)" } ?? ""
                amountLeft = saved["left"].map { "\($0)" } ?? ""
            }
        }
    }

    private func updateAnswers() {
        let calcAnswers = [
            "spent": Int(amountSpent) ?? 0,
            "left": Int(amountLeft) ?? 0
        ]
        answers[questionId] = calcAnswers
    }
}

struct AnimalListView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    @State private var animalCount: Double = 0

    var body: some View {
        VStack {
            Text("\(Int(animalCount)) animals named")
                .font(.title2)
            Slider(value: $animalCount, in: 0...20, step: 1)
                .padding()
                .onChange(of: animalCount) {
                    answers[questionId] = Int(animalCount)
                }
                .onAppear {
                    if let savedAnswer = answers[questionId] as? Int {
                        animalCount = Double(savedAnswer)
                    } else {
                        animalCount = 0
                    }
                }
        }
    }
}

struct FiveWordRecallInputView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    @State private var recalledWords: [String] = Array(repeating: "", count: 5)

    var body: some View {
        VStack {
            ForEach(0..<5, id: \.self) { index in
                TextField("Object \(index + 1)", text: $recalledWords[index])
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onChange(of: recalledWords) {
            answers[questionId] = recalledWords
        }
        .onAppear {
            if let savedAnswer = answers[questionId] as? [String] {
                recalledWords = savedAnswer
            } else {
                recalledWords = Array(repeating: "", count: 5)
            }
        }
    }
}

struct StoryRecallView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    @State private var womanName: String = ""
    @State private var profession: String = ""
    @State private var when: String = ""
    @State private var state: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                TextField("What was the female's name?", text: $womanName)
                TextField("What work did she do?", text: $profession)
                TextField("When did she go back to work?", text: $when)
                TextField("What state did she live in?", text: $state)
            }
            .textFieldStyle(.roundedBorder)
            .padding()
        }
        .onChange(of: womanName) { updateAnswers() }
        .onChange(of: profession) { updateAnswers() }
        .onChange(of: when) { updateAnswers() }
        .onChange(of: state) { updateAnswers() }
        .onAppear {
            if let saved = answers[questionId] as? [String: String] {
                womanName = saved["womanName"] ?? ""
                profession = saved["profession"] ?? ""
                when = saved["when"] ?? ""
                state = saved["state"] ?? ""
            } else {
                womanName = ""
                profession = ""
                when = ""
                state = ""
            }
        }
    }
    
    private func updateAnswers() {
        let storyAnswers = [
            "womanName": womanName,
            "profession": profession,
            "when": when,
            "state": state
        ]
        answers[questionId] = storyAnswers
    }
}

// --- Drawing View for Clock ---
struct DrawingView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    @State private var paths: [DrawingPath] = []
    @State private var currentPath = DrawingPath(color: .primary, lineWidth: 3.0)

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                
                Canvas { context, size in
                    for path in paths {
                        var path2D = Path()
                        path2D.addLines(path.points)
                        context.stroke(path2D, with: .color(path.color), lineWidth: path.lineWidth)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentPath.points.append(value.location)
                            if paths.last?.id == currentPath.id {
                                paths[paths.count - 1] = currentPath
                            } else {
                                paths.append(currentPath)
                            }
                        }
                        .onEnded { value in
                            answers[questionId] = paths
                            currentPath = DrawingPath(color: .primary, lineWidth: 3.0)
                        }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()

            Button(action: {
                paths.removeAll()
                answers[questionId] = paths
            }) {
                Label("Clear Drawing", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .onAppear {
            if let savedPaths = answers[questionId] as? [DrawingPath] {
                paths = savedPaths
            }
        }
    }
}

// --- Shape Identification View ---
struct ShapeIdentificationView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    
    @State private var tappedShape: String? = nil
    @State private var largestShape: String? = nil

    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 15) {
                ShapeContainer(shape: Rectangle(), name: "Square", tappedShape: $tappedShape)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 100)

                ShapeContainer(shape: Triangle(), name: "Triangle", tappedShape: $tappedShape)
                    .frame(width: 70, height: 70)

                ShapeContainer(shape: Rectangle(), name: "Rectangle", tappedShape: $tappedShape)
                    .frame(width: 40, height: 90)
            }
            .frame(height: 110)
            
            Divider().padding()

            Text("Which of the figures is largest?")
                .font(.headline)
            
            HStack(spacing: 15) {
                Button("Square") { largestShape = "Square" }
                    .buttonStyle(.bordered)
                    .background(largestShape == "Square" ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                
                Button("Triangle") { largestShape = "Triangle" }
                    .buttonStyle(.bordered)
                    .background(largestShape == "Triangle" ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)

                Button("Rectangle") { largestShape = "Rectangle" }
                    .buttonStyle(.bordered)
                    .background(largestShape == "Rectangle" ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
        }
        .onChange(of: tappedShape) { updateAnswers() }
        .onChange(of: largestShape) { updateAnswers() }
        .onAppear {
            if let saved = answers[questionId] as? [String: String?] {
                tappedShape = saved["tappedShape"] ?? nil
                largestShape = saved["largestShape"] ?? nil
            }
        }
    }
    
    private func updateAnswers() {
        let shapeAnswers: [String: String?] = [
            "tappedShape": tappedShape,
            "largestShape": largestShape
        ]
        answers[questionId] = shapeAnswers
    }
}

// Helper views for ShapeIdentificationView
struct ShapeContainer<S: Shape>: View {
    let shape: S
    let name: String
    @Binding var tappedShape: String?

    var body: some View {
        ZStack {
            shape
                .stroke(Color.primary, lineWidth: 2)
            
            if tappedShape == name {
                Text("X")
                    .font(.largeTitle)
                    .foregroundColor(.red)
            }
        }
        .contentShape(shape)
        .onTapGesture {
            tappedShape = name
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// --- Number Series View (Redesigned) ---
class SpeechManager: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var speechQueue: [AVSpeechUtterance] = []
    
    @Published var isSpeaking = false
    
    var onQueueFinish: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func speak(queue: [String]) {
        guard !queue.isEmpty, !synthesizer.isSpeaking else { return }
        
        speechQueue = queue.map { text in
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha") ?? AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
            utterance.postUtteranceDelay = 1.0
            return utterance
        }
        
        isSpeaking = true
        synthesizer.speak(speechQueue.removeFirst())
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !speechQueue.isEmpty {
            synthesizer.speak(speechQueue.removeFirst())
        } else {
            isSpeaking = false
            onQueueFinish?()
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        isSpeaking = false
    }
}

struct AudioVisualizerView: View {
    @Binding var isSpeaking: Bool
    @State private var barHeights: [CGFloat] = [10, 10, 10]
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Rectangle()
                    .frame(width: 8, height: barHeights[i])
                    .animation(.easeInOut(duration: 0.2), value: barHeights)
            }
        }
        .foregroundColor(.blue)
        .onChange(of: isSpeaking) {
            if isSpeaking {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    private func startAnimating() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            barHeights = [CGFloat.random(in: 10...50), CGFloat.random(in: 10...50), CGFloat.random(in: 10...50)]
        }
    }
    
    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
        barHeights = [10, 10, 10]
    }
}

struct NumberSeriesView: View {
    let questionId: Int
    @Binding var answers: [Int: Any]
    let questionText: String
    @Binding var isNarrationComplete: Bool
    
    @State private var answer1: String = ""
    @State private var answer2: String = ""
    @State private var answer3: String = ""
    
    @StateObject private var speechManager = SpeechManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Listen and Recall")
                .font(.title3).bold()
            
            AudioVisualizerView(isSpeaking: $speechManager.isSpeaking)
                .frame(height: 50)
            
            VStack(spacing: 15) {
                TextField("Enter first number backwards", text: $answer1)
                    .keyboardType(.numberPad)
                TextField("Enter second number backwards", text: $answer2)
                    .keyboardType(.numberPad)
                TextField("Enter third number backwards", text: $answer3)
                    .keyboardType(.numberPad)
            }
            .textFieldStyle(.roundedBorder)
        }
        .padding()
        .onChange(of: answer1) { updateAnswers() }
        .onChange(of: answer2) { updateAnswers() }
        .onChange(of: answer3) { updateAnswers() }
        .onAppear {
            isNarrationComplete = false
            setupAndPlaySequence()
            if let saved = answers[questionId] as? [String: String] {
                answer1 = saved["series1"] ?? ""
                answer2 = saved["series2"] ?? ""
                answer3 = saved["series3"] ?? ""
            }
        }
        .onDisappear {
            speechManager.stop()
        }
    }
    
    private func setupAndPlaySequence() {
        let series1 = "eighty-seven"
        let series2 = "six hundred forty-eight"
        let series3 = "eight thousand, five hundred thirty-seven"
        
        let speechSequence = [questionText, series1, series2, series3]
        
        speechManager.onQueueFinish = {
            isNarrationComplete = true
        }
        
        speechManager.speak(queue: speechSequence)
    }
    
    private func updateAnswers() {
        let numberAnswers = [
            "series1": answer1,
            "series2": answer2,
            "series3": answer3
        ]
        answers[questionId] = numberAnswers
    }
}


// --- Results View ---
struct ResultsView: View {
    let score: Int
    let hasHighSchoolEducation: Bool
    @Environment(\.presentationMode) var presentationMode

    var interpretation: String {
        let scoreRanges = getScoreRanges()
        if score >= scoreRanges.normal.lowerBound {
            return "Normal Cognition"
        } else if score >= scoreRanges.mild.lowerBound {
            return "Mild Neurocognitive Disorder Likely"
        } else {
            return "Dementia is Likely"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Exam Complete")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your Score: \(score) / 30")
                .font(.title)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .center, spacing: 10) {
                Text("Interpretation:")
                    .font(.headline)
                Text(interpretation)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(interpretationColor)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Text("Disclaimer: This is a screening tool and not a diagnosis. Please consult a healthcare professional with any concerns.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Back to Home")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    // --- Helper functions for Results View ---
    private func getScoreRanges() -> (normal: ClosedRange<Int>, mild: ClosedRange<Int>, dementia: ClosedRange<Int>) {
        if hasHighSchoolEducation {
            return (normal: 27...30, mild: 21...26, dementia: 0...20)
        } else {
            return (normal: 25...30, mild: 20...24, dementia: 0...19)
        }
    }

    private var interpretationColor: Color {
        switch interpretation {
        case "Normal Cognition":
            return .green
        case "Mild Neurocognitive Disorder Likely":
            return .orange
        default:
            return .red
        }
    }
}


// --- SwiftUI Previews ---
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
