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

    // MARK: - RealEDFReader tests

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

    func testRealReaderParsesHeader() throws {
        let reader = try RealEDFReader(fileURL: fixtureURL())
        XCTAssertEqual(reader.channels.count, 1)
        XCTAssertEqual(reader.channels[0].label, "EEG Fp1")
        XCTAssertEqual(reader.channels[0].sampleRateHz, 256)
        XCTAssertEqual(reader.channels[0].unit, "uV")
    }

    func testRealReaderFileDuration() throws {
        let reader = try RealEDFReader(fileURL: fixtureURL())
        XCTAssertEqual(reader.fileDurationSeconds, 1.0, accuracy: 0.001)
    }

    func testRealReaderReadWindow() async throws {
        let reader = try RealEDFReader(fileURL: fixtureURL())
        let window = try await reader.readWindow(channelID: 0, startSeconds: 0, durationSeconds: 1.0)

        // 256 Hz x 1 second = 256 samples
        XCTAssertEqual(window.samples.count, 256)

        // Ramp from digital -32768 to 32767 maps to physical -100 to +100
        // First sample: physMin = -100
        XCTAssertEqual(window.samples.first!, -100.0, accuracy: 0.01)
        // Last sample: physMax ≈ +100 (32767/32768 * 100)
        XCTAssertEqual(window.samples.last!, 100.0, accuracy: 0.01)
    }
}
