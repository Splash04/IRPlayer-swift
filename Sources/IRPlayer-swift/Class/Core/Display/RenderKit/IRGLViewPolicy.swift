//
//  IRGLViewPolicy.swift
//  IRPlayer-swift
//
//  Created by Codex on 2026/6/2.
//

import UIKit

enum IRGLViewPolicy {
    static func drawablePixelSize(from size: CGSize) -> (width: Int, height: Int)? {
        guard size.width.isFinite,
              size.height.isFinite,
              size.width > 0,
              size.height > 0,
              size.width <= CGFloat(Int.max),
              size.height <= CGFloat(Int.max) else {
            return nil
        }
        return (Int(size.width), Int(size.height))
    }

    static func fittedImageTransform(imageExtent: CGRect,
                                     targetRect: CGRect,
                                     contentMode: IRGLRenderContentMode) -> IRGLView.FittedImageTransform? {
        guard imageExtent.origin.x.isFinite,
              imageExtent.origin.y.isFinite,
              imageExtent.width.isFinite,
              imageExtent.height.isFinite,
              targetRect.width.isFinite,
              targetRect.height.isFinite,
              imageExtent.width > 0,
              imageExtent.height > 0,
              targetRect.width > 0,
              targetRect.height > 0 else {
            return nil
        }

        var scaleX = targetRect.width / imageExtent.width
        var scaleY = targetRect.height / imageExtent.height

        switch contentMode {
        case .scaleAspectFit:
            let scale = min(scaleX, scaleY)
            scaleX = scale
            scaleY = scale
        case .scaleAspectFill:
            let scale = max(scaleX, scaleY)
            scaleX = scale
            scaleY = scale
        case .scaleToFill:
            break
        @unknown default:
            break
        }

        let scaledExtent = imageExtent.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        let translationX = (targetRect.width - scaledExtent.width) / 2.0 - scaledExtent.origin.x
        let translationY = (targetRect.height - scaledExtent.height) / 2.0 - scaledExtent.origin.y
        return IRGLView.FittedImageTransform(scaleX: scaleX,
                                             scaleY: scaleY,
                                             translationX: translationX,
                                             translationY: translationY)
    }

    static func texUVTextureLayout(width: Int, height: Int) -> (bytesPerRow: Int, totalByteCount: Int)? {
        guard width > 0, height > 0 else { return nil }

        let bytesPerTexel = MemoryLayout<Float>.size * 2
        let (bytesPerRow, rowOverflow) = width.multipliedReportingOverflow(by: bytesPerTexel)
        guard !rowOverflow, bytesPerRow > 0 else { return nil }

        let (totalByteCount, totalOverflow) = bytesPerRow.multipliedReportingOverflow(by: height)
        guard !totalOverflow, totalByteCount > 0 else { return nil }

        return (bytesPerRow: bytesPerRow, totalByteCount: totalByteCount)
    }

    static func translationVector(for scope: IRGLScope2D?) -> SIMD2<Float> {
        guard let scope,
              scope.w > 0,
              scope.h > 0,
              scope.scaleX.isFinite,
              scope.scaleY.isFinite,
              scope.offsetX.isFinite,
              scope.offsetY.isFinite,
              scope.scaleX > 0,
              scope.scaleY > 0 else {
            return SIMD2<Float>(repeating: 0)
        }

        let tx: Float
        if scope.scaleX >= 1.0 {
            tx = (scope.offsetX * scope.scaleX * 2 / Float(scope.w)) + 1.0 - scope.scaleX
        } else {
            tx = 0
        }

        let ty: Float
        if scope.scaleY >= 1.0 {
            ty = -((scope.offsetY * scope.scaleY * 2 / Float(scope.h)) + 1.0 - scope.scaleY)
        } else {
            ty = 0
        }

        return SIMD2<Float>(tx, ty)
    }
}
