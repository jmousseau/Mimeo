//
//  IntentHandler.swift
//  MimeoIntents
//
//  Created by Jack Mousseau on 10/18/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is RecognizeTextIntent:
            return RecognizeTextIntentHandler()

        default:
            fatalError("Unhandle intent type: \(intent)")
        }
    }
    
}
