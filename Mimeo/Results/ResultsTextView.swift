//
//  ResultsTextView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit
import Vision

public final class ResultsTextView: UIView {

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.alpha = 0
        return label
    }()

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            switch recognitionState {
            case .notStarted:
                text = nil  

            case .inProgress:
                break

            case .complete(let recognizedTextObservations):
                text = recognizedTextObservations
                    .sortedLeftToRightTopToBottom()
                    .reduce("", { allText, observation -> String in
                        let string = observation.topCandidate!.string
                        return allText.isEmpty ? string : "\(allText) \(string)"
                    })
            }
        }
    }

    public private(set) var text: String? {
        didSet {
            label.text = text

            if (label.text != nil) {
                UIView.animate(withDuration: 0.25, animations: {
                    self.label.alpha = 1
                })
            } else {
                label.alpha = 0
            }
        }
    }

    public init() {
        super.init(frame: .zero)

        addLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addLabel() {
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            layoutMarginsGuide.topAnchor.constraint(equalTo: label.topAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])
    }

}
