//
//  SendFeedbackCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import MessageUI

public final class SendFeedbackCell: SettingCell {

    public init(presenter: UIViewController & MFMailComposeViewControllerDelegate) {
        super.init(title: "Send Feedback") {
            guard MFMailComposeViewController.canSendMail() else {
                return
            }

            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.view.tintColor = .systemBlue
            mailComposeViewController.mailComposeDelegate = presenter
            mailComposeViewController.setToRecipients(["mimeo@jmousseau.com"])
            mailComposeViewController.setSubject("\(Bundle.main.applicationDisplayName) Feedback")
            mailComposeViewController.becomeFirstResponder()
            presenter.present(mailComposeViewController, animated: true)
        }

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
