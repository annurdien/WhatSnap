//
//  DrawSquare.swift
//  WhatSnap
//
//  Created by Annurdien Rasyid on 07/09/24.
//

import UIKit

class DrawSquare: UIView {

    override func draw(_ rect: CGRect) {
        let h = rect.height
        let w = rect.width
        let color:UIColor = UIColor.yellow
        
        let drect = CGRect(x: (w * 0.25),y: (h * 0.25), width: (w * 0.5),height: (h * 0.5))
        let bpath:UIBezierPath = UIBezierPath(rect: drect)
        
        color.set()
        bpath.stroke()
    }

}
