import SwiftUI

struct ContentView: View {
    @State private var isExamActive = false
    @State private var hasHighSchoolEducation = true
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

                VStack {
                    Text("First, what is your education level?")
                        .font(.headline)
                    Picker("Education Level", selection: $hasHighSchoolEducation) {
                        Text("High School Grad or More").tag(true)
                        Text("Less Than High School").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.top)

                VStack {
                    Text("Timer per Question: \(Int(timerDuration)) seconds")
                        .font(.headline)
                    Slider(value: $timerDuration, in: 10...120, step: 5)
                        .padding(.horizontal)
                }
                .padding()

                Spacer()

                Button(action: { isExamActive = true }) {
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

#Preview {
    ContentView()
}


