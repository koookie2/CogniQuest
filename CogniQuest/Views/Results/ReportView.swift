import SwiftUI
import PDFKit
import UIKit

struct ReportView: View {
    let score: Int
    let interpretation: String
    let questions: [Question]
    let answers: [Int: Answer]
    let questionScores: [Int: Int]
    let hasHighSchoolEducation: Bool

    struct ShareURLItem: Identifiable { let id = UUID(); let url: URL }
    @State private var shareItem: ShareURLItem?

    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 32
    private let questionSpacing: CGFloat = 12

    private var reportQuestions: [Question] {
        questions.filter { $0.type != .registration }
    }

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
            headerSection
            questionsSection
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(Color.white)
    }

    private var headerSection: some View {
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
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary").font(.title3.weight(.bold)).foregroundColor(.black)
                HStack {
                    Text("Education Level:").foregroundColor(.black)
                    Spacer()
                    Text(hasHighSchoolEducation ? "High School or Above" : "Less than High School")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Origin & Disclaimer")
                    .font(.headline)
                    .foregroundColor(.black)
                Text("This assessment is adapted from the SLU Mental Status Exam (SLUMS).")
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Refer to SLU's guidance for interpreting results:")
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Link("https://www.slu.edu/medicine/internal-medicine/geriatric-medicine/aging-successfully/assessment-tools/mental-status-exam.php",
                     destination: URL(string: "https://www.slu.edu/medicine/internal-medicine/geriatric-medicine/aging-successfully/assessment-tools/mental-status-exam.php")!)
                    .foregroundColor(.blue)
                    .font(.footnote)
                Text("Disclaimer: This screening is not a diagnosis. Always consult a healthcare professional for medical advice.")
                    .foregroundColor(.black)
                    .font(.footnote)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )

            detailedHeading
        }
    }

    private var detailedHeading: some View {
        Text("Detailed Responses")
            .font(.title3.weight(.bold))
            .foregroundColor(.black)
            .padding(.top, 4)
    }

    private var continuationHeading: some View {
        Text("Detailed Responses (continued)")
            .font(.title3.weight(.bold))
            .foregroundColor(.black)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: questionSpacing) {
            ForEach(reportQuestions) { question in
                questionBlock(for: question)
            }
        }
    }

    @ViewBuilder
    private func questionBlock(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Q\(question.id): \(question.text)")
                .font(.headline)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
            Text("Score: \(scoreSummary(for: question))")
                .font(.subheadline)
                .foregroundColor(.black)
            Text(formattedAnswer(for: question))
                .font(.body)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        Divider()
            .overlay(Color.black.opacity(0.1))
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
        let pageRect = CGRect(origin: .zero, size: CGSize(width: 612, height: 792))
        let printableWidth = pageRect.width - (horizontalPadding * 2)
        let availableHeight = pageRect.height - (verticalPadding * 2)

        let headerHeight = measureHeight(of: headerSection, width: printableWidth)
        let continuationHeight = measureHeight(of: continuationHeading, width: printableWidth)

        var blockHeights: [Int: CGFloat] = [:]
        for question in reportQuestions {
            blockHeights[question.id] = measureHeight(of: questionBlock(for: question), width: printableWidth)
        }

        var remainingQuestions = reportQuestions
        var pageQuestionSets: [[Question]] = []
        var isFirstPage = true

        while !remainingQuestions.isEmpty {
            var remainingHeight = availableHeight
            let header = isFirstPage ? headerHeight : continuationHeight
            remainingHeight -= header

            var pageQuestions: [Question] = []
            while !remainingQuestions.isEmpty {
                let nextQuestion = remainingQuestions.first!
                let blockHeight = blockHeights[nextQuestion.id] ?? 0
                let requiredHeight = blockHeight + (pageQuestions.isEmpty ? 0 : questionSpacing)

                if requiredHeight <= remainingHeight || pageQuestions.isEmpty {
                    pageQuestions.append(nextQuestion)
                    remainingHeight -= requiredHeight
                    remainingQuestions.removeFirst()
                } else {
                    break
                }
            }

            pageQuestionSets.append(pageQuestions)
            isFirstPage = false
        }

        if pageQuestionSets.isEmpty {
            pageQuestionSets = [[]]
        }

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            for (index, questionsOnPage) in pageQuestionSets.enumerated() {
                ctx.beginPage()
                let pageView = pageContent(includeHeader: index == 0, questions: questionsOnPage)
                let controller = UIHostingController(rootView: pageView)
                controller.view.bounds = pageRect
                controller.view.backgroundColor = .white
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
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

    private func measureHeight<V: View>(of view: V, width: CGFloat) -> CGFloat {
        let controller = UIHostingController(rootView: view.frame(width: width, alignment: .leading))
        controller.view.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: 10))
        controller.view.backgroundColor = .clear
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        let size = controller.view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return size.height
    }

    private func pageContent(includeHeader: Bool, questions: [Question]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if includeHeader {
                headerSection
            } else {
                continuationHeading
            }
            VStack(alignment: .leading, spacing: questionSpacing) {
                ForEach(questions) { question in
                    questionBlock(for: question)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(width: 612, height: 792, alignment: .topLeading)
        .background(Color.white)
    }
}

// ShareSheet is defined in Views/Results/ShareSheet.swift
