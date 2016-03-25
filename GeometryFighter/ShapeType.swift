//
//  ShapeType.swift
//  GeometryFighter
//
//  Created by Scott Gardner on 3/24/16.
//  Copyright © 2016 Scott Gardner. All rights reserved.
//

import Foundation

enum ShapeType: Int {
  
  case Box, Sphere, Pyramid, Torus, Capsule, Cylinder, Cone, Tube
  
  static func random() -> ShapeType {
    let i = Int(arc4random_uniform(UInt32(Tube.rawValue + 1)))
    return ShapeType(rawValue: i)!
  }
  
}
