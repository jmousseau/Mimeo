//
//  ResultsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class ResultsViewController: UIViewController {

    private lazy var resultsTextView: ResultsTextView = {
        let resultsView = ResultsTextView()
        resultsView.translatesAutoresizingMaskIntoConstraints = false
        return resultsView
    }()

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            switch recognitionState {
            case .notStarted:
                view.alpha = 0

            case .inProgress:
                UIView.animate(withDuration: 0.15) {
                    self.view.alpha = 1
                }

            case .complete(let recognizedText):
                resultsTextView.text = recognizedText
            }
        }
    }

    public init() {
        super.init(nibName: nil, bundle: nil)

        addResultsView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addResultsView() {
        view.addSubview(resultsTextView)

        NSLayoutConstraint.activate([
            resultsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsTextView.topAnchor.constraint(equalTo: view.topAnchor),
            resultsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

}
