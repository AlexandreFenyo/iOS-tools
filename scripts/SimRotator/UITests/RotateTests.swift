//
//  RotateTests.swift — pivote le simulateur sur lequel le test s'exécute
//
//  Orientation voulue passée par xcodebuild, qui transmet au test les variables
//  préfixées TEST_RUNNER_ sans ce préfixe :
//    TEST_RUNNER_SIM_ORIENTATION=landscape xcodebuild test-without-building …
//  Valeurs : portrait (défaut) ou landscape.
//
import XCTest

final class RotateTests: XCTestCase {
    func testRotate() throws {
        let wanted = ProcessInfo.processInfo.environment["SIM_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = wanted == "landscape" ? .landscapeLeft : .portrait
        // Laisse à l'interface le temps de terminer l'animation de rotation
        sleep(2)
        XCTAssertEqual(XCUIDevice.shared.orientation, wanted == "landscape" ? .landscapeLeft : .portrait)
    }
}
