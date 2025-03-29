import UIKit
import RxSwift
import RxKeyboard
import NotificationBannerSwift

class PayeeViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var payeeNameTextField: UITextField!
    @IBOutlet weak var accountNumberTextField: UITextField!
    
    @IBOutlet weak var addPayeeButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var addPayeeButton: UIButton!
    @IBAction func addPayeeButtonAction(_ sender: Any) {
        addPayeeAction()
    }
    
    var disposeBag = DisposeBag()
    var textFields: [UITextField]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavigationController()
    }
    
}

//MARK: - Setup Functions
private extension PayeeViewController {
    
    func setupViews() {
        handleKeyboardVisibility()
        setupTextFields()
        addPayeeButton.dropShadowAndCornerRadius(.regular)
    }
    
    func setupNavigationController() {
        tabBarController?.navigationItem.hidesBackButton = true
        tabBarController?.navigationItem.largeTitleDisplayMode = .always
        tabBarController?.navigationItem.title = "Manage Payee"
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
    
    func setupTextFields() {
        textFields = view.getTextfields(view)
        textFields.forEach({$0.delegate = self})
        textFields.forEach({$0.addDoneToolbar()})
        payeeNameTextField.placeholder = "Please choose one payee"
        accountNumberTextField.placeholder = "Please set your payee ID."
        payeeNameTextField.becomeFirstResponder()
    }
}

//MARK: - Keyboard Functions
private extension PayeeViewController {
    
    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.addPayeeButtonBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

//MARK: - TextField Functions
extension PayeeViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        var maxLength = 10
        
        switch textField {
        case payeeNameTextField: maxLength = 30
            return newString.length <= maxLength
        case accountNumberTextField: maxLength = 11
            return newString.length <= maxLength
        default: return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case payeeNameTextField:
            accountNumberTextField.becomeFirstResponder()
        case accountNumberTextField:
            addPayeeAction()
        default: break
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Actions
private extension PayeeViewController {
    
    func addPayeeAction() {
        let title = payeeNameTextField.text ?? ""
        let id = accountNumberTextField.text ?? ""
        
        
        if title.isEmpty && id.isEmpty {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please fill all fields.", style: .danger)
            return
        }
        
        if isPayeeEntryValid(title: title, id: id) {
            if !isPayeeAvailable(title: title, id: id) {
                showAddingPayeeAlert(title: title, id: id) { [self] buttonIndex in
                    if buttonIndex == 0 {
                        let payee = Payee(title: title, id: id)
                        currentUser?.payees.append(payee)
                        saveAccount(user: currentUser!)
                        BannerManager.showMessage(messageText: "Success!", messageSubtitle: "The payee information submitted successfully. \n You can pay it in Bill tab", style: .success)
                        payeeNameTextField.text = ""
                        accountNumberTextField.text = ""
                    }
                }
            } else {
                BannerManager.showMessage(messageText: "Duplicated Payee!", messageSubtitle: "Please add another payee.", style: .warning)
            }
        }
    }
    
    private func showAddingPayeeAlert(title: String, id: String, completion: @escaping (Int?) -> ()) {
        let alertTitle = "Notice"
        let body = "You're adding \"\(title)\" with \"\(id)\" as a new payee. \n Are you sure?"
        AlertManager.shared.showAlert(parent: self, title: alertTitle, body: body, buttonTitles: ["OK"], style: .alert, completion: completion)
    }
    
    private func isPayeeEntryValid(title: String, id: String)-> Bool {
        let isValidID = ValidationRule.bankID.isValidPayeeID(id: id)
        return isValidTitle() && isValidID
    }
    
    private func isValidTitle()-> Bool {
        let title = payeeNameTextField.text ?? ""
        let isValidTitle = ValidationRule.textName.isValidTextName(text: title, shouldShowError: false)
        if !isValidTitle {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please check Payee name!", style: .danger)
            return false
        } else {
            return true
        }
    }
    
    func isPayeeAvailable(title: String, id: String)-> Bool {
        if let payees = currentUser?.payees {
            if !payees.filter({$0.id == id && $0.title == title}).isEmpty {
                return true
            } else {
                return false
            }
        }
        return false
    }
}
