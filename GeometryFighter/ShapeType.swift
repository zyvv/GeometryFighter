//
//  ShapeType.swift
//  GeometryFighter
//
//  Created by gakki's vi~ on 2018/7/3.
//  Copyright © 2018年 zhangyw@yhyvr.com. All rights reserved.
//

import Foundation

enum ShapeType:Int {
    case box = 0
    case sphere
    case pyramid
    case torus
    case capsule
    case cylinder
    case cone
    case tube
    
    static func random() -> ShapeType {
        let maxValue = tube.rawValue
        let rand = arc4random_uniform(UInt32(maxValue+1))
        return ShapeType(rawValue: Int(rand))!
    }
}
