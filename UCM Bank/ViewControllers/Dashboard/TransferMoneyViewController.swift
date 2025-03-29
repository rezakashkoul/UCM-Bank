import UIKit
import RxSwift
import RxKeyboard
import NotificationBannerSwift

class TransferMoneyViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var originAccountTextField: UITextField!
    @IBOutlet weak var destinationAccountTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var transferButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var transferButton: UIButton!
    @IBAction func transferButtonAction(_ sender: Any) {
        if isEntriesValid() {
            transferAction()
        }
    }
    
    var disposeBag = DisposeBag()
    var textFields: [UITextField]!
    let pickerView = UIPickerView()
    let loadingVC = LoadingViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupViews()
    }
    
}

//MARK: - Setup Functions
private extension TransferMoneyViewController {
    
    func setupViews() {
        setupBackgroundView()
        setupNavigationController()
        handleKeyboardVisibility()
        setupTextFields()
        setupPickerView()
        transferButton.dropShadowAndCornerRadius(.regular)
    }
    
    func setupNavigationController() {
        tabBarController?.navigationItem.title = "Transfer Money"
        navigationItem.largeTitleDisplayMode = .always
        tabBarController?.navigationItem.hidesBackButton = true
        tabBarController?.navigationItem.rightBarButtonItem = nil
        setupNavigationTitleView()
    }
    
    func setupNavigationTitleView() {
        let textLabel = UILabel()
        textLabel.text = "UCM BANK"
        textLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        textLabel.textAlignment = .center
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 4.0
        stackView.addArrangedSubview(textLabel)
        tabBarController?.navigationItem.titleView = stackView
    }
    
    func setupBackgroundView() {
        if let accounts = currentUser?.accounts {
            backgroundView.isHidden = !accounts.isEmpty
            scrollView.isHidden = accounts.isEmpty
        }
    }
    
    func setupTextFields() {
        textFields = view.getTextfields(view)
        textFields.forEach({$0.delegate = self})
        textFields.forEach({$0.addDoneToolbar()})
        originAccountTextField.inputView = pickerView
        originAccountTextField.placeholder = "Please choose your account"
        destinationAccountTextField.placeholder = "Please enter the receiver account"
        amountTextField.placeholder = "Please set the amount to transfer"
        destinationAccountTextField.text = ""
        amountTextField.text = ""
        originAccountTextField.text = ""
    }
    
    func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    func showLoading(loadingVC: LoadingViewController) {
        DispatchQueue.main.async { [self] in
            loadingVC.modalPresentationStyle = .overCurrentContext
            loadingVC.modalTransitionStyle = .crossDissolve
            loadingVC.view.isUserInteractionEnabled = false
            transferButton.isEnabled = false
            present(loadingVC, animated: true, completion: nil)
        }
    }
    
    func dismissLoading(loadingVC: LoadingViewController) {
        DispatchQueue.main.async { [self] in
            loadingVC.dismiss(animated: true)
            loadingVC.view.isUserInteractionEnabled = true
            transferButton.isEnabled = true
        }
    }
}

//MARK: - TextField Functions
extension TransferMoneyViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == originAccountTextField && textField.text == "" {
            if let accounts = currentUser?.accounts, accounts.count > 0 {
                textField.text = accounts[0].id
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        let maxLength = 11
        
        switch textField {
        case originAccountTextField: return false
        case destinationAccountTextField:
            return newString.length <= maxLength
        default:
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case originAccountTextField:
            destinationAccountTextField.becomeFirstResponder()
        case destinationAccountTextField:
            amountTextField.becomeFirstResponder()
        case amountTextField:
            transferAction()
        default: break
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - PickerView Functions
extension TransferMoneyViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currentUser?.accounts.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let account = currentUser?.accounts[row] {
            return account.title + " " + account.id
        } else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        originAccountTextField.text = currentUser?.accounts[row].id
    }
}

//MARK: - Keyboard Functions
private extension TransferMoneyViewController {
    
    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.transferButtonBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

//MARK: - Actions
private extension TransferMoneyViewController {
    
    func transferAction() {
        showLoading(loadingVC: loadingVC)
        
        let destinationAccountID = destinationAccountTextField.text!
        if let receiverAccount = getDestinationAccount(destinationAccountID) {
            let destinationUser = getDestinationUser(destinationAccountID)
            let originAccountID = originAccountTextField.text!
            let originAccount = currentUser?.accounts.filter({$0.id == originAccountID}).first
            let baseAmount = Double(amountTextField.text!)!
            
            if originAccountID == destinationAccountID {
                BannerManager.showMessage(messageText: "Error!", messageSubtitle: "It is not possible to choose the same account for both side of transaction!", style: .danger)
                destinationAccountTextField.text = ""
                return
            }
            
            let newBalance = (originAccount?.balance ?? 0) - baseAmount
            
            if newBalance >= 0 {
                
                let transactionID = Int.random(in: 100000000...999999999).description
                let receiverInfo = (destinationUser?.personalInfo.firstName ?? "?") + " " + (destinationUser?.personalInfo.lastName ?? "??")
                let senderInfo = (currentUser?.personalInfo.firstName ?? "?") + " " + (currentUser?.personalInfo.lastName ?? "??")
                
                NetworkManager.shared.getExchangeRate { [self] result in
                    
                    switch result {
                    case .success(let newExchangeRate):
                        dismissLoading(loadingVC: loadingVC)
                        
                        let exchangeRate = calculateExchangeRate(onlineExchangeRatio: newExchangeRate, originCurrency: originAccount!.currency, destinationCurrency: receiverAccount.currency)
                        let exchangedAmount = (baseAmount * exchangeRate).roundToDecimal(2)
                        
                        print("exchange rates are:\(String(describing: newExchangeRate))")
                        
                        let outcomeTransaction = Transaction(date: Date(), amount: baseAmount, type: .outcome, reason: .transfer, id: transactionID, receiver: TransactionReceiver(title: receiverAccount.title + " " + receiverInfo, id: receiverAccount.id))
                        
                        let incomeTransaction = Transaction(date: Date(), amount: exchangedAmount, type: .income, reason: .transfer, id: transactionID, receiver: TransactionReceiver(title: senderInfo, id: originAccountID))
                        
                        showTransactionPromptAlert(amount: baseAmount, senderCurrency: originAccount?.currency ?? .none, receiverCurrency: receiverAccount.currency, receiverInfo: receiverInfo, receiverID: destinationAccountID, exchangedAmount: exchangedAmount, exchangeRatio: exchangeRate) { [self] buttonIndex in
                            if buttonIndex == 0 {
                                
                                setIncomeTransaction(receiverID: destinationAccountID, newBalance: exchangedAmount, transaction: incomeTransaction)
                                setOutcomeTransaction(originAccountID: originAccountID, newBalance: newBalance, transaction: outcomeTransaction)
                                
                                UserDefaults.standard.saveUsers()
                                
                                BannerManager.showMessage(messageText: "Success!", messageSubtitle: "The transaction submitted successfully. \n You can check it in Dashboard tab", style: .success)
                                showDashboardViewController()
                            } else {
                                BannerManager.showMessage(messageText: "Canceled", messageSubtitle: "Your Transaction canceled.", style: .danger)
                            }
                        }
                        
                    case .failure(let error):
                        
                        dismissLoading(loadingVC: loadingVC)
                        BannerManager.showMessage(messageText: "Error", messageSubtitle: "Can not get the current exchange ratio, please try again", style: .danger)
                        print("Error: ", error.localizedDescription)
                        return
                    }
                }
            } else {
                dismissLoading(loadingVC: loadingVC)
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Due to insufficient balance, Transaction failed.", style: .danger)
            }
        } else {
            dismissLoading(loadingVC: loadingVC)
            BannerManager.showMessage(messageText: "Receiver user not found!", messageSubtitle: "Please double check receiver account ID", style: .danger)
        }
    }
    
    func setIncomeTransaction(receiverID: String, newBalance: Double, transaction: Transaction) {
        allUsers = UserDefaults.standard.retrieveUsers()
        
    outerLoop: for i in 0..<allUsers.count {
        for j in 0..<allUsers[i].accounts.count {
            if allUsers[i].accounts[j].id == receiverID {
                allUsers[i].accounts[j].balance += newBalance
                allUsers[i].accounts[j].transactions.append(transaction)
                let sortedTransactions = allUsers[i].accounts[j].transactions.sorted(by: {$0.date > $1.date})
                allUsers[i].accounts[j].transactions = sortedTransactions
                saveAccount(user: allUsers[i])
                break outerLoop
            }
        }
    }
    }
    
    func setOutcomeTransaction(originAccountID: String, newBalance: Double, transaction: Transaction) {
        let user = currentUser
        allUsers = UserDefaults.standard.retrieveUsers()
        currentUser = allUsers.filter({$0.personalInfo == user!.personalInfo}).first
        
        for i in 0..<(currentUser?.accounts.count ?? 0) {
            if currentUser?.accounts[i].id == originAccountID {
                currentUser?.accounts[i].balance = newBalance
                currentUser?.accounts[i].transactions.append(transaction)
                let sortedTransactions = currentUser?.accounts[i].transactions.sorted(by: {$0.date > $1.date})
                currentUser?.accounts[i].transactions = sortedTransactions ?? []
                break
            }
        }
        saveAccount(user: currentUser!)
    }
    
    private func showTransactionPromptAlert(amount: Double, senderCurrency: Currency, receiverCurrency: Currency, receiverInfo: String, receiverID: String, exchangedAmount: Double, exchangeRatio: Double, completion: @escaping (Int?) -> ()) {
        let body = "You are transferring \"\(amount.description) \(senderCurrency.getCurrency())\" to \"\(receiverInfo)\" with account ID: \"\(receiverID)\". \n Exchange ratio is also \"\(exchangeRatio.roundToDecimal(2))\" and the final transaction amount they will get is \"\(exchangedAmount) \(receiverCurrency.getCurrency())\".\n\n Are you sure?"
        
        AlertManager.shared.showAlert(parent: self, title: "Notice", body: body, buttonTitles: ["OK"], style: .alert, completion: completion)
    }
    
    func getDestinationAccount(_ destinationAccountID: String)-> Account? {
        for i in 0..<allUsers.count {
            for account in allUsers[i].accounts {
                if account.id == destinationAccountID {
                    print("Account is found ", account.id)
                    return account
                }
            }
        }
        print("Account not found ")
        return nil
    }
    
    func getDestinationUser(_ destinationAccountID: String)-> User? {
        for i in 0..<allUsers.count {
            for account in allUsers[i].accounts {
                if account.id == destinationAccountID {
                    print("User is found ", account.id)
                    return allUsers[i]
                }
            }
        }
        print("User not found ")
        return nil
    }
    
    func isEntriesValid()-> Bool {
        let amount = amountTextField.text!
        let originAccount = originAccountTextField.text!
        let destinationAccount = destinationAccountTextField.text!
        let userAccounts = currentUser?.accounts ?? []
        
        if !amount.isEmpty && !originAccount.isEmpty && !destinationAccount.isEmpty && !userAccounts.isEmpty {
            
            let isAmountValid = ValidationRule.amount.isValidAmount(text: amount)
            let isOriginAccountValid = ValidationRule.bankID.isValidBankID(id: originAccount)
            let isDestinationAccountValid = ValidationRule.bankID.isValidBankID(id: destinationAccount)
            
            if isAmountValid && isOriginAccountValid && isDestinationAccountValid {
                return true
            }
        } else {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
            return false
        }
        return false
    }
}

//MARK: - Calculations
extension TransferMoneyViewController {
    
    func calculateExchangeRate(onlineExchangeRatio: ExchangeRate, originCurrency: Currency, destinationCurrency: Currency)-> Double {
        switch originCurrency {
        case .cad:
            switch destinationCurrency {
            case .cad:
                return 1
            case .usd:
                return onlineExchangeRatio.rates.usd
            case .gbp:
                return onlineExchangeRatio.rates.gbp
            case .eur:
                return onlineExchangeRatio.rates.eur
            case .none: break
            }
        case .usd:
            switch destinationCurrency {
            case .usd:
                return 1
            case .cad:
                return 1/onlineExchangeRatio.rates.usd
            case .gbp:
                return 1/onlineExchangeRatio.rates.usd * onlineExchangeRatio.rates.gbp
            case .eur:
                return 1/onlineExchangeRatio.rates.usd * onlineExchangeRatio.rates.eur
            case .none: break
            }
        case .gbp:
            switch destinationCurrency {
            case .gbp:
                return 1
            case .cad:
                return 1/onlineExchangeRatio.rates.gbp
            case .usd:
                return 1/onlineExchangeRatio.rates.gbp * onlineExchangeRatio.rates.usd
            case .eur:
                return 1/onlineExchangeRatio.rates.gbp * onlineExchangeRatio.rates.eur
            case .none: break
            }
        case .eur:
            switch destinationCurrency {
            case .eur:
                return 1
            case .cad:
                return 1/onlineExchangeRatio.rates.eur
            case .usd:
                return 1/onlineExchangeRatio.rates.eur * onlineExchangeRatio.rates.usd
            case .gbp:
                return 1/onlineExchangeRatio.rates.eur * onlineExchangeRatio.rates.gbp
            case .none: break
            }
        case .none: break
        }
        return -1
    }
}


//MARK: - Navigation Functions
extension TransferMoneyViewController {
    
    func showLoginViewController() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    func showDashboardViewController() {
        tabBarController?.selectedIndex = 0
    }
}
