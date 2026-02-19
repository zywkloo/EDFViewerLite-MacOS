import Foundation

enum EDFError: LocalizedError {
    case fileTooShort
    case invalidHeader(String)
    case invalidChannel(Int)
    case readError(String)

    var errorDescription: String? {
        switch self {
        case .fileTooShort: return "File is too short to contain a valid EDF/BDF header"
        case .invalidHeader(let msg): return "Invalid EDF/BDF header: \(msg)"
        case .invalidChannel(let id): return "Invalid channel ID: \(id)"
        case .readError(let msg): return "Read error: \(msg)"
        }
    }
}

final class RealEDFReader: EDFReading {
    let channels: [ChannelInfo]
    let fileDurationSeconds: Double

    private let fileData: Data
    private let headerSize: Int
    private let recordSize: Int // bytes per data record
    private let numDataRecords: Int
    private let dataRecordDuration: Double
    private let isBDF: Bool
    private let signalParams: [SignalParam]

    struct SignalParam {
        let samplesPerRecord: Int
        let bitvalue: Double
        let offset: Double
        let bufOffset: Int // byte offset within a data record
        let bytesPerSample: Int
    }

    init(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        guard data.count >= 256 else { throw EDFError.fileTooShort }

        // Detect EDF vs BDF
        let firstByte = data[0]
        isBDF = (firstByte == 0xFF)

        func ascii(_ range: Range<Int>) -> String {
            String(data: data[range], encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? ""
        }

        func asciiInt(_ range: Range<Int>) -> Int? {
            Int(ascii(range))
        }

        func asciiDouble(_ range: Range<Int>) -> Double? {
            Double(ascii(range))
        }

        // Parse fixed header fields
        guard let headerBytes = asciiInt(184..<192) else {
            throw EDFError.invalidHeader("cannot parse header byte count")
        }
        guard let numRecords = asciiInt(236..<244), numRecords >= 0 else {
            throw EDFError.invalidHeader("cannot parse number of data records")
        }
        guard let recordDuration = asciiDouble(244..<252), recordDuration > 0 else {
            throw EDFError.invalidHeader("cannot parse data record duration")
        }
        guard let ns = asciiInt(252..<256), ns > 0 else {
            throw EDFError.invalidHeader("cannot parse number of signals")
        }

        headerSize = headerBytes
        numDataRecords = numRecords
        dataRecordDuration = recordDuration
        fileDurationSeconds = Double(numRecords) * recordDuration

        guard data.count >= headerSize else {
            throw EDFError.fileTooShort
        }

        // Parse signal headers (interleaved layout, each field ns times)
        let base = 256
        let bytesPerSample = isBDF ? 3 : 2

        // Field offsets within signal header block (cumulative per-field sizes)
        // label: 16, transducer: 80, physDim: 8, physMin: 8, physMax: 8, digMin: 8, digMax: 8, prefilter: 80, samplesPerRecord: 8
        var labels = [String]()
        var physDims = [String]()
        var physMins = [Double]()
        var physMaxs = [Double]()
        var digMins = [Int]()
        var digMaxs = [Int]()
        var samplesPerRecords = [Int]()

        for i in 0..<ns {
            labels.append(ascii(base + i*16 ..< base + (i+1)*16))
        }
        let transducerOffset = base + ns * 16
        let physDimOffset = transducerOffset + ns * 80
        for i in 0..<ns {
            physDims.append(ascii(physDimOffset + i*8 ..< physDimOffset + (i+1)*8))
        }
        let physMinOffset = physDimOffset + ns * 8
        for i in 0..<ns {
            guard let v = asciiDouble(physMinOffset + i*8 ..< physMinOffset + (i+1)*8) else {
                throw EDFError.invalidHeader("cannot parse physical minimum for signal \(i)")
            }
            physMins.append(v)
        }
        let physMaxOffset = physMinOffset + ns * 8
        for i in 0..<ns {
            guard let v = asciiDouble(physMaxOffset + i*8 ..< physMaxOffset + (i+1)*8) else {
                throw EDFError.invalidHeader("cannot parse physical maximum for signal \(i)")
            }
            physMaxs.append(v)
        }
        let digMinOffset = physMaxOffset + ns * 8
        for i in 0..<ns {
            guard let v = asciiInt(digMinOffset + i*8 ..< digMinOffset + (i+1)*8) else {
                throw EDFError.invalidHeader("cannot parse digital minimum for signal \(i)")
            }
            digMins.append(v)
        }
        let digMaxOffset = digMinOffset + ns * 8
        for i in 0..<ns {
            guard let v = asciiInt(digMaxOffset + i*8 ..< digMaxOffset + (i+1)*8) else {
                throw EDFError.invalidHeader("cannot parse digital maximum for signal \(i)")
            }
            digMaxs.append(v)
        }
        // prefilter: ns * 80 bytes (skip)
        let prefilterOffset = digMaxOffset + ns * 8
        let samplesOffset = prefilterOffset + ns * 80
        for i in 0..<ns {
            guard let v = asciiInt(samplesOffset + i*8 ..< samplesOffset + (i+1)*8) else {
                throw EDFError.invalidHeader("cannot parse samples per record for signal \(i)")
            }
            samplesPerRecords.append(v)
        }

        // Build channel info and signal params
        var chans = [ChannelInfo]()
        var params = [SignalParam]()
        var cumBufOffset = 0

        for i in 0..<ns {
            let sampleRate = Double(samplesPerRecords[i]) / recordDuration
            chans.append(ChannelInfo(id: i, label: labels[i], sampleRateHz: sampleRate, unit: physDims[i]))

            let digRange = Double(digMaxs[i] - digMins[i])
            let bitvalue: Double
            let offset: Double
            if digRange != 0 {
                bitvalue = (physMaxs[i] - physMins[i]) / digRange
                offset = physMaxs[i] / bitvalue - Double(digMaxs[i])
            } else {
                bitvalue = 1
                offset = 0
            }

            params.append(SignalParam(
                samplesPerRecord: samplesPerRecords[i],
                bitvalue: bitvalue,
                offset: offset,
                bufOffset: cumBufOffset,
                bytesPerSample: bytesPerSample
            ))
            cumBufOffset += samplesPerRecords[i] * bytesPerSample
        }

        channels = chans
        signalParams = params
        recordSize = cumBufOffset
        fileData = data
    }

    func readWindow(channelID: Int, startSeconds: Double, durationSeconds: Double) async throws -> WaveformWindow {
        guard let chIdx = channels.firstIndex(where: { $0.id == channelID }) else {
            throw EDFError.invalidChannel(channelID)
        }

        let param = signalParams[chIdx]
        let sampleRate = channels[chIdx].sampleRateHz

        // Clamp to file bounds
        let clampedStart = max(0, min(startSeconds, fileDurationSeconds))
        let clampedEnd = min(clampedStart + durationSeconds, fileDurationSeconds)
        let clampedDuration = clampedEnd - clampedStart

        // Which data records overlap?
        let firstRecord = Int(clampedStart / dataRecordDuration)
        let lastRecord = min(numDataRecords - 1, Int((clampedEnd - 1e-12) / dataRecordDuration))

        guard firstRecord <= lastRecord, firstRecord < numDataRecords else {
            return WaveformWindow(startSeconds: clampedStart, durationSeconds: clampedDuration, samples: [])
        }

        // Calculate sample range within the window
        let totalSamplesNeeded = Int(clampedDuration * sampleRate)
        var samples = [Float]()
        samples.reserveCapacity(totalSamplesNeeded)

        for rec in firstRecord...lastRecord {
            let recordStartSec = Double(rec) * dataRecordDuration

            // First sample index within this record
            let windowStartInRecord = max(0, clampedStart - recordStartSec)
            let firstSample = Int(windowStartInRecord * sampleRate)

            // Last sample index within this record
            let windowEndInRecord = min(dataRecordDuration, clampedEnd - recordStartSec)
            let lastSample = min(param.samplesPerRecord, Int(ceil(windowEndInRecord * sampleRate)))

            guard firstSample < lastSample else { continue }

            // Read from in-memory data
            let recordDataOffset = headerSize + rec * recordSize + param.bufOffset
            let sampleDataOffset = recordDataOffset + firstSample * param.bytesPerSample
            let bytesToRead = (lastSample - firstSample) * param.bytesPerSample
            let endOffset = sampleDataOffset + bytesToRead

            guard endOffset <= fileData.count else {
                throw EDFError.readError("unexpected end of file in data record \(rec)")
            }

            let rawData = fileData[sampleDataOffset..<endOffset]

            // Decode samples
            if isBDF {
                for s in 0..<(lastSample - firstSample) {
                    let base = rawData.startIndex + s * 3
                    let b0 = Int(rawData[base])
                    let b1 = Int(rawData[base + 1])
                    let b2 = Int(Int8(bitPattern: rawData[base + 2])) // sign extension
                    let digital = b0 | (b1 << 8) | (b2 << 16)
                    let physical = param.bitvalue * (param.offset + Double(digital))
                    samples.append(Float(physical))
                }
            } else {
                let sampleCount = lastSample - firstSample
                rawData.withUnsafeBytes { ptr in
                    for s in 0..<sampleCount {
                        let lo = ptr[s * 2]
                        let hi = ptr[s * 2 + 1]
                        let digital = Int(Int16(bitPattern: UInt16(lo) | (UInt16(hi) << 8)))
                        let physical = param.bitvalue * (param.offset + Double(digital))
                        samples.append(Float(physical))
                    }
                }
            }
        }

        return WaveformWindow(startSeconds: clampedStart, durationSeconds: clampedDuration, samples: samples)
    }
}
