import UIKit
import MarqueeLabel

protocol CollectionViewCellDelegate: AnyObject {
    func didSelectAccountEditButton(index: Int)
}

class CollectionViewCell: UICollectionViewCell {

    struct Config {
        let title, id: String
        let numberOfTransactions: Int
        let totalBalance: Double
        let currency: Currency
        let accountType: AccountType
        let index: Int
        let delegate: CollectionViewCellDelegate
    }
    
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var numberOfTransactionsLabel: UILabel!
    @IBOutlet weak var accountTypeLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var totalBalanceLabel: UILabel!

    @IBAction func editButtonAction(_ sender: Any) {
        delegate?.didSelectAccountEditButton(index: index)
    }
    
    static let identifier = "CollectionViewCell"
    weak var delegate: CollectionViewCellDelegate?
    var index = 0
    
    private var config: Config! {
        didSet {
            DispatchQueue.main.async {[self] in
                setupView()
                layoutIfNeeded()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        parentView.dropShadowAndCornerRadius(.large, shadowOpacity: 0.1)
    }

}

//MARK: - Setup Functions
extension CollectionViewCell {
    
    func setupCell(config: Config) {
        self.config = config
        self.delegate = config.delegate
        setupView()
    }
    
    private func setupView() {
        titleLabel.text = config.title
        titleLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        numberOfTransactionsLabel.text = "TXNs: " + "(\(config.numberOfTransactions))"
        totalBalanceLabel.text = config.totalBalance.description + " " + config.currency.getCurrency()
        accountNumberLabel.text = "#" + config.id
        self.index = config.index
        
        switch config.accountType {
        case .checking: accountTypeLabel.text = "Checking account"
        case .saving: accountTypeLabel.text = "Saving account"
        default: break
        }
    }
}
