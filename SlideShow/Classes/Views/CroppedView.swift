//
//  CroppedView.swift
//  SlideShow
//
//  Created by Walter on 9/5/22.
//

import UIKit

class CroppedView: UIView {

    func cutViewCornersWith(cornerRadius: CGFloat, arcRadius: CGFloat) {
        let path = UIBezierPath()

        let width = self.frame.width
        let height = self.frame.height
        let arcCenter = height - height/3

        path.move(to: CGPoint(x: 0, y: cornerRadius))

        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(180.0).toRadians(),
                    endAngle: CGFloat(270.0).toRadians(),
                    clockwise: true)

        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0.0))

        path.addArc(withCenter: CGPoint(x: width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(90.0).toRadians(),
                    endAngle: CGFloat(0.0).toRadians(),
                    clockwise: true)

        path.addLine(to: CGPoint(x: width, y: arcCenter - arcRadius))

        path.addArc(withCenter: CGPoint(x: width, y: arcCenter),
                    radius: arcRadius,
                    startAngle: CGFloat(270.0).toRadians(),
                    endAngle: CGFloat(90.0).toRadians(),
                    clockwise: false)

        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))

        path.addArc(withCenter: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(0.0).toRadians(),
                    endAngle: CGFloat(90.0).toRadians(),
                    clockwise: true)

        path.addLine(to: CGPoint(x: cornerRadius, y: height))

        path.addArc(withCenter: CGPoint(x: cornerRadius, y: height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(90.0).toRadians(),
                    endAngle: CGFloat(180.0).toRadians(),
                    clockwise: true)

        path.addLine(to: CGPoint(x: 0, y: arcCenter + arcRadius))

        path.addArc(withCenter: CGPoint(x: 0, y: arcCenter),
                    radius: arcRadius,
                    startAngle: CGFloat(90.0).toRadians(),
                    endAngle: CGFloat(270.0).toRadians(),
                    clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: arcCenter - arcRadius))
        path.addLine(to: CGPoint(x: 0, y: 0))

        path.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        self.layer.mask = shapeLayer
    }
}

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * .pi / 180.0
    }
}

