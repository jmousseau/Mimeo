//
//  BooleanSettingCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/19/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class BooleanSettingCell: UITableViewCell {

    public static let identifier = "boolean-setting-cell"

    private lazy var preferenceStore = PreferencesStore.default()

    private let title: String

    private let onToggle: (Bool) -> Void

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    private lazy var toggle: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(toggleButtonPressed), for: .valueChanged)
        return toggle
    }()

    convenience init<P: BooleanPreferenceStorable>(
        title: String,
        preferenceStore: PreferencesStore,
        preference: P.Type,
        onToggle: ((_ isOn: Bool) -> Void)? = nil
    ) {
        self.init(title: title, isOn: preferenceStore.get(preference).isEnabled, onToggle: { isOn in
            preferenceStore.set(isOn ? P.enabledCase : P.disabledCase)
            onToggle?(isOn)
        })
    }

    init(title: String, isOn: Bool, onToggle: @escaping (_ isOn: Bool) -> Void) {
        self.title = title
        self.onToggle = onToggle

        super.init(style: .default, reuseIdentifier: Self.identifier)

        selectionStyle = .none

        toggle.isOn = isOn

        addTitleLabel()
        addToggle()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func toggleButtonPressed(_ toggle: UISwitch) {
        self.onToggle(toggle.isOn)
    }
}

// MARK: - View Layout

extension BooleanSettingCell {

    private func addTitleLabel() {
        addSubview(titleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),
            layoutMarginsGuide.topAnchor.constraint(
                equalTo: titleLabel.topAnchor
            ),
            layoutMarginsGuide.bottomAnchor.constraint(
                equalTo: titleLabel.bottomAnchor
            )
        ])
    }

    private func addToggle() {
        addSubview(toggle)

        toggle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toggle.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            toggle.leadingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor,
                constant: 8
            ),
            toggle.trailingAnchor.constraint(
                equalTo: layoutMarginsGuide.trailingAnchor
            )
        ])
    }

}
