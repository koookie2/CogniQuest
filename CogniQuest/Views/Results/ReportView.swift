import SwiftUI
import PDFKit
import UIKit

struct ReportView: View {
    let score: Int
    let interpretation: String
    let questions: [Question]
    let answers: [Int: Answer]
    let questionScores: [Int: Int]

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
        VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 6) {
                Text("CogniQuest Screening Report")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.black)
                Text("Generated on: \(Date().formatted(date: .long, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary").font(.title3.weight(.bold)).foregroundColor(.black)
                HStack {
                    Text("Final Score:").foregroundColor(.black)
                    Spacer()
                    Text("\(score) / 30").fontWeight(.bold).foregroundColor(.black)
                }
                HStack {
                    Text("Interpretation:").foregroundColor(.black)
                    Spacer()
                    Text(interpretation).fontWeight(.bold).foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )

            Text("Detailed Responses").font(.title3.weight(.bold)).foregroundColor(.black).padding(.top, 8)

            ForEach(questions.filter { $0.type != .registration }) { question in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Q\(question.id): \(question.text.split(separator: "\n").first ?? "")")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("Score: \(scoreSummary(for: question))")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Text(formattedAnswer(for: question))
                        .font(.body)
                        .foregroundColor(.black)
                }
                Divider()
                    .overlay(Color.black.opacity(0.1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color.white)
    }

    private func scoreSummary(for question: Question) -> String {
        let earned = questionScores[question.id] ?? 0
        return "\(earned)/\(question.points)"
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
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size @72dpi
        let printableWidth = pageRect.width - 48
        let paddedView = reportBody
            .frame(width: printableWidth, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .background(Color.white)
        let hosting = UIHostingController(rootView: paddedView)
        hosting.view.backgroundColor = .white
        hosting.view.bounds = CGRect(origin: .zero, size: CGSize(width: pageRect.width, height: 10))
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()

        let targetSize = hosting.view.systemLayoutSizeFitting(
            CGSize(width: pageRect.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        hosting.view.bounds = CGRect(origin: .zero, size: CGSize(width: pageRect.width, height: targetSize.height))
        hosting.view.layoutIfNeeded()

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            var offset: CGFloat = 0
            while offset < targetSize.height {
                ctx.beginPage()
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: 0, y: -offset)
                hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
                ctx.cgContext.restoreGState()
                offset += pageRect.height
            }
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
