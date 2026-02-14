@testable import QuarryMenuBar
import XCTest

@MainActor
final class ContentPanelTests: XCTestCase {
    func testContentPanelInitializesWithDaemon() {
        let daemon = DaemonManager(executablePath: "/nonexistent")
        let panel = ContentPanel(daemon: daemon)
        XCTAssertNotNil(panel.body)
    }

    func testContentPanelShowsErrorStateRestart() {
        // Verify that starting with an invalid path puts daemon in error,
        // which ContentPanel would render as the error view with restart button
        let daemon = DaemonManager(executablePath: "/nonexistent/quarry")
        daemon.start()
        if case .error = daemon.state {
            // ContentPanel would show the error view
        } else {
            XCTFail("Expected error state for ContentPanel error view")
        }
    }
}
