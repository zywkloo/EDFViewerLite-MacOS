import XCTest


/// Integration tests that will exercise the full read path once the real EDFReader is implemented.
/// For now, they verify the test fixture is accessible and validate the mock reader contract.
final class EDFReadIntegrationTests: XCTestCase {

    private func fixtureURL() -> URL {
        let bundle = Bundle(for: type(of: self))
        // Folder reference: Fixtures/test_1ch_1s.edf
        if let url = bundle.url(forResource: "test_1ch_1s", withExtension: "edf", subdirectory: "Fixtures") {
            return url
        }
        // Flat resource fallback
        return bundle.url(forResource: "test_1ch_1s", withExtension: "edf")!
    }

    func testFixtureFileIsReadable() throws {
        let url = fixtureURL()
        let data = try Data(contentsOf: url)
        // EDF header: version is "0" padded to 8 bytes
        let version = String(data: data[0..<8], encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(version, "0")
    }

    func testFixtureHeaderFieldsAreValid() throws {
        let url = fixtureURL()
        let data = try Data(contentsOf: url)

        // Number of signals at offset 252, 4 bytes
        let numSignals = String(data: data[252..<256], encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(numSignals, "1")

        // Duration of data record at offset 244, 8 bytes
        let duration = String(data: data[244..<252], encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(duration, "1.0")

        // Number of data records at offset 236, 8 bytes
        let numRecords = String(data: data[236..<244], encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(numRecords, "1")
    }

    func testFixtureSignalLabel() throws {
        let url = fixtureURL()
        let data = try Data(contentsOf: url)

        // Signal label starts at byte 256 (after 256-byte main header), 16 bytes
        let label = String(data: data[256..<272], encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(label, "EEG Fp1")
    }

    func testFixtureDataRecordSize() throws {
        let url = fixtureURL()
        let data = try Data(contentsOf: url)

        // Header = 256 + 1*256 = 512 bytes
        // Data = 256 samples × 2 bytes = 512 bytes
        // Total = 1024 bytes
        XCTAssertEqual(data.count, 1024)
    }

    func testFixtureFirstAndLastSample() throws {
        let url = fixtureURL()
        let data = try Data(contentsOf: url)

        let headerSize = 512
        // First sample: digital min = -32768
        let first = data.subdata(in: headerSize..<(headerSize + 2))
            .withUnsafeBytes { $0.load(as: Int16.self) }
        XCTAssertEqual(first, -32768)

        // Last sample: digital max = 32767
        let lastOffset = headerSize + (255 * 2)
        let last = data.subdata(in: lastOffset..<(lastOffset + 2))
            .withUnsafeBytes { $0.load(as: Int16.self) }
        XCTAssertEqual(last, 32767)
    }

    // MARK: - End-to-end: RealEDFReader → readWindow → downsampleMinMax

    func testEndToEndReadAndDownsample() async throws {
        let reader = try RealEDFReader(fileURL: fixtureURL())
        let window = try await reader.readWindow(channelID: 0, startSeconds: 0, durationSeconds: 1.0)

        XCTAssertFalse(window.samples.isEmpty, "readWindow should return samples")

        let downsampled = SignalProcessing.downsampleMinMax(window.samples, bucketCount: 100)
        XCTAssertFalse(downsampled.mins.isEmpty, "downsample should produce min values")
        XCTAssertFalse(downsampled.maxs.isEmpty, "downsample should produce max values")
        XCTAssertEqual(downsampled.mins.count, downsampled.maxs.count)

        // The ramp spans -100 to +100, so overall min should be near -100 and max near +100
        let overallMin = downsampled.mins.min()!
        let overallMax = downsampled.maxs.max()!
        XCTAssertEqual(overallMin, -100.0, accuracy: 1.0)
        XCTAssertEqual(overallMax, 100.0, accuracy: 1.0)
    }
}
