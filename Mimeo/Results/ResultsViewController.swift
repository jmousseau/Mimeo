//
//  ResultsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Iris
import MetalKit
import MimeoKit
import UIKit

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

    private lazy var copyAllButton: UIButton = {
        let symbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let copyImage = UIImage(
            systemName: "doc.on.doc",
            withConfiguration: symbolConfiguration
        )

        let copyAllButton = UIButton()
        copyAllButton.tintColor = .mimeoYellow
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

    private lazy var resultsTableView: ResultsTableView = {
        let resultsTableView = ResultsTableView()
        resultsTableView.resultsDelegate = self
        return resultsTableView
    }()

    private var dissolver = Dissolver()

    private lazy var dissolvingTextView: MTKView = {
        let dissolvingTextView = MTKView(
            frame: .zero,
            device: MTLCreateSystemDefaultDevice()!
        )
        dissolvingTextView.backgroundColor = .clear
        dissolvingTextView.delegate = dissolver
        dissolvingTextView.framebufferOnly = true
        dissolvingTextView.colorPixelFormat = .bgra8Unorm
        dissolvingTextView.contentScaleFactor = UIScreen.main.scale
        return dissolvingTextView
    }()

    public var resultsLayout: ResultsLayout {
        didSet {
            preferencesStore.set(resultsLayout)

            if resultsTableView.superview == nil {
                addResultsTableView()
                addDissolvingTextView()

                view.bringSubviewToFront(resultsTableView)
            }

            resultsTableView.state = (recognitionState, resultsLayout)
        }
    }

    public var recognitionState: TextRecognizer.RecognitionState = .notStarted {
        didSet {
            resultsTableView.state = (recognitionState, resultsLayout)

            switch recognitionState {
            case .notStarted, .failed:
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

            case .complete(let result):
                let plainText = result.observations.plainText()

                MimeoAnalytics.shared.record(event: MimeoAnalytics.Events.RecognizedTextEvent(
                    totalRecognizedTextLength: UInt(plainText.count)
                ))

                if (!plainText.isEmpty) {
                    MimeoProSubscription.isSubscribed {
                        let recognitionResult = RecognitionResult(context: Store.viewContext)
                        recognitionResult.text = plainText
                        recognitionResult.createdAt = Date()
                        try? recognitionResult.managedObjectContext?.save()
                    }
                }

                resultsLayout = preferencesStore.get(ResultsLayout.self)

                UIView.animate(withDuration: 0.25, animations: {
                    self.activityIndicator.alpha = 0
                }) { isFinished in
                    if (isFinished) {
                        self.activityIndicator.stopAnimating()
                        self.copyAllButton.isEnabled = result.observations.count > 0
                    }
                }
            }
        }
    }

    private let dispatchQueue = DispatchQueue(label: "jack")

    private weak var cameraShutterView: UIView?

    public init(cameraShutterView: UIView) {
        self.resultsLayout = preferencesStore.get(ResultsLayout.self)
        self.cameraShutterView = cameraShutterView

        super.init(nibName: nil, bundle: nil)

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

    private func addResultsTableView() {
        view.addSubview(resultsTableView)

        resultsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: resultsTableView.leadingAnchor),
            resultsLayoutSegmentedControl.bottomAnchor.constraint(
                equalTo: resultsTableView.topAnchor,
                constant: -32
            ),
            view.trailingAnchor.constraint(equalTo: resultsTableView.trailingAnchor),
            resultsTableView.bottomAnchor.constraint(
                equalTo: (cameraShutterView?.topAnchor ?? view.bottomAnchor),
                constant: -32
            )
        ])
    }

    private func addDissolvingTextView() {
        view.addSubview(dissolvingTextView)

        dissolvingTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dissolvingTextView.leftAnchor.constraint(equalTo: resultsTableView.leftAnchor),
            dissolvingTextView.rightAnchor.constraint(equalTo: resultsTableView.rightAnchor),
            dissolvingTextView.topAnchor.constraint(equalTo: resultsTableView.topAnchor),
            dissolvingTextView.bottomAnchor.constraint(equalTo: resultsTableView.bottomAnchor)
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
        UIPasteboard.general.string = resultsTableView.copyAllRecognizedText()
        dissolveText(in: resultsTableView.allRecognizedTextViews())
    }

    fileprivate func dissolveText(in views: [UIView]) {
        let tableViewOffset = CGPoint(
            x: resultsTableView.contentOffset.x,
            y: -1 * resultsTableView.contentOffset.y
        )

        let rects = views.map { view in
            view
                .convert(view.frame, to: resultsTableView)
                .offset(by: tableViewOffset)
                .scaled(by: UIScreen.main.scale)
        }

        if let image = ImageFilter.subtract(
            rects: rects,
            invert: true
        ).apply(to: image(
            of: resultsTableView,
            offset: tableViewOffset
        ))?.cgImage {
            dissolver.dissolve(image: image)
        }
    }

    private func image(of view: UIView, offset: CGPoint) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds.offset(by: offset), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

}

extension ResultsViewController: ResultsTableViewDelegate  {

    public func resultsTableView(
        _ resultsTableView: ResultsTableView,
        didCopyText text: String,
        in view: UIView
    ) {
        UIPasteboard.general.string = text
        dissolveText(in: [view])
    }

}
