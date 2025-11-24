import SwiftUI

struct ResultsView: View {
    let score: Int
    let hasHighSchoolEducation: Bool
    let questions: [Question]
    let answers: [Int: Answer]
    let questionScores: [Int: Int]
    @Binding var isExamActive: Bool
    @State private var showReport = false

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

            Button(action: { showReport = true }) {
                Label("View Report", systemImage: "doc.text.fill")
            }
            .buttonStyle(.bordered)

            Text("Disclaimer: This is a screening tool and not a diagnosis. Please consult a healthcare professional with any concerns.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            Button(action: { isExamActive = false }) {
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
        .sheet(isPresented: $showReport) {
            ReportView(
                score: score,
                interpretation: interpretation,
                questions: questions,
                answers: answers,
                questionScores: questionScores,
                hasHighSchoolEducation: hasHighSchoolEducation
            )
        }
    }

    private func getScoreRanges() -> (normal: ClosedRange<Int>, mild: ClosedRange<Int>, dementia: ClosedRange<Int>) {
        if hasHighSchoolEducation {
            return (normal: 27...30, mild: 21...26, dementia: 0...20)
        } else {
            return (normal: 25...30, mild: 20...24, dementia: 0...19)
        }
    }

    private var interpretationColor: Color {
        switch interpretation {
        case "Normal Cognition": return .green
        case "Mild Neurocognitive Disorder Likely": return .orange
        default: return .red
        }
    }
}
