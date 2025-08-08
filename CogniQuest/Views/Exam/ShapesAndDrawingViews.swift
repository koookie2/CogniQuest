import SwiftUI

struct DrawingView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    @State private var paths: [DrawingPath] = []
    @State private var currentPath = DrawingPath(color: .primary, lineWidth: 3.0)

    var body: some View {
        VStack {
            ZStack {
                Circle().stroke(Color.gray, lineWidth: 2)
                Canvas { context, _ in
                    for path in paths {
                        var path2D = Path(); path2D.addLines(path.points)
                        context.stroke(path2D, with: .color(path.color), lineWidth: path.lineWidth)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentPath.points.append(value.location)
                            if paths.last?.id == currentPath.id { paths[paths.count - 1] = currentPath }
                            else { paths.append(currentPath) }
                        }
                        .onEnded { _ in
                            answers[questionId] = .drawing(paths)
                            currentPath = DrawingPath(color: .primary, lineWidth: 3.0)
                        }
                )
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()

            Button(action: { paths.removeAll(); answers[questionId] = .drawing(paths) }) {
                Label("Clear Drawing", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .onAppear { if case let .drawing(saved)? = answers[questionId] { paths = saved } }
        .accessibilityLabel("Clock drawing canvas")
        .accessibilityHint("Draw inside the circle to place the clock and time")
    }
}

struct ShapeIdentificationView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    @State private var tappedShape: String? = nil
    @State private var largestShape: String? = nil

    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 15) {
                ShapeContainer(shape: Rectangle(), name: "Square", tappedShape: $tappedShape)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 100)
                ShapeContainer(shape: Triangle(), name: "Triangle", tappedShape: $tappedShape)
                    .frame(width: 70, height: 70)
                ShapeContainer(shape: Rectangle(), name: "Rectangle", tappedShape: $tappedShape)
                    .frame(width: 40, height: 90)
            }
            .frame(height: 110)

            Divider().padding()

            Text("Which of the figures is largest?").font(.headline)
            HStack(spacing: 15) {
                Button("Square") { largestShape = "Square" }
                    .buttonStyle(.bordered)
                    .background(largestShape == "Square" ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                Button("Triangle") { largestShape = "Triangle" }
                    .buttonStyle(.bordered)
                    .background(largestShape == "Triangle" ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                Button("Rectangle") { largestShape = "Rectangle" }
                    .buttonStyle(.bordered)
                    .background(largestShape == "Rectangle" ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
        }
        .onChange(of: tappedShape) { updateAnswers() }
        .onChange(of: largestShape) { updateAnswers() }
        .onAppear {
            if case let .shape(saved)? = answers[questionId] {
                tappedShape = saved.tappedShape
                largestShape = saved.largestShape
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shape identification")
        .accessibilityHint("Tap a shape to place an X, and choose the largest shape")
    }

    private func updateAnswers() {
        answers[questionId] = .shape(ShapeAnswer(tappedShape: tappedShape, largestShape: largestShape))
    }
}

struct ShapeContainer<S: Shape>: View {
    let shape: S
    let name: String
    @Binding var tappedShape: String?

    var body: some View {
        ZStack {
            shape.stroke(Color.primary, lineWidth: 2)
            if tappedShape == name { Text("X").font(.largeTitle).foregroundColor(.red) }
        }
        .contentShape(shape)
        .onTapGesture { tappedShape = name }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(name) shape")
        .accessibilityHint("Tap to place an X on the \(name)")
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}


