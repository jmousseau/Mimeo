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

    private lazy var resultsTextView = ResultsTextView()

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            switch recognitionState {
            case .notStarted:
                view.alpha = 0

            case .inProgress:
                UIView.animate(withDuration: 0.15) {
                    self.view.alpha = 1
                }

            case .complete:
                break;
            }

            resultsTextView.recognitionState = recognitionState
        }
    }

    public init() {
        super.init(nibName: nil, bundle: nil)

        addBlurView()
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
