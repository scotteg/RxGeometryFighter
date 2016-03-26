//
//  RxSCNSceneRendererDelegateProxy.swift
//  GeometryFighter
//
//  Created by Scott Gardner on 3/26/16.
//  Copyright © 2016 Scott Gardner. All rights reserved.
//

import Foundation
import SceneKit
import RxSwift
import RxCocoa

public class RxSCNSceneRendererDelegateProxy: DelegateProxy, DelegateProxyType, SCNSceneRendererDelegate {
  
  public override static func createProxyForObject(object: AnyObject) -> AnyObject {
    let scnView = object as! SCNView
    return scnView.rx_createDelegateProxy()
  }
  
  public static func setCurrentDelegate(delegate: AnyObject?, toObject object: AnyObject) {
    let scnSceneRenderer = object as! SCNSceneRenderer
    scnSceneRenderer.delegate = delegate as? SCNSceneRendererDelegate
  }
  
  public static func currentDelegateFor(object: AnyObject) -> AnyObject? {
    let scnSceneRenderer = object as! SCNSceneRenderer
    return scnSceneRenderer.delegate
  }
  
}
