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

struct ClockDrawingView: View {
    let questionId: Int
    @Binding var answers: [Int: Answer]
    var onPauseTimer: (() -> Void)? = nil
    var onResumeTimer: (() -> Void)? = nil
    var onSubmit: (() -> Void)? = nil
    @State private var paths: [DrawingPath] = []
    @State private var currentPath = DrawingPath(color: .primary, lineWidth: 3.0)
    @State private var showSelfAssessment = false
    @State private var hasCorrectNumbers: Bool? = nil
    @State private var hasCorrectTime: Bool? = nil

    var body: some View {
        VStack(spacing: 20) {
            if !showSelfAssessment {
                // Drawing Phase
                VStack {
                    Text("Draw a clock with all numbers and set the time to 10:50")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    ZStack {
                        Circle().stroke(Color.gray, lineWidth: 2)
                            .frame(width: 300, height: 300)
                        Canvas { context, _ in
                            for path in paths {
                                var path2D = Path(); path2D.addLines(path.points)
                                context.stroke(path2D, with: .color(path.color), lineWidth: path.lineWidth)
                            }
                        }
                        .frame(width: 300, height: 300)
                        .contentShape(Circle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    currentPath.points.append(location)
                                    if paths.last?.id == currentPath.id { paths[paths.count - 1] = currentPath }
                                    else { paths.append(currentPath) }
                                }
                                .onEnded { _ in
                                    currentPath = DrawingPath(color: .primary, lineWidth: 3.0)
                                }
                        )
                    }
                    .frame(width: 300, height: 300)
                    .padding()

                    HStack(spacing: 15) {
                        Button(action: { 
                            if !paths.isEmpty {
                                paths.removeLast()
                            }
                        }) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .disabled(paths.isEmpty)
                        
                        Button(action: { 
                            paths.removeAll()
                        }) {
                            Label("Reset", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(paths.isEmpty)
                        
                        Button(action: { 
                            showSelfAssessment = true
                        }) {
                            Label("Done Drawing", systemImage: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(paths.isEmpty)
                    }
                }
            } else {
                // Self-Assessment Phase
                VStack(spacing: 20) {
                    Text("Self-Assessment")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Compare your drawing with the reference:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        // User's drawing
                        VStack {
                            Text("Your Drawing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                Circle().stroke(Color.gray, lineWidth: 2)
                                Canvas { context, size in
                                    // Scale the drawing to fit the smaller display
                                    let scaleX = size.width / 300
                                    let scaleY = size.height / 300
                                    
                                    for path in paths {
                                        var scaledPoints: [CGPoint] = []
                                        for point in path.points {
                                            scaledPoints.append(CGPoint(x: point.x * scaleX, y: point.y * scaleY))
                                        }
                                        var path2D = Path()
                                        path2D.addLines(scaledPoints)
                                        context.stroke(path2D, with: .color(path.color), lineWidth: path.lineWidth * scaleX)
                                    }
                                }
                            }
                            .frame(width: 150, height: 150)
                        }
                        
                        // Reference image
                        VStack {
                            Text("Reference")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ReferenceClockView()
                                .frame(width: 150, height: 150)
                        }
                    }
                    
                    VStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Does your clock have all 12 numbers (1-12) around the circle?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 15) {
                                Button("Yes") { hasCorrectNumbers = true }
                                    .buttonStyle(.bordered)
                                    .background(hasCorrectNumbers == true ? Color.green.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                                
                                Button("No") { hasCorrectNumbers = false }
                                    .buttonStyle(.bordered)
                                    .background(hasCorrectNumbers == false ? Color.red.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2. Does your clock show 10:50 (10 minutes to 11)?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 15) {
                                Button("Yes") { hasCorrectTime = true }
                                    .buttonStyle(.bordered)
                                    .background(hasCorrectTime == true ? Color.green.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                                
                                Button("No") { hasCorrectTime = false }
                                    .buttonStyle(.bordered)
                                    .background(hasCorrectTime == false ? Color.red.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        let clockAnswer = ClockDrawingAnswer(
                            drawing: paths,
                            hasCorrectNumbers: hasCorrectNumbers ?? false,
                            hasCorrectTime: hasCorrectTime ?? false
                        )
                        answers[questionId] = .clockDrawing(clockAnswer)
                        onResumeTimer?()
                        
                        // Advance to next question like the Next button
                        onSubmit?()
                    }) {
                        Text("Submit Assessment")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(hasCorrectNumbers == nil || hasCorrectTime == nil)
                }
            }
        }
        .onAppear { 
            onPauseTimer?()
            if case let .clockDrawing(saved)? = answers[questionId] {
                paths = saved.drawing
                hasCorrectNumbers = saved.hasCorrectNumbers
                hasCorrectTime = saved.hasCorrectTime
                showSelfAssessment = true
            }
        }
        .onDisappear {
            onResumeTimer?()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Clock drawing with self-assessment")
    }
}

struct ReferenceClockView: View {
    var body: some View {
        ZStack {
            clockFace
            clockNumbers
            clockHands
            centerDot
        }
        .frame(width: 150, height: 150)
    }
    
    private var clockFace: some View {
        ZStack {
            Circle()
                .fill(Color.white)
            Circle()
                .stroke(Color.black, lineWidth: 3)
        }
    }
    
    private var clockNumbers: some View {
        ForEach(1...12, id: \.self) { hour in
            let angle = Double(hour - 3) * 30 * .pi / 180
            let radius: CGFloat = 60
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            
            Text("\(hour)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .position(x: 75 + x, y: 75 + y)
        }
    }
    
    private var clockHands: some View {
        ZStack {
            hourHand
            minuteHand
        }
    }
    
    private var hourHand: some View {
        Path { path in
            // Hour hand pointing to 11 (shorter hand)
            path.move(to: CGPoint(x: 75, y: 75))
            path.addLine(to: CGPoint(x: 60, y: 45))
        }
        .stroke(Color.black, lineWidth: 5)
    }
    
    private var minuteHand: some View {
        Path { path in
            // Minute hand pointing to 10 (longer hand for 50 minutes)
            path.move(to: CGPoint(x: 75, y: 75))
            path.addLine(to: CGPoint(x: 45, y: 45))
        }
        .stroke(Color.black, lineWidth: 4)
    }
    
    private var centerDot: some View {
        Circle()
            .fill(Color.black)
            .frame(width: 8, height: 8)
            .position(x: 75, y: 75)
    }
}

