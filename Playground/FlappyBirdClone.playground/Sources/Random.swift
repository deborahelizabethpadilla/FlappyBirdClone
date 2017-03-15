//
//  Random.swift
//  FlappyBirdClone
//
//  Created by Deborah on 1/9/17.
//  Copyright © 2017 Deborah. All rights reserved.
//

import Foundation
import CoreGraphics


public extension CGFloat {
    
    public static func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat)
        -> CGFloat {
        
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + firstNum;
        
    }
}
