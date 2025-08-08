import SwiftUI

struct StoryRecallView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
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
            if case let .story(saved)? = answers[questionId] {
                womanName = saved.womanName
                profession = saved.profession
                when = saved.whenReturnedToWork
                state = saved.state
            } else {
                womanName = ""; profession = ""; when = ""; state = ""
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Story recall inputs")
    }

    private func updateAnswers() {
        let story = StoryAnswer(
            womanName: womanName,
            profession: profession,
            whenReturnedToWork: when,
            state: state
        )
        answers[questionId] = .story(story)
    }
}


