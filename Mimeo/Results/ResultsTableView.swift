//
//  ResultsTableView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/10/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import FontClassifier
import Iris
import MimeoKit
import SpriteKit
import UIKit

public protocol ResultsTableViewDelegate: class {

    func resultsTableView(
        _ resultsTableView: ResultsTableView,
        didCopyText text: String,
        in view: UIView
    )

}

public final class ResultsTableView: UITableView {

    public final class Cell: UITableViewCell {

        fileprivate static let identifier = "results-cell"

        private let serifFont = UIFont(
            name: "NewYorkSmall-Regular",
            size: UIFont.preferredFont(forTextStyle: .body).pointSize
        )

        private let sansSerifFont = UIFont.preferredFont(forTextStyle: .body)

        fileprivate lazy var textView: UITextView = {
            let textView = UITextView()
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.backgroundColor = .clear
            textView.font = fontClassification == .serif ? serifFont : sansSerifFont
            textView.adjustsFontForContentSizeCategory = true
            textView.tintColor = .mimeoYellow
            return textView
        }()

        private lazy var copyButton: UIButton = {
            let symbolConfiguration = UIImage.SymbolConfiguration(scale: .small)
            let copyImage = UIImage(
                systemName: "doc.on.doc",
                withConfiguration: symbolConfiguration
            )

            let copyButton = UIButton()
            copyButton.tintColor = .mimeoYellow
            copyButton.setImage(copyImage, for: .normal)
            copyButton.setTitle(" Copy", for: .normal)
            copyButton.setTitleColor(.mimeoYellow, for: .normal)
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
            stackView.addArrangedSubview(textView)
            stackView.addArrangedSubview(copyButtonStackView)
            return stackView
        }()

        public fileprivate(set) var didCopy: ((String) -> Void)?

        public var recognizedText: String? {
            didSet {
                textView.text = recognizedText
            }
        }

        public var fontClassification: FontClassifier.Classification = .serif {
            didSet {
                textView.font = fontClassification == .serif ? serifFont : sansSerifFont
            }
        }

        public var isCopyButtonVisible: Bool = true {
            didSet {
                copyButtonStackView.isHidden = !isCopyButtonVisible
            }
        }

        public override init(
            style: UITableViewCell.CellStyle,
            reuseIdentifier: String?
        ) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)

            backgroundColor = .clear

            addStackView()
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public override func prepareForReuse() {
            textView.text = nil
        }

        private func addStackView() {
            addSubview(stackView)

            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
            ])
        }

        @objc private func didPressCopyButton() {
            guard let text = textView.text else {
                return
            }

            didCopy?(text)
        }

    }

    private let preferencesStore = PreferencesStore.default()

    public weak var resultsDelegate: ResultsTableViewDelegate?

    public var state: (
        recognitionState: TextRecognizer.RecognitionState,
        resultsLayout: ResultsLayout
    ) = (.notStarted, .plain) {
        didSet {
            switch state {
            case (.notStarted, _), (.failed, _):
                recognizedText = []
                cachedGroupedRecognizedText = nil
                backgroundView = nil

            case (.inProgress, _):
                break

            case (.complete(let result), .plain):
                updateNoResultsLabel(for: result)
                fontClassification = result.fontClassification ?? .serif
                recognizedText = [result.observations.plainText()]

            case (.complete(let result), .grouped):
                updateNoResultsLabel(for: result)
                fontClassification = result.fontClassification ?? .serif

                if let groupedRecognizedText = cachedGroupedRecognizedText {
                    recognizedText = groupedRecognizedText
                } else {
                    cachedGroupedRecognizedText = result.observations.groupedText()
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

    private var fontClassification: FontClassifier.Classification = .serif

    private lazy var noResultsLabel: UILabel = {
        let noResultsLabel = UILabel()
        noResultsLabel.numberOfLines = 0
        noResultsLabel.text = "No text detected"
        noResultsLabel.textColor = .secondaryLabel
        noResultsLabel.textAlignment = .center
        return noResultsLabel
    }()

    public convenience init(frame: CGRect) {
        self.init(frame: .zero, style: .plain)

        backgroundColor = .clear
        separatorStyle = .none
        alwaysBounceVertical = true
        allowsSelection = false

        dataSource = self

        register(Cell.classForCoder(), forCellReuseIdentifier: Cell.identifier)
    }

    public func copyAllRecognizedText() -> String {
        recognizedText.joined(separator: " ")
    }

    public func allRecognizedTextViews() -> [UIView] {
        visibleCells.compactMap { cell in
            guard let textView = (cell as? Cell)?.textView else {
                return nil
            }

            return textView
        }
    }

    private func updateNoResultsLabel(
        for result: TextRecognizer.RecognizedTextResult
    ) {
        if result.observations.count > 0 {
            backgroundView = nil
        } else {
            noResultsLabel.bounds = bounds
            backgroundView = noResultsLabel
        }
    }

}

extension ResultsTableView: UITableViewDataSource {

    public func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        recognizedText.count
    }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Cell.identifier,
            for: indexPath
        ) as? Cell else {
            fatalError("Dequeue resuable cell failed with identifier: \(Cell.identifier)")
        }

        cell.textView.dataDetectorTypes = preferencesStore
            .get(DataDetectionSetting.self)
            .enabledDataDetectorTypes

        cell.recognizedText = recognizedText[indexPath.row]
        cell.fontClassification = fontClassification
        cell.isCopyButtonVisible = state.resultsLayout == .grouped
        cell.didCopy = { text in
            self.resultsDelegate?.resultsTableView(
                self,
                didCopyText: cell.textView.text,
                in: cell.textView
            )
        }

        return cell
    }

}
