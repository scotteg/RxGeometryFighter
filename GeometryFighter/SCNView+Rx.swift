//
//  SCNView+Rx.swift
//  GeometryFighter
//
//  Created by Scott Gardner on 3/26/16.
//  Copyright © 2016 Scott Gardner. All rights reserved.
//

import Foundation
import SceneKit
import RxSwift
import RxCocoa

extension SCNView {
  
  var rx_rendererUpdateAtTime: ControlEvent<(renderer: SCNSceneRenderer, time: NSTimeInterval)> {
    let source = rx_delegate.observe(#selector(SCNSceneRendererDelegate.renderer(_:updateAtTime:)))
      .map { ($0[0] as! SCNSceneRenderer, $0[1] as! NSTimeInterval) }
    return ControlEvent(events: source)
  }
  
  public func rx_createDelegateProxy() -> RxSCNSceneRendererDelegateProxy {
    return RxSCNSceneRendererDelegateProxy(parentObject: self)
  }
  
  public var rx_delegate: DelegateProxy {
    return proxyForObject(RxSCNSceneRendererDelegateProxy.self, self)
  }
  
}
