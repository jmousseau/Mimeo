//
//  ResultsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public enum ResultsLayout: String, CaseIterable, PreferenceStorable {

    public static let preferenceKey = "resultsLayout"

    public static let defaultPreferenceValue = Self.plain.rawValue

    case plain = "plain"

    case clustered = "clustered"

}

public final class ResultsViewController: UIViewController {

    private let preferencesStore = PreferencesStore.default()

    private var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView()
        blurView.effect = UIBlurEffect(style: .systemMaterial)
        return blurView
    }()

    private lazy var resultsLayoutSegmentedControl: UISegmentedControl = {
        let resultsLayoutSegmentedControl = UISegmentedControl()

        for (index, layout) in ResultsLayout.allCases.enumerated() {
            switch layout {
            case .plain:
                resultsLayoutSegmentedControl.insertSegment(
                    withTitle: "Plain",
                    at: index,
                    animated: false
                )

            case .clustered:
                resultsLayoutSegmentedControl.insertSegment(
                    withTitle: "Grouped",
                    at: index,
                    animated: false
                )
            }

            if layout == preferencesStore.get(ResultsLayout.self) {
                resultsLayoutSegmentedControl.selectedSegmentIndex = index
            }
        }

        resultsLayoutSegmentedControl.addTarget(
            self,
            action: #selector(didChangeResultsLayout(_:)),
            for: .valueChanged
        )

        return resultsLayoutSegmentedControl
    }()

    private lazy var copyAllButton: UIButton = {
        let symbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let copyImage = UIImage(
            systemName: "doc.on.doc.fill",
            withConfiguration: symbolConfiguration
        )

        let copyAllButton = UIButton()
        copyAllButton.tintColor = .systemYellow
        copyAllButton.isEnabled = false
        copyAllButton.setImage(copyImage, for: .normal)
        copyAllButton.addTarget(
            self,
            action: #selector(copyTextToPasteboard),
            for: .touchUpInside
        )

        return copyAllButton
    }()

    private var activityIndicator = UIActivityIndicatorView(style: .large)

    private var resultsTextView = ResultsTextView()

    public var resultsLayout: ResultsLayout = .plain {
        didSet {
            preferencesStore.set(resultsLayout)

            switch resultsLayout {
            case .plain:
                addResultsTextView()
            case .clustered:
                resultsTextView.removeFromSuperview()
            }
        }
    }

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            switch recognitionState {
            case .notStarted:
                view.alpha = 0
                activityIndicator.alpha = 0
                activityIndicator.stopAnimating()
                copyAllButton.removeFromSuperview()
                copyAllButton.isEnabled = false

            case .inProgress:
                UIView.animate(withDuration: 0.15) {
                    self.view.alpha = 1
                }

                addCopyAllButton()

                activityIndicator.alpha = 1
                activityIndicator.startAnimating()

            case .complete:
                resultsLayout = preferencesStore.get(ResultsLayout.self)

                UIView.animate(withDuration: 0.25, animations: {
                    self.activityIndicator.alpha = 0
                }) { isFinished in
                    if (isFinished) {
                        self.activityIndicator.stopAnimating()
                        self.copyAllButton.isEnabled = true
                    }
                }
            }

            resultsTextView.recognitionState = recognitionState
        }
    }

    private weak var cameraShutterView: UIView?

    public init(cameraShutterView: UIView) {
        super.init(nibName: nil, bundle: nil)

        self.cameraShutterView = cameraShutterView

        addBlurView()
        addResultsLayoutSegmentedControl()
        addActivityIndicator()
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

    private func addResultsLayoutSegmentedControl() {
        view.addSubview(resultsLayoutSegmentedControl)

        resultsLayoutSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: resultsLayoutSegmentedControl.centerXAnchor),
            resultsLayoutSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
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

    private func addResultsTextView() {
        view.addSubview(resultsTextView)

        resultsTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: resultsTextView.leadingAnchor),
            resultsLayoutSegmentedControl.bottomAnchor.constraint(equalTo: resultsTextView.topAnchor),
            view.trailingAnchor.constraint(equalTo: resultsTextView.trailingAnchor),
            resultsTextView.bottomAnchor.constraint(equalTo: (cameraShutterView?.topAnchor ?? view.bottomAnchor))
        ])
    }

    private func addCopyAllButton() {
        view.addSubview(copyAllButton)

        copyAllButton.translatesAutoresizingMaskIntoConstraints = false

        if let cameraShutterView = cameraShutterView {
            NSLayoutConstraint.activate([
                copyAllButton.leadingAnchor.constraint(equalTo: cameraShutterView.trailingAnchor),
                copyAllButton.centerYAnchor.constraint(equalTo: cameraShutterView.centerYAnchor),
                copyAllButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                copyAllButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20),
                copyAllButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
            ])
        }
    }

    @objc private func didChangeResultsLayout(
        _ segmentedControl: UISegmentedControl
    ) {
        resultsLayout = ResultsLayout.allCases[segmentedControl.selectedSegmentIndex]
    }

    @objc private func copyTextToPasteboard() {
        UIPasteboard.general.string = resultsTextView.text
    }
}
