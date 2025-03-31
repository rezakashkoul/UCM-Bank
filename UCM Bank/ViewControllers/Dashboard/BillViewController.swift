import UIKit
import RxSwift
import RxKeyboard
import NotificationBannerSwift

class BillViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backgroundLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var payeeNameTextField: UITextField!
    @IBOutlet weak var payeeAccountNumberTextField: UITextField!
    @IBOutlet weak var userBankAccountTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var payButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var payButton: UIButton!
    @IBAction func payButtonAction(_ sender: Any) {
        payAction()
    }
    
    var disposeBag = DisposeBag()
    var textFields: [UITextField]!
    let payeeNamePickerView = UIPickerView()
    let userBankAccountPickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupViews()
    }
}

//MARK: - Setup Functions
private extension BillViewController {
    
    func setupViews() {
        setupNavigationController()
        setupBackgroundView()
        handleKeyboardVisibility()
        setupPickerView()
        setupTextFields()
        payButton.dropShadowAndCornerRadius(.regular)
    }
    
    func setupNavigationController() {
        tabBarController?.navigationItem.title = "Pay Bills"
        navigationItem.largeTitleDisplayMode = .always
        tabBarController?.navigationItem.hidesBackButton = true
        tabBarController?.navigationItem.rightBarButtonItem = nil
        
        setupNavigationTitleView()
    }
    
    func setupNavigationTitleView() {
        let textLabel = UILabel()
        textLabel.text  = "UCM BANK"
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
        if let currentUser = currentUser, currentUser.payees.isEmpty || currentUser.accounts.isEmpty {
            backgroundView.isHidden = false
            scrollView.isHidden = true
            if currentUser.payees.isEmpty {
                backgroundLabel.text = "Please add some payees in \"Payee\" tab"
            } else {
                backgroundLabel.text = "There's no account to work with.  Please add a new one from  Dashboard top right."
            }
        } else {
            backgroundView.isHidden = true
            scrollView.isHidden = false
        }
    }
    
    func setupPickerView() {
        payeeNamePickerView.delegate = self
        payeeNamePickerView.dataSource = self
        userBankAccountPickerView.delegate = self
        userBankAccountPickerView.dataSource = self
    }
    
    func setupTextFields() {
        textFields = view.getTextfields(view)
        textFields.forEach({$0.delegate = self})
        textFields.forEach({$0.addDoneToolbar()})
        payeeNameTextField.inputView = payeeNamePickerView
        userBankAccountTextField.inputView = userBankAccountPickerView
        payeeAccountNumberTextField.isUserInteractionEnabled = false
        payeeNameTextField.placeholder = "Please choose one payee"
        payeeAccountNumberTextField.placeholder = "This will set automatically"
        userBankAccountTextField.placeholder = "Please enter a American bank account number"
        amountTextField.placeholder = "Please set the bill amount"
        amountTextField.text = ""
        payeeNameTextField.text = ""
        payeeAccountNumberTextField.text = ""
        userBankAccountTextField.text = ""
    }
}

//MARK: - PickerView Functions
extension BillViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let currentUser = currentUser {
            if pickerView == payeeNamePickerView {
                return currentUser.payees.count
            } else if pickerView == userBankAccountPickerView {
                let americanAccounts = currentUser.accounts.filter({$0.id.last?.description == "1"})
                return americanAccounts.count
            }
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let currentUser = currentUser {
            if pickerView == payeeNamePickerView {
                return currentUser.payees[row].title
            } else if pickerView == userBankAccountPickerView {
                let americanAccounts = currentUser.accounts.filter({$0.id.last?.description == "1"})
                return americanAccounts[row].id
            }
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let currentUser = currentUser {
            if pickerView == payeeNamePickerView {
                payeeNameTextField.text = currentUser.payees[row].title
                payeeAccountNumberTextField.text = currentUser.payees[row].id
            } else if pickerView == userBankAccountPickerView {
                let americanAccounts = currentUser.accounts.filter({$0.id.last?.description == "1"})
                if !americanAccounts.isEmpty {
                    userBankAccountTextField.text = americanAccounts[row].id
                } else {
                    AlertManager.shared.showAlert(parent: self, title: "No American account", body: "Please add one if you want to pay your bills", buttonTitles: ["Create one"]) { [self] buttonIndex in
                        if buttonIndex == 0 {
                            showCreateAccount()
                        }
                    }
                }
            }
        }
    }
}

//MARK: - TextField Functions
extension BillViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let americanAccounts = currentUser?.accounts.filter({$0.id.last?.description == "1"})
        
        if textField == payeeNameTextField && textField.text == "" {
            if let payees = currentUser?.payees, payees.count > 0 {
                textField.text = payees[0].title
                payeeAccountNumberTextField.text = currentUser?.payees[0].id
            }
        } else if textField == userBankAccountTextField && textField.text == "" && americanAccounts == [] {
            view.endEditing(true)
            AlertManager.shared.showAlert(parent: self, title: "No American account", body: "Please add one if you want to pay your bills", buttonTitles: ["Create one"], style: .alert) { [self] buttonIndex in
                if buttonIndex == 0 {
                    showCreateAccount()
                }
            }
        } else if textField == userBankAccountTextField && textField.text == "" {
            if let payees = currentUser?.payees, payees.count > 0 {
                textField.text = americanAccounts?[0].id
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        var maxLength = 10
        
        switch textField {
        case payeeNameTextField, userBankAccountTextField: return false
        case payeeAccountNumberTextField: maxLength = 11
            return newString.length <= maxLength && ValidationRule.amount.isValidAmount(text: payeeAccountNumberTextField.text!)
        case amountTextField:
            return newString.length <= maxLength
        default: return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case payeeNameTextField:
            payeeAccountNumberTextField.becomeFirstResponder()
        case payeeAccountNumberTextField:
            userBankAccountTextField.becomeFirstResponder()
        case userBankAccountTextField:
            amountTextField.becomeFirstResponder()
        case amountTextField:
            payAction()
        default: break
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Keyboard Functions
private extension BillViewController {
    
    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.payButtonBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

//MARK: - Actions
private extension BillViewController {
    
    func isEntriesValid()-> Bool {
        
        if amountTextField.text!.isEmpty && userBankAccountTextField.text!.isEmpty && payeeNameTextField.text!.isEmpty && payeeAccountNumberTextField.text!.isEmpty {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
            return false
        }
        let isAmericanAccounts = userBankAccountTextField.text!.last?.description == "1"
        let isAmountValid = ValidationRule.amount.isValidAmount(text: amountTextField.text!)
        let isBankAccountValid = ValidationRule.bankID.isValidBankID(id: userBankAccountTextField.text!) && isAmericanAccounts
        
        if isBankAccountValid && isAmountValid && !payeeNameTextField.text!.isEmpty && !payeeAccountNumberTextField.text!.isEmpty {
            return true
        } else if !isAmericanAccounts && !userBankAccountTextField.text!.isEmpty {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please only use American account", style: .danger)
            return false
        }
        return false
    }
    
    func payBill(for account: Account, transaction: Transaction, updatedBalance: Double) {
        let user = currentUser
        allUsers = UserDefaults.standard.retrieveUsers()
        currentUser = allUsers.filter({$0.personalInfo == user!.personalInfo}).first
        
        for i in 0..<(currentUser?.accounts.count ?? 0) {
            if currentUser?.accounts[i].id == account.id {
                currentUser?.accounts[i].balance = updatedBalance
                currentUser?.accounts[i].transactions.append(transaction)
                let sortedTransactions = currentUser?.accounts[i].transactions.sorted(by: {$0.date > $1.date})
                currentUser?.accounts[i].transactions = sortedTransactions ?? []
                break
            }
        }
    }
    
    func payAction() {
        if isEntriesValid() {
            submitTransaction()
        }
    }
    
    func submitTransaction() {
        if let userAccountID = userBankAccountTextField.text, !userAccountID.isEmpty {
            let selectedAccount = currentUser?.accounts.filter({$0.id == userAccountID}).first
            let payee = payeeNameTextField.text!
            let billAmount = Double(amountTextField.text!) ?? 0
            let newBalance = selectedAccount!.balance - billAmount
            let transactionReceiver = TransactionReceiver(title: payee, id: payeeAccountNumberTextField.text!)
            if newBalance >= 0 {
                let transactionID = Int.random(in: 100000000...999999999).description
                let transaction = Transaction(date: Date(), amount: Double(billAmount), type: .outcome, reason: .bill, id: transactionID, receiver: transactionReceiver)
                
                showPaymentPromptAlert(amount: billAmount.description, payee: payee) { [self] buttonIndex in
                    if buttonIndex == 0 {
                        if let account = selectedAccount {
                            payBill(for: account, transaction: transaction, updatedBalance: newBalance)
                        }
                        saveAccount(user: currentUser!)
                        showDashboardViewController()
                        BannerManager.showMessage(messageText: "Success!", messageSubtitle: "The payee transaction submitted successfully. \n You can check it in Dashboard tab", style: .success)
                        showDashboardViewController()
                    } else {
                        BannerManager.showMessage(messageText: "Canceled", messageSubtitle: "Your Transaction canceled.", style: .danger)
                    }
                }
            } else {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Due to insufficient balance, Transaction failed.", style: .danger)
            }
        }
    }
    
    private func showPaymentPromptAlert(amount: String, payee: String, completion: @escaping (Int?) -> ()) {
        let alertTitle = "Notice"
        let body = "You're paying \"\(amount)\" $ to \"\(payee)\". \n Are you sure?"
        AlertManager.shared.showAlert(parent: self, title: alertTitle, body: body, buttonTitles: ["OK"], style: .alert, completion: completion)
    }
}

//MARK: - Navigation Functions
extension BillViewController {
    
    func showDashboardViewController() {
        tabBarController?.selectedIndex = 0
    }
    
    func showCreateAccount() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "AddAccountViewController") as! AddAccountViewController
        navigationController?.present(viewController, animated: true)
    }
}
