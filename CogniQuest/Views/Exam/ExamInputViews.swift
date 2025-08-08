import SwiftUI

struct TextInputView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    let placeholder: String
    @State private var text: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .padding()
            .onChange(of: text) {
                if let num = Int(text) { answers[questionId] = .number(num) }
                else { answers[questionId] = .text(text) }
            }
            .onAppear {
                if case let .text(t)? = answers[questionId] { text = t }
                else if case let .number(n)? = answers[questionId] { text = "\(n)" }
                else { text = "" }
            }
            .accessibilityLabel("Text answer input")
    }
}

struct CalculationInputView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
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
            if case let .calculation(saved)? = answers[questionId] {
                amountSpent = "\(saved.spent)"
                amountLeft = "\(saved.left)"
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Enter spent and remaining amounts")
    }

    private func updateAnswers() {
        let calc = CalculationAnswer(spent: Int(amountSpent) ?? 0, left: Int(amountLeft) ?? 0)
        answers[questionId] = .calculation(calc)
    }
}

struct AnimalListView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    @State private var animalCount: Double = 0

    var body: some View {
        VStack {
            Text("\(Int(animalCount)) animals named").font(.title2)
            Slider(value: $animalCount, in: 0...20, step: 1)
                .padding()
                .onChange(of: animalCount) {
                    answers[questionId] = .animalCount(Int(animalCount))
                }
                .onAppear {
                    if case let .animalCount(n)? = answers[questionId] { animalCount = Double(n) } else { animalCount = 0 }
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Animal count")
        .accessibilityHint("Adjust the slider to set the number of animals named")
    }
}

struct FiveWordRecallInputView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    @State private var recalledWords: [String] = Array(repeating: "", count: 5)

    var body: some View {
        VStack {
            ForEach(0..<5, id: \.self) { index in
                TextField("Object \(index + 1)", text: $recalledWords[index])
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .onChange(of: recalledWords) { answers[questionId] = .fiveWordRecall(recalledWords) }
        .onAppear {
            if case let .fiveWordRecall(words)? = answers[questionId] { recalledWords = words } else { recalledWords = Array(repeating: "", count: 5) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Five word recall inputs")
    }
}


