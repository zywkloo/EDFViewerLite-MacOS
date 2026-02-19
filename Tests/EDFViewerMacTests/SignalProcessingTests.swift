import XCTest


final class SignalProcessingTests: XCTestCase {

    func testEmptyInput() {
        let result = SignalProcessing.downsampleMinMax([], bucketCount: 10)
        XCTAssertTrue(result.mins.isEmpty)
        XCTAssertTrue(result.maxs.isEmpty)
    }

    func testZeroBuckets() {
        let result = SignalProcessing.downsampleMinMax([1, 2, 3], bucketCount: 0)
        XCTAssertTrue(result.mins.isEmpty)
        XCTAssertTrue(result.maxs.isEmpty)
    }

    func testSingleSample() {
        let result = SignalProcessing.downsampleMinMax([42.0], bucketCount: 5)
        XCTAssertEqual(result.mins.count, 1)
        XCTAssertEqual(result.mins[0], 42.0)
        XCTAssertEqual(result.maxs[0], 42.0)
    }

    func testBucketCountGreaterThanSamples() {
        let samples: [Float] = [1, 2, 3]
        let result = SignalProcessing.downsampleMinMax(samples, bucketCount: 100)
        // step = max(1, 3/100) = 1, so one bucket per sample
        XCTAssertEqual(result.mins.count, 3)
        XCTAssertEqual(result.mins, [1, 2, 3])
        XCTAssertEqual(result.maxs, [1, 2, 3])
    }

    func testKnownMinMax() {
        // 8 samples into 2 buckets → step of 4
        let samples: [Float] = [5, 1, 8, 3, 10, 2, 7, 4]
        let result = SignalProcessing.downsampleMinMax(samples, bucketCount: 2)
        XCTAssertEqual(result.mins.count, 2)
        // Bucket 0: [5,1,8,3] → min=1, max=8
        XCTAssertEqual(result.mins[0], 1.0)
        XCTAssertEqual(result.maxs[0], 8.0)
        // Bucket 1: [10,2,7,4] → min=2, max=10
        XCTAssertEqual(result.mins[1], 2.0)
        XCTAssertEqual(result.maxs[1], 10.0)
    }

    func testAllSameValues() {
        let samples: [Float] = [7, 7, 7, 7]
        let result = SignalProcessing.downsampleMinMax(samples, bucketCount: 2)
        for i in 0..<result.mins.count {
            XCTAssertEqual(result.mins[i], 7.0)
            XCTAssertEqual(result.maxs[i], 7.0)
        }
    }
}
