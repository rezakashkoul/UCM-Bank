import UIKit
import MarqueeLabel

class TableViewCell: UITableViewCell {
    
    struct Config {
        let date: Date
        let amount: Double
        let type: TransactionType
        let currency: Currency
        let reason: TransactionReason
        let receiver: TransactionReceiver
    }
    
    @IBOutlet weak var transactionImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var descriptionLabel: MarqueeLabel!
    
    static let identifier = "TableViewCell"
    
    var config: Config!
    
}

//MARK: - Setup Functions
extension TableViewCell {
    
    func setupCell(with config: Config) {
        self.config = config
        setupView()
    }
    
    private func setupView() {
        amountLabel.text = config.amount.description + " " + config.currency.getCurrency()
        setupTransactionImageView()
        setupDateLabel()
        setupDescriptionLabel()

    }
    
    private func setupTransactionImageView() {
        if config.type == .outcome {
            transactionImageView.image = UIImage(systemName: "chevron.up")
            transactionImageView.tintColor = .red
        } else {
            transactionImageView.image = UIImage(systemName: "chevron.down")
            transactionImageView.tintColor = .green
        }
    }
    
    private func setupDateLabel() {
        let date = config.date.getPrettyDate(format: "yy/MM/dd")
        let time = config.date.getPrettyTime()
        dateLabel.text = date + " - " + time
    }
    
    private func setupDescriptionLabel() {
        descriptionLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        switch config.reason {
        case .bill:
            descriptionLabel.text = "Payed bill to \(config.receiver.title) for account ID \(config.receiver.id) - "
        case .transfer:
            descriptionLabel.text = "Transferred to \(config.receiver.title) by account ID: \(config.receiver.id) - "
        }
    }
}
