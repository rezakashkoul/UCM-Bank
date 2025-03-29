import UIKit
import RxSwift
import RxKeyboard
import NotificationBannerSwift

protocol AddAccountViewControllerDelegate: AnyObject {
    func informIfUserAddAccount()
}

class AddAccountViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var accountTypeSegment: UISegmentedControl!
    @IBOutlet weak var currencySegment: UISegmentedControl!
    @IBOutlet weak var accountTitleTextField: UITextField!
    @IBOutlet weak var initialDepositLabel: UILabel!
    @IBOutlet weak var initialDepositTextField: UITextField!
    @IBOutlet weak var closeButton: UIButton!
    @IBAction private func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
    
    var disposeBag = DisposeBag()
    weak var delegate: AddAccountViewControllerDelegate?
    var isEditingMode: Bool = false
    var accountIndex: Int = 0
    var account: Account!
    let minimumDeposit = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.slideUpViews(delay: 0.05)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Setup Functions
private extension AddAccountViewController {
    
    func setupViews() {
        setupTextFields()
        setupButtons()
        handleKeyboardVisibility()
        initialDepositLabel.text = isEditingMode ? "Current Deposit" : "Initial Deposit"
    }
    
    func setupTextFields() {
        let username = currentUser?.personalInfo.firstName
        firstNameLabel.text = username
        initialDepositTextField.delegate = self
        accountTitleTextField.delegate = self
        accountTitleTextField.addDoneToolbar()
        initialDepositTextField.addDoneToolbar()
        if isEditingMode {
            accountTypeSegment.isEnabled = false
            currencySegment.isEnabled = false
            initialDepositTextField.isEnabled = false
            if let account = currentUser?.accounts[accountIndex] {
                accountTitleTextField.text = account.title
                currencySegment.selectedSegmentIndex = account.currency.getCurrencyIndex()
                accountTypeSegment.selectedSegmentIndex = account.type.getAccountTypeIndex()
                initialDepositTextField.text = account.balance.description
            }
        }
    }
    
    func setupButtons() {
        closeButton.setTitle("", for: .normal)
        closeButton.dropShadowAndCornerRadius(.large)
        submitButton.dropShadowAndCornerRadius(.regular)
    }
}

//MARK: - TextField Functions
extension AddAccountViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == accountTitleTextField {
            initialDepositTextField.becomeFirstResponder()
        }
        return true
    }
}

//MARK: - Keyboard Functions
extension AddAccountViewController {
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.submitButtonBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

//MARK: - Action Functions
private extension AddAccountViewController {
    
    func submitAction() {
        
        if initialDepositTextField.text!.isEmpty && accountTitleTextField.text!.isEmpty {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please fill all fields.", style: .danger)
            return
        }
        
        if isEntriesValid() {
            setAccountValues()
            saveAccount(user: currentUser!)
            if !isEditingMode {
                BannerManager.showMessage(messageText: "Success", messageSubtitle: "You're account with Account #:\(account.id) has been created successfully.", style: .success)
                print("Account with Account #:\(account.id) added successfully.")
            } else {
                BannerManager.showMessage(messageText: "Success", messageSubtitle: "You're account with Account #:\(account.id) has been updated successfully.", style: .success)
                print("Account with Account #:\(account.id) updated successfully.")
            }
            delegate?.informIfUserAddAccount()
            dismiss(animated: true)
        }
    }
    
    func setAccountValues() {
        let balance = Double(initialDepositTextField.text!) ?? 0
        let title = accountTitleTextField.text ?? ""
        let id = (isEditingMode ? currentUser?.accounts[accountIndex].id : getAccountID()) ?? "id error"
        
        let account = Account(id: id, title: title, type: getAccountType(), currency: getCurrency(), balance: balance, transactions: [])
        self.account = account
        if isEditingMode {
            currentUser?.accounts[accountIndex] = account
        } else {
            currentUser?.accounts.append(account)
        }
    }
    
    func getAccountType()-> AccountType {
        switch accountTypeSegment.selectedSegmentIndex {
        case 0: return .checking
        case 1: return .saving
        default: break
        }
        return .none
    }
    
    func getCurrency()-> Currency {
        switch currencySegment.selectedSegmentIndex {
        case 0: return .cad
        case 1: return .usd
        case 2: return .gbp
        case 3: return .eur
        default: break
        }
        return .none
    }
    
    func getAccountID()-> String {
        
        let prefixID = Int.random(in: 10000000...99999999).description
        var suffixID: String {
            switch currencySegment.selectedSegmentIndex {
            case 0: return "000"
            case 1: return "001"
            case 2: return "002"
            case 3: return "003"
            default: break
            }
            return ""
        }
        return prefixID + suffixID
    }
    
    func isEntriesValid()-> Bool {
        let title = accountTitleTextField.text!
        let deposit = initialDepositTextField.text!
        let isTitleValid = ValidationRule.none.isValid(text: title)
        let isMinimumInitialDepositValid = Double(deposit)?.toInt() ?? 0 >= minimumDeposit
        let isAmountValid = ValidationRule.amount.isValidAmount(text: Double(deposit)?.toInt()?.description ?? "") && isMinimumInitialDepositValid
        
        if  !isMinimumInitialDepositValid {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "You should at least add" + " \(minimumDeposit) \(getCurrency())".uppercased(), style: .warning)
            return false
        }
        
        if isTitleValid && isAmountValid && !title.isEmpty && !deposit.isEmpty {
            return true
        }
        return false
    }
}
