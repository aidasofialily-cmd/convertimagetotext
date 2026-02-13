import Foundation
import Vision
import AppKit

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("Usage: mac-ocr <path-to-image>")
    exit(1)
}

let imagePath = arguments[1]
let imageUrl = URL(fileURLWithPath: imagePath)

guard let image = NSImage(contentsOf: imageUrl),
      let tiffData = image.tiffRepresentation,
      let cgImage = NSBitmapImageRep(data: tiffData)?.cgImage else {
    print("Error: Could not load image.")
    exit(1)
}

// 1. Create the Request
let request = VNRecognizeTextRequest { (request, error) in
    guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
    
    for observation in observations {
        if let topCandidate = observation.topCandidates(1).first {
            print(topCandidate.string)
        }
    }
}

// 2. Configure for accuracy
request.recognitionLevel = .accurate

// 3. Perform the Request
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([request])
