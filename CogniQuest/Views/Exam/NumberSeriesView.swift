import SwiftUI

struct NumberSeriesView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    let questionText: String
    @Binding var isNarrationComplete: Bool

    @State private var answer1: String = ""
    @State private var answer2: String = ""
    @State private var answer3: String = ""

    @StateObject private var speechManager = SpeechManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Listen and Recall").font(.title3).bold()
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
            if case let .numberSeries(saved)? = answers[questionId] {
                answer1 = saved.series1
                answer2 = saved.series2
                answer3 = saved.series3
            }
        }
        .onDisappear { speechManager.stop() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Number series inputs")
    }

    private func setupAndPlaySequence() {
        let series1 = "eighty-seven"
        let series2 = "six hundred forty-eight"
        let series3 = "eight thousand, five hundred thirty-seven"
        let speechSequence = [questionText, series1, series2, series3]

        speechManager.onQueueFinish = { isNarrationComplete = true }
        speechManager.speak(queue: speechSequence)
    }

    private func updateAnswers() {
        let numberAnswers = NumberSeriesAnswer(series1: answer1, series2: answer2, series3: answer3)
        answers[questionId] = .numberSeries(numberAnswers)
    }
}


