import XCTest


@MainActor
final class ViewerViewModelTests: XCTestCase {

    func testOpenFilePopulatesChannels() async {
        let vm = ViewerViewModel(makeReader: MockEDFReader.init)
        let url = URL(fileURLWithPath: "/tmp/fake.edf")

        vm.openFile(url: url)
        // Allow the internal Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.channels.count, 3)
        XCTAssertEqual(vm.selectedChannelID, 0)
        XCTAssertEqual(vm.openedFileURL, url)
        XCTAssertNil(vm.errorMessage)
    }

    func testOpenFileSetsFirstChannelSelected() async {
        let vm = ViewerViewModel(makeReader: MockEDFReader.init)
        vm.openFile(url: URL(fileURLWithPath: "/tmp/fake.edf"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.selectedChannelID, vm.channels.first?.id)
    }

    func testZoomClampsMinimum() async {
        let vm = ViewerViewModel(makeReader: MockEDFReader.init)
        vm.openFile(url: URL(fileURLWithPath: "/tmp/fake.edf"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Zoom in aggressively — should clamp at 0.25s
        vm.visibleDurationSeconds = 0.5
        await vm.zoom(by: 0.1, pixelWidth: 1400)
        XCTAssertGreaterThanOrEqual(vm.visibleDurationSeconds, 0.25)
    }

    func testZoomClampsMaximum() async {
        let vm = ViewerViewModel(makeReader: MockEDFReader.init)
        vm.openFile(url: URL(fileURLWithPath: "/tmp/fake.edf"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.visibleDurationSeconds = 50
        await vm.zoom(by: 10, pixelWidth: 1400)
        XCTAssertLessThanOrEqual(vm.visibleDurationSeconds, 60)
    }

    func testPanDoesNotGoBelowZero() async {
        let vm = ViewerViewModel(makeReader: MockEDFReader.init)
        vm.openFile(url: URL(fileURLWithPath: "/tmp/fake.edf"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.visibleStartSeconds = 1.0
        await vm.pan(by: -10.0, pixelWidth: 1400)
        XCTAssertGreaterThanOrEqual(vm.visibleStartSeconds, 0)
    }

    func testWaveformPopulatedAfterOpen() async {
        let vm = ViewerViewModel(makeReader: MockEDFReader.init)
        vm.openFile(url: URL(fileURLWithPath: "/tmp/fake.edf"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(vm.waveform.mins.isEmpty)
        XCTAssertEqual(vm.waveform.mins.count, vm.waveform.maxs.count)
    }
}
