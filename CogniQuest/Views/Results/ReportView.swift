import SwiftUI
import PDFKit

struct ReportView: View {
    let score: Int
    let interpretation: String
    let questions: [Question]
    let answers: [Int: Answer]

    struct ShareURLItem: Identifiable { let id = UUID(); let url: URL }
    @State private var shareItem: ShareURLItem?

    var body: some View {
        NavigationView {
            ScrollView { reportBody }
                .navigationTitle("Test Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: exportPDF) {
                            Label("Share as PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(item: $shareItem) { item in
                    ShareSheet(activityItems: [item.url], filename: item.url.lastPathComponent)
                }
        }
    }

    var reportBody: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack {
                Text("CogniQuest Screening Report").font(.title2).bold()
                Text("Generated on: \(Date().formatted(date: .long, time: .shortened))")
                    .font(.subheadline).foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary").font(.title3).bold()
                HStack { Text("Final Score:"); Spacer(); Text("\(score) / 30").bold() }
                HStack { Text("Interpretation:"); Spacer(); Text(interpretation).bold() }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)

            Text("Detailed Responses").font(.title3).bold().padding(.top)

            ForEach(questions.filter { $0.type != .registration }) { question in
                VStack(alignment: .leading) {
                    Text("Q\(question.id): \(question.text.split(separator: "\n").first ?? "")")
                        .font(.headline)
                    Text(formattedAnswer(for: question))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                Divider()
            }
        }
        .padding()
    }

    private func formattedAnswer(for question: Question) -> String {
        guard let answer = answers[question.id] else { return "No Response" }
        switch (question.type, answer) {
        case (.calculation, .calculation(let c)): return "Spent: $\(c.spent), Left: $\(c.left)"
        case (.animalList, .animalCount(let n)): return "Named \(n) animals."
        case (.fiveWordRecall, .fiveWordRecall(let words)):
            let filtered = words.filter { !$0.isEmpty }
            return filtered.isEmpty ? "No Response" : filtered.joined(separator: ", ")
        case (.numberSeriesBackwards, .numberSeries(let s)):
            return "87 -> \(s.series1.isEmpty ? "NR" : s.series1), 648 -> \(s.series2.isEmpty ? "NR" : s.series2), 8537 -> \(s.series3.isEmpty ? "NR" : s.series3)"
        case (.storyRecall, .story(let st)):
            return "Name: \(st.womanName.isEmpty ? "NR" : st.womanName), Work: \(st.profession.isEmpty ? "NR" : st.profession), Returned: \(st.whenReturnedToWork.isEmpty ? "NR" : st.whenReturnedToWork), State: \(st.state.isEmpty ? "NR" : st.state)"
        case (.shapeIdentification, .shape(let shp)):
            return "Tapped: \(shp.tappedShape ?? "NR"), Largest: \(shp.largestShape ?? "NR")"
        case (.clockDrawing, .clockDrawing(let clock)):
            let numbersStatus = clock.hasCorrectNumbers ? "✓" : "✗"
            let timeStatus = clock.hasCorrectTime ? "✓" : "✗"
            return "Numbers: \(numbersStatus), Time: \(timeStatus)"
        case (.clockDrawing, _): return "Drawing was recorded."
        case (.orientation, .text(let t)): return t
        case (.orientation, .number(let n)): return String(n)
        default: return "No Response"
        }
    }

    @MainActor
    private func exportPDF() {
        // Render SwiftUI to PDF pages with UIGraphicsPDFRenderer
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size @72dpi
        let hosting = UIHostingController(rootView: reportBody.frame(maxWidth: .infinity))
        hosting.view.bounds = CGRect(x: 0, y: 0, width: 612, height: 792)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CogniQuest_Report_\(UUID().uuidString.prefix(6)).pdf")
        do {
            try data.write(to: url)
            shareItem = ShareURLItem(url: url)
        } catch {
            // Swallow for now; in production present an alert
        }
    }
}

// ShareSheet is defined in Views/Results/ShareSheet.swift


