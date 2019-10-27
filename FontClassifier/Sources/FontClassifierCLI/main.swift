import Iris
import Foundation
import SwiftCLI

let FontClassifierCLI = CLI(
    name: "font-classifier",
    version: "0.0.0",
    description: "FontClassifier's command line interface",
    commands: [GenerateCommand()]
)

FontClassifierCLI.goAndExit()
