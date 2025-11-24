import SwiftUI

struct ExamView: View {
    let hasHighSchoolEducation: Bool
    let timerDuration: Double
    @Binding var isExamActive: Bool
    @StateObject private var viewModel: ExamViewModel
    @Environment(\.dismiss) private var dismiss


    init(hasHighSchoolEducation: Bool, timerDuration: Double, isExamActive: Binding<Bool>) {
        self.hasHighSchoolEducation = hasHighSchoolEducation
        self.timerDuration = timerDuration
        self._isExamActive = isExamActive
        _viewModel = StateObject(wrappedValue: ExamViewModel(hasHighSchoolEducation: hasHighSchoolEducation, timerDuration: timerDuration))
    }

    var questionTransition: AnyTransition {
        let forwardTransition = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        let backwardTransition = AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
        return viewModel.navigationDirection == .forward ? forwardTransition : backwardTransition
    }

    var body: some View {
        VStack {
            if viewModel.questions.isEmpty {
                VStack {
                    ProgressView("Loading Exam...")
                }
            } else {
                VStack {
                    let timeValue = max(0, viewModel.timeRemaining)
                    Text("Time Remaining: \(Int(timeValue))s")
                        .font(.headline)
                        .foregroundColor(timeValue <= 10 ? .red : .primary)
                    if timerDuration > 0 && !timeValue.isNaN && !timeValue.isInfinite {
                        ProgressView(value: timeValue, total: timerDuration)
                            .progressViewStyle(LinearProgressViewStyle(tint: timeValue <= 10 ? .red : .blue))
                    }
                }
                .padding(.horizontal)

                if viewModel.questions.count > 0 {
                    ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(viewModel.questions.count))
                        .padding()
                }

                VStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                        .font(.headline)
                        .foregroundColor(.gray)

                    ScrollView {
                        Text(viewModel.questions[viewModel.currentQuestionIndex].text)
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding()
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxHeight: 200)

                    questionView(for: viewModel.questions[viewModel.currentQuestionIndex])
                }
                .transition(questionTransition)
                .id(viewModel.currentQuestionIndex)

                Spacer()

                HStack {
                    if viewModel.currentQuestionIndex > 0 {
                        Button("Back") {
                            hideKeyboard()
                            viewModel.moveBack()
                        }
                        .padding()
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(viewModel.currentQuestionIndex == viewModel.questions.count - 1 ? "Finish Exam" : "Next") {
                        hideKeyboard()
                        // Small delay to ensure keyboard dismisses cleanly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.moveToNextQuestion()
                        }
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Exam")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { 
                    hideKeyboard()
                    dismiss() 
                }) { Image(systemName: "house.fill") }
            }
        }
        .navigationDestination(isPresented: $viewModel.showResults) {
            ResultsView(
                score: viewModel.score,
                hasHighSchoolEducation: hasHighSchoolEducation,
                questions: viewModel.questions,
                answers: viewModel.answers,
                questionScores: viewModel.questionScores,
                isExamActive: $isExamActive
            )
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    private func questionView(for question: Question) -> some View {
        switch question.type {
        case .orientation:
            TextInputView(questionId: question.id, answers: $viewModel.answers, placeholder: "Enter your answer")
        case .registration:
            RegistrationView(
                questionText: question.text,
                words: ["Apple", "Pen", "Tie", "House", "Car"],
                isNarrationComplete: Binding(
                    get: { viewModel.phase != .narrating },
                    set: { viewModel.setNarrating(!$0) }
                )
            )
        case .calculation:
            CalculationInputView(questionId: question.id, answers: $viewModel.answers)
        case .animalList:
            AnimalListView(questionId: question.id, answers: $viewModel.answers)
        case .fiveWordRecall:
            FiveWordRecallInputView(questionId: question.id, answers: $viewModel.answers)
        case .numberSeriesBackwards:
            NumberSeriesView(
                questionId: question.id,
                answers: $viewModel.answers,
                questionText: question.text,
                isNarrationComplete: Binding(
                    get: { viewModel.phase != .narrating },
                    set: { viewModel.setNarrating(!$0) }
                )
            )
        case .clockDrawing:
            ClockDrawingView(
                questionId: question.id,
                answers: $viewModel.answers,
                onPauseTimer: { viewModel.pauseTimer() },
                onResumeTimer: { viewModel.resumeTimer() },
                onSubmit: { viewModel.moveToNextQuestion() }
            )
        case .shapeIdentification:
            ShapeIdentificationView(questionId: question.id, answers: $viewModel.answers)
        case .storyRecall:
            StoryRecallView(questionId: question.id, answers: $viewModel.answers)
        }
    }
}
