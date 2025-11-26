
import XCTest

final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Capture Home Screen
        takeScreenshot(named: "01_HomeScreen")

        // 2. Start Exam
        let startButton = app.buttons["Start Exam"]
        if startButton.exists {
            startButton.tap()
        }

        // 3. Capture First Question Screen
        // Wait for the question text to appear to ensure navigation is complete
        let questionText = app.staticTexts.element(matching: .any, identifier: "Question 1 of")
        if questionText.waitForExistence(timeout: 5) {
             takeScreenshot(named: "02_QuestionScreen")
        } else {
            // Fallback if specific text isn't found, just take a screenshot after a delay
            Thread.sleep(forTimeInterval: 2)
            takeScreenshot(named: "02_QuestionScreen_Fallback")
        }
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
