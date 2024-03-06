import UIKit

/**
 - author: VietHQ
 */
extension UITextView {
    // MARK: public function
    // using this function to add clickable ranges then receive the range is clicked in callback
    func addClickable(to ranges: NSRange..., then: @escaping (NSRange) -> Void) {
        guard let _ = self.attributedText else {
            return
        }
        
        self.addTapGesture(check: ranges, then: then)
    }
    
    // MARK: private function
    private func addTapGesture(check ranges: [NSRange], then: @escaping (NSRange) -> Void) {
        let tap = UITapGestureRecognizer { (gesture) in
            let touchPoint = gesture.location(in: self)
            for range in ranges {
                if self.didTapAttributedLink(at: touchPoint, inRange: range) {
                    then(range)
                }
            }
        }
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    private func didTapAttributedLink(at touchPoint: CGPoint, inRange targetRange: NSRange) -> Bool {
        // Find the tapped character location and compare it to the specified range
        let beginning = beginningOfDocument
        let start = position(from: beginning, offset: targetRange.location)
        let end = position(from: start!, offset: targetRange.length)
        let textRange = textRange(from: start!, to: end!)
        let rect = firstRect(for: textRange!)
        return rect.contains(touchPoint)
    }
}

// MARK: UITapGestureRecognizer closure
private extension UITapGestureRecognizer {
    private struct MEAssociatedKeys {
        static var key: UInt8 = 0
    }
    
    private var tapableEvent: (UITapGestureRecognizer) -> Void {
        get {
            return objc_getAssociatedObject(self, &MEAssociatedKeys.key) as! (UITapGestureRecognizer) -> Void
        }
        
        set {
            return objc_setAssociatedObject(self, &MEAssociatedKeys.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    convenience init(action: @escaping (UITapGestureRecognizer) -> Void) {
        self.init()
        self.addTarget(self, action: #selector(tapCallback(tap:)))
        self.tapableEvent = action
    }
    
    @objc func tapCallback(tap: UITapGestureRecognizer) {
        self.tapableEvent(tap)
    }
}
