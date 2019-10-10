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

    private var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView()
        blurView.effect = UIBlurEffect(style: .systemMaterial)
        return blurView
    }()

    private var activityIndicator = UIActivityIndicatorView(style: .large)

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
                activityIndicator.alpha = 0
                activityIndicator.stopAnimating()
                text = nil  

            case .inProgress:
                activityIndicator.alpha = 1
                activityIndicator.startAnimating()

            case .complete(let recognizedTextObservations):
                text = recognizedTextObservations.clustered().map({ cluster -> String in
                    cluster.observations.sortedLeftToRightTopToBottom().reduce("", { text, observation -> String in
                        return "\(text) \(observation.topCandidate!.string)"
                    })
                }).reduce("", { existingPargraphs, paragraph in
                    existingPargraphs + "\n\n" + paragraph
                })
            }
        }
    }

    private var text: String? {
        didSet {
            label.text = text

            if (label.text != nil) {
                UIView.animate(withDuration: 0.25, animations: {
                    self.activityIndicator.alpha = 0
                    self.label.alpha = 1
                }) { isFinished in
                    if (isFinished) {
                        self.activityIndicator.stopAnimating()
                    }
                }
            } else {
                label.alpha = 0
            }
        }
    }

    public init() {
        super.init(frame: .zero)

        addBlurView()
        addActivityIndicator()
        addLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addBlurView() {
        addSubview(blurView)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            topAnchor.constraint(equalTo: blurView.topAnchor),
            trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            bottomAnchor.constraint(equalTo: blurView.bottomAnchor)
        ])
    }

    private func addActivityIndicator() {
        addSubview(activityIndicator)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor),
            centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor)
        ])
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
