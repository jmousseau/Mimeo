//
//  RecognitionHistoryCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class RecognitionHistoryCell: BooleanSettingCell, MimeoProSettingCell {

    public init(preferencesStore: PreferencesStore) {
        super.init(
            title: "Recognition History",
            preferenceStore: preferencesStore,
            preference: RecognitionHistory.self
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
