import UIKit

extension UIApplication {
    
    class func topViewController(_ viewController: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        
        return viewController
    }
}


extension UIViewController {
    
    func hideKeyboardOnTap(_ selector: Selector) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: selector)
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension UIView {
    
    func getTextfields(_ view: UIView) -> [UITextField] {
        var textfields: [UITextField] = []
        for subview in view.subviews as [UIView] {
            if let textField = subview as? UITextField {
                textfields += [textField]
            } else {
                textfields += getTextfields(subview)
            }
        }
        return textfields
    }
    
    func dropShadowAndCornerRadius(_ value: CornerRadius, shadowOpacity: Float = 0.05) {
        roundUp(value)
        dropNormalShadow(opacity: shadowOpacity)
    }
    
    func roundUp(_ value: CornerRadius) {
        DispatchQueue.main.async { [weak self] in
            if value == .round {
                self?.layer.cornerRadius = (self?.bounds.height ?? 2) / 2
            } else {
                self?.layer.cornerRadius = value.rawValue
            }
            self?.layer.masksToBounds = true
        }
    }
    
    func dropNormalShadow(opacity:Float = 0.05) {
        DispatchQueue.main.async { [weak self] in
            self?.layer.masksToBounds = false
            self?.layer.shadowColor = UIColor.black.cgColor
            self?.layer.shadowOpacity = opacity
            self?.layer.shadowOffset = CGSize(width: 0, height: 0)
            self?.layer.shadowRadius = 8
        }
    }
}

extension UIScrollView {
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height + contentInset.bottom)
        if(bottomOffset.y > 0) {
            setContentOffset(bottomOffset, animated: true)
        }
    }
}

extension UITextField {
    
    func addDoneToolbar() {
        let bar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(hideKeyboard))
        doneButton.tintColor = UIColor.red
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bar.items = [spacer, doneButton]
        bar.sizeToFit()
        self.inputAccessoryView = bar
    }
    
    @objc private func hideKeyboard() {
        self.resignFirstResponder()
        self.endEditing(true)
    }
}

extension UITableView {

    func setEmptyMessage() {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = "There's no transactions."
        messageLabel.textColor = .systemPink
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }
    
    func removeEmptyMessage() {
        self.backgroundView = nil
        self.separatorStyle = .none
    }
}
