import Iris
import Files
import FontClassifier
import Foundation
import SwiftCLI
import Vision

#if os(macOS)

import Cocoa

extension Image {

    public func pngData() -> Data? {
        var imageRect = CGRect(origin: .zero, size: size)
        guard let cgImage = cgImage(
            forProposedRect: &imageRect,
            context: nil,
            hints: nil
        ) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = size
        return bitmapRep.representation(using: .png, properties: [:])
    }

}

#endif

final class GenerateCommand: Command {

    let name = "generate"

    let shortDescription = "Generate testing and training character images"

    let serifDirectory = Key<String>(
        "--serif-directory",
        description: "The directory containing images with serif text."
    )

    let sansSerifDirectory = Key<String>(
        "--sans-serif-directory",
        description: "The directory containing images with sans-serif text."
    )

    let outputDirectory = Key<String>(
        "--output-directory",
        description: "The output directory for the test and training images."
    )

    let trainingPercentage = Key<Double>(
        "--training-percentage",
        description: "The percentage of images to be used for training. Defaults to 0.8."
    )

    func execute() throws {
        guard let serifDirectoryPath = serifDirectory.value else {
            stderr <<< "Missing serif directory"
            return
        }

        guard let sansSerifDirectoryPath = sansSerifDirectory.value else {
            stderr <<< "Missing sans-serif directory"
            return
        }

        guard let outputDirectoryPath = outputDirectory.value else {
            stderr <<< "Missing output directory"
            return
        }

        let trainingPercentage = self.trainingPercentage.value ?? 0.8

        let serifDirectory = try Folder(path: serifDirectoryPath)
        let sansSerifDirectory = try Folder(path: sansSerifDirectoryPath)
        let outputDirectory = try Folder(path: outputDirectoryPath)

        try writeCharactersImages(
            for: "serif",
            source: serifDirectory,
            destination: outputDirectory,
            trainingPercentage: trainingPercentage
        )

        try writeCharactersImages(
            for: "sans-serif",
            source: sansSerifDirectory,
            destination: outputDirectory,
            trainingPercentage: trainingPercentage
        )
    }

    private func writeCharactersImages(
        for category: String,
        source: Folder,
        destination: Folder,
        trainingPercentage: Double = 0.8
    ) throws {
        let dispatchGroup = DispatchGroup()

        let trainingSubdirectoryPath = "training/\(category)"
        let testingSubdirectoryPath = "testing/\(category)"

        try destination.createSubfolder(at: trainingSubdirectoryPath)
        try destination.createSubfolder(at: testingSubdirectoryPath)

        let trainingSubdirectory = try destination.subfolder(at: trainingSubdirectoryPath)
        let testingSubdirectory = try destination.subfolder(at: testingSubdirectoryPath)

        stdout <<< "Processing \(source.files.count()) \(category) images...\n"

        source.files.enumerated().forEach { (fileIndex, file) in
            let linePrefix = "  - \(file.path(relativeTo: .home)):"
            guard let image = Image(contentsOf: file.url) else {
                stdout <<< "\(linePrefix) Unable to initialize image"
                return
            }

            dispatchGroup.enter()

            self.textObservations(in: image) { observations in
                FontClassifier.characterImages(
                    in: image,
                    with: observations,
                    characterImageSize: CGSize(width: 300, height: 300)
                ) { images in
                    defer {
                        dispatchGroup.leave()
                    }

                    self.stdout <<< "\(linePrefix) \(images.count) characters"

                    images.enumerated().forEach { (imageIndex, image) in
                        let isForTraining =  Double.random(in: 0...1) <= trainingPercentage
                        let directory = isForTraining ? trainingSubdirectory : testingSubdirectory
                        let _ = try? directory.createFile(
                            at: "image-\(fileIndex)-character-\(imageIndex)",
                            contents: image.pngData()
                        )
                    }
                }
            }
        }

        stdout <<< "\nDone."

        dispatchGroup.wait()
    }

    private func textObservations(
        in image: Image,
        completion: @escaping ([VNTextObservation]
    ) -> Void) {
        guard let cgImage = image.cgImage else {
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        let request = VNDetectTextRectanglesRequest { request, error in
            guard let results = request.results as? [VNTextObservation] else { return }
            completion(results)
        }

        request.reportCharacterBoxes = true

        try? handler.perform([request])
    }

}
