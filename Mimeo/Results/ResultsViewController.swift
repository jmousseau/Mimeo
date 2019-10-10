//
//  ResultsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class ResultsViewController: UIViewController {

    private var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView()
        blurView.effect = UIBlurEffect(style: .systemMaterial)
        return blurView
    }()

    private var activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var resultsTextView = ResultsTextView()

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            switch recognitionState {
            case .notStarted:
                view.alpha = 0
                activityIndicator.alpha = 0
                activityIndicator.stopAnimating()

            case .inProgress:
                UIView.animate(withDuration: 0.15) {
                    self.view.alpha = 1
                }

                activityIndicator.alpha = 1
                activityIndicator.startAnimating()

            case .complete:
                UIView.animate(withDuration: 0.25, animations: {
                    self.activityIndicator.alpha = 0
                }) { isFinished in
                    if (isFinished) {
                        self.activityIndicator.stopAnimating()
                    }
                }
            }

            resultsTextView.recognitionState = recognitionState
        }
    }

    public init() {
        super.init(nibName: nil, bundle: nil)

        addBlurView()
        addActivityIndicator()
        addResultsView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addBlurView() {
        view.addSubview(blurView)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            view.topAnchor.constraint(equalTo: blurView.topAnchor),
            view.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: blurView.bottomAnchor)
        ])
    }

    private func addActivityIndicator() {
        view.addSubview(activityIndicator)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor)
        ])
    }

    private func addResultsView() {
        view.addSubview(resultsTextView)

        resultsTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: resultsTextView.leadingAnchor),
            view.topAnchor.constraint(equalTo: resultsTextView.topAnchor),
            view.trailingAnchor.constraint(equalTo: resultsTextView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: resultsTextView.bottomAnchor)
        ])
    }

}
