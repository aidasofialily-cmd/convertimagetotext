import Foundation
import Vision

class ScreenshotWatcher {
    private let folderURL: URL
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: Int32

    init(watching url: URL) {
        self.folderURL = url
        self.fileDescriptor = open(url.path, O_EVTONLY)
    }

    func start() {
        let queue = DispatchQueue(label: "com.engineer.ocr-watcher")
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor, 
            eventMask: .write, 
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.processNewFiles()
        }

        source?.resume()
        print("👀 Watching for new screenshots in: \(folderURL.path)")
    }

    private func processNewFiles() {
        // Find the most recent image that hasn't been processed
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.creationDateKey]) else { return }

        // Filter for images added in the last 5 seconds
        let newImages = files.filter { $0.pathExtension == "png" || $0.pathExtension == "jpg" }
                             .sorted { $0.path > $1.path }

        if let latestImage = newImages.first {
            print("📸 New screenshot detected: \(latestImage.lastPathComponent)")
            performOCR(on: latestImage)
        }
    }
}

func performOCR(on url: URL) {
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        
        // Save to a .txt file with the same name
        let txtURL = url.deletingPathExtension().appendingPathExtension("txt")
        try? recognizedText.write(to: txtURL, atomically: true, encoding: .utf8)
        
        print("✅ Saved OCR to: \(txtURL.lastPathComponent)")
    }
    
    let handler = VNImageRequestHandler(url: url, options: [:])
    try? handler.perform([request])
}
