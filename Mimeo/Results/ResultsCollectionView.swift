//
//  ResultsCollectionView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/10/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import SpriteKit
import UIKit

public final class ResultsCollectionView: UICollectionView {

    public final class Cell: UICollectionViewCell {

        fileprivate static let identifier = "results-collection-view-cell"

        private lazy var label: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            return label
        }()

        private lazy var dissolvingTextView: DissolvingTextView = {
            let dissolvingTextView = DissolvingTextView()
            dissolvingTextView.presentScene(SKScene())
            dissolvingTextView.allowsTransparency = true
            dissolvingTextView.scene?.scaleMode = .resizeFill
            dissolvingTextView.scene?.backgroundColor = .clear
            return dissolvingTextView
        }()

        private lazy var copyButton: UIButton = {
            let symbolConfiguration = UIImage.SymbolConfiguration(scale: .small)
            let copyImage = UIImage(
                systemName: "doc.on.doc.fill",
                withConfiguration: symbolConfiguration
            )

            let copyButton = UIButton()
            copyButton.tintColor = .systemYellow
            copyButton.setImage(copyImage, for: .normal)
            copyButton.setTitle(" Copy", for: .normal)
            copyButton.setTitleColor(.systemYellow, for: .normal)
            copyButton.addTarget(
                self,
                action: #selector(didPressCopyButton),
                for: .touchUpInside
            )

            return copyButton
        }()

        private lazy var copyButtonStackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.addArrangedSubview(copyButton)
            stackView.addArrangedSubview(UIView())
            return stackView
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 8
            stackView.addArrangedSubview(label)
            stackView.addArrangedSubview(copyButtonStackView)
            return stackView
        }()

        public fileprivate(set) var didCopy: ((String) -> Void)?

        public var text: String? {
            didSet {
                label.text = text

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.dissolvingTextView.preload(view: self.label)
                }
            }
        }

        public var isCopyButtonVisible: Bool = true {
            didSet {
                copyButtonStackView.isHidden = !isCopyButtonVisible
            }
        }

        public override init(frame: CGRect) {
            super.init(frame: frame)

            addStackView()
            addDissolvingTextView()
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func addStackView() {
            addSubview(stackView)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        private func addDissolvingTextView() {
            addSubview(dissolvingTextView)

            dissolvingTextView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dissolvingTextView.leadingAnchor.constraint(equalTo: label.leadingAnchor),
                dissolvingTextView.topAnchor.constraint(equalTo: label.topAnchor),
                dissolvingTextView.trailingAnchor.constraint(equalTo: label.trailingAnchor),
                dissolvingTextView.bottomAnchor.constraint(equalTo: label.bottomAnchor)
            ])
        }

        @objc private func didPressCopyButton() {
            guard let text = label.text else {
                return
            }

            dissolveText()
            didCopy?(text)
        }

        public func dissolveText() {
            dissolvingTextView.dissolveText()
        }

    }

    public var state: (
        recognitionState: TextRecognizer.RecognitionState,
        resultsLayout: ResultsLayout
    ) = (.notStarted, .plain) {
        didSet {
            switch state {
            case (.notStarted,  _):
                recognizedText = []
                cachedGroupedRecognizedText = nil

            case (.inProgress, _):
                break

            case (.complete(let recognizedTextObservations), .plain):
                recognizedText = [recognizedTextObservations
                    .sortedLeftToRightTopToBottom()
                    .compactMap({ observation in
                        observation.topCandidate?.string
                    })
                    .joined(separator: " ")]

            case (.complete(let recognizedTextObservations), .grouped):
                if let groupedRecognizedText = cachedGroupedRecognizedText {
                    recognizedText = groupedRecognizedText
                } else {
                    cachedGroupedRecognizedText = recognizedTextObservations
                        .clustered()
                        .map({ cluster in
                            cluster.observations
                                .compactMap({ observation in
                                    observation.topCandidate?.string
                                })
                                .joined(separator: " ")
                        })
                }
            }
        }
    }

    public var cachedGroupedRecognizedText: [String]? {
        didSet {
            recognizedText = cachedGroupedRecognizedText ?? []
        }
    }

    public private(set) var recognizedText = [String]() {
        didSet {
            reloadData()
        }
    }

    public convenience init(frame: CGRect) {
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(44)
        )

        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 32

        let layout = UICollectionViewCompositionalLayout(section: section)

        self.init(frame: frame, collectionViewLayout: layout)

        backgroundColor = .clear
        dataSource = self

        alwaysBounceVertical = true

        register(Cell.classForCoder(), forCellWithReuseIdentifier: Cell.identifier)
    }

    public func copyAllRecognizedText() -> String {
        visibleCells.forEach { cell in
            guard let cell = cell as? Cell else {
                return
            }

            cell.dissolveText()
        }

        return recognizedText.joined(separator: " ")
    }

}

extension ResultsCollectionView: UICollectionViewDataSource {

    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return recognizedText.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Cell.identifier,
            for: indexPath
        ) as? Cell else {
            fatalError("Dequeue resuable cell failed with identifier: \(Cell.identifier)")
        }

        cell.text = recognizedText[indexPath.row]
        cell.isCopyButtonVisible = state.resultsLayout == .grouped
        cell.didCopy = { text in
            UIPasteboard.general.string = text
        }

        return cell
    }
}
