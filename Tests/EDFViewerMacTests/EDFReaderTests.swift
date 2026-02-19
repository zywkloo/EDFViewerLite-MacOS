import XCTest


final class EDFReaderTests: XCTestCase {

    // MARK: - MockEDFReader baseline tests

    func testMockReaderChannelCount() {
        let reader = MockEDFReader(fileURL: URL(fileURLWithPath: "/tmp/fake.edf"))
        XCTAssertEqual(reader.channels.count, 3)
    }

    func testMockReaderFileDuration() {
        let reader = MockEDFReader(fileURL: URL(fileURLWithPath: "/tmp/fake.edf"))
        XCTAssertEqual(reader.fileDurationSeconds, 120)
    }

    func testMockReaderReadWindow() async throws {
        let reader = MockEDFReader(fileURL: URL(fileURLWithPath: "/tmp/fake.edf"))
        let window = try await reader.readWindow(channelID: 0, startSeconds: 0, durationSeconds: 1.0)
        // 256 Hz × 1 second = 256 samples
        XCTAssertEqual(window.samples.count, 256)
        XCTAssertEqual(window.startSeconds, 0)
        XCTAssertEqual(window.durationSeconds, 1.0)
    }

    // MARK: - Real EDFReader stubs (will be filled in when the real reader is implemented)
    // These tests use the fixture file at Tests/EDFViewerMacTests/Fixtures/test_1ch_1s.edf
    //
    // The fixture is a valid EDF file with:
    //   - 1 channel: "EEG Fp1", 256 Hz, unit "uV"
    //   - Physical range: -100 to 100
    //   - Digital range: -32768 to 32767
    //   - 1 data record, 1 second duration
    //   - Samples: ramp from digital min to digital max

    private func fixtureURL() -> URL {
        let bundle = Bundle(for: type(of: self))
        if let url = bundle.url(forResource: "test_1ch_1s", withExtension: "edf", subdirectory: "Fixtures") {
            return url
        }
        return bundle.url(forResource: "test_1ch_1s", withExtension: "edf")!
    }

    func testFixtureFileExists() {
        XCTAssertNoThrow(fixtureURL(), "Fixture EDF file must be bundled in the test target")
    }
}
