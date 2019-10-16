//
//  ResultsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit
import SpriteKit

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

            case .grouped:
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

    private lazy var betaLabel: UILabel = {
        let betaLabel = InsetLabel()
        betaLabel.contentInsets = .init(top: 2, left: 4, bottom: 2, right: 4)
        betaLabel.text = "BETA"
        betaLabel.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        betaLabel.textColor = .white
        betaLabel.backgroundColor = .systemGreen
        betaLabel.clipsToBounds = true
        betaLabel.layer.cornerRadius = 6
        return betaLabel
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

    private var resultsCollectionView = ResultsCollectionView()

    private var dissolvingTextView: DissolvingTextView = {
        let dissolvingTextView = DissolvingTextView()
        dissolvingTextView.presentScene(SKScene())
        dissolvingTextView.allowsTransparency = true
        dissolvingTextView.scene?.scaleMode = .resizeFill
        dissolvingTextView.scene?.backgroundColor = .clear
        return dissolvingTextView
    }()

    public var resultsLayout: ResultsLayout = .plain {
        didSet {
            preferencesStore.set(resultsLayout)

            if resultsCollectionView.superview == nil {
                addResultsCollectionView()
                addDissolvingTextView()
            }

            UIView.animate(withDuration: 0.25) {
                self.betaLabel.alpha = self.resultsLayout.isBeta ? 1 : 0
            }

            resultsCollectionView.state = (recognitionState, resultsLayout)
        }
    }

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            resultsCollectionView.state = (recognitionState, resultsLayout)

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
                        self.dissolvingTextView.preload(view: self.resultsCollectionView)
                    }
                }
            }
        }
    }

    private let dispatchQueue = DispatchQueue(label: "jack")

    private weak var cameraShutterView: UIView?

    public init(cameraShutterView: UIView) {
        super.init(nibName: nil, bundle: nil)

        self.cameraShutterView = cameraShutterView

        addBlurView()
        addResultsLayoutSegmentedControl()
        addBetaLabel()
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

    private func addBetaLabel() {
        view.addSubview(betaLabel)

        betaLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            betaLabel.centerXAnchor.constraint(equalTo: resultsLayoutSegmentedControl.trailingAnchor, constant: -2),
            betaLabel.centerYAnchor.constraint(equalTo: resultsLayoutSegmentedControl.topAnchor, constant: 2)
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

    private func addResultsCollectionView() {
        view.addSubview(resultsCollectionView)

        resultsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: resultsCollectionView.leadingAnchor),
            resultsLayoutSegmentedControl.bottomAnchor.constraint(
                equalTo: resultsCollectionView.topAnchor,
                constant: -32
            ),
            view.trailingAnchor.constraint(equalTo: resultsCollectionView.trailingAnchor),
            resultsCollectionView.bottomAnchor.constraint(
                equalTo: (cameraShutterView?.topAnchor ?? view.bottomAnchor),
                constant: -32
            )
        ])
    }

    private func addDissolvingTextView() {
        view.addSubview(dissolvingTextView)

        dissolvingTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dissolvingTextView.leadingAnchor.constraint(equalTo: resultsCollectionView.leadingAnchor),
            dissolvingTextView.topAnchor.constraint(equalTo: resultsCollectionView.topAnchor),
            dissolvingTextView.trailingAnchor.constraint(equalTo: resultsCollectionView.trailingAnchor),
            dissolvingTextView.bottomAnchor.constraint(equalTo: resultsCollectionView.bottomAnchor)
        ])
    }

    private func addCopyAllButton() {
        view.addSubview(copyAllButton)

        copyAllButton.translatesAutoresizingMaskIntoConstraints = false

        if let cameraShutterView = cameraShutterView {
            NSLayoutConstraint.activate([
                copyAllButton.leadingAnchor.constraint(equalTo: view.centerXAnchor),
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
        dissolvingTextView.dissolveText()
        UIPasteboard.general.string = resultsCollectionView.allRecognizedText
    }
}
