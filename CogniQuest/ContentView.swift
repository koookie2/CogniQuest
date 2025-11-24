import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isExamActive = false
    @State private var hasHighSchoolEducation = true
    @State private var timerDuration: Double = 60.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                appIconView

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
                ExamView(hasHighSchoolEducation: hasHighSchoolEducation, timerDuration: timerDuration, isExamActive: $isExamActive)
            }
        }
    }
}

extension ContentView {
    private var appIcon: UIImage? {
        guard
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last,
            let icon = UIImage(named: lastIcon)
        else {
            return nil
        }
        return icon
    }

    @ViewBuilder
    private var appIconView: some View {
        if let image = appIcon {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(radius: 6)
        } else {
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    ContentView()
}

