import UIKit
import NotificationBannerSwift

class BannerManager {
    
    static func showMessage(messageText: String, messageSubtitle: String? = "", style: BannerStyle = .warning)  {
        DispatchQueue.main.async {
            
            let banner = FloatingNotificationBanner(title: messageText, subtitle: messageSubtitle, titleTextAlign: .center, subtitleTextAlign: .center, leftView: getIcon(for: style), style: style)
            
            banner.titleLabel?.font = .systemFont(ofSize: 14)
            banner.titleLabel?.layoutMargins.top += 10
            banner.titleLabel?.textAlignment = .left
            banner.subtitleLabel?.font = .systemFont(ofSize: 14)
            banner.subtitleLabel?.textAlignment = .left
            banner.dismissOnTap = true
            banner.haptic = .light
            banner.titleLabel?.textColor = .white
            banner.subtitleLabel?.textColor = .white
            banner.bannerQueue = NotificationBannerQueue(maxBannersOnScreenSimultaneously: 4)
            setBackgroundColor(banner, style: style)
            
            banner.show(
                queuePosition: .front,
                bannerPosition: .top,
                cornerRadius: 10,
                shadowColor: UIColor(red: 0.431, green: 0.459, blue: 0.494, alpha: 1),
                shadowBlurRadius: 16,
                shadowEdgeInsets: UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
            )
        }
    }
    
    static private func setBackgroundColor(_ banner: FloatingNotificationBanner, style: BannerStyle) {
        switch style {
        case .success:
            banner.backgroundColor = .systemGreen
        case .danger:
            banner.backgroundColor = .systemPink
        case .warning:
            banner.backgroundColor = .systemYellow
        default: break
        }
    }
    
    static private func getIcon(for style: BannerStyle)-> UIView? {
        var icon: UIImageView?
        switch style {
        case .warning:
            icon = UIImageView(image: UIImage(named: "danger")?.withRenderingMode(.alwaysTemplate))
        case .danger:
            icon = UIImageView(image: UIImage(named: "slash")?.withRenderingMode(.alwaysTemplate))
        case .success:
            icon = UIImageView(image: UIImage(named: "tick-circle")?.withRenderingMode(.alwaysTemplate))
        default: break
        }
        icon?.tintColor = .white
        return icon
    }
}
