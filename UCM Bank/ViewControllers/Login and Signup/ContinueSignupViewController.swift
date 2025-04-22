import UIKit
import RxSwift
import RxKeyboard

class ContinueSignupViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var ssnTextField: UITextField!
    @IBOutlet weak var telTextField: UITextField!
    @IBOutlet weak var unitNumberTextField: UITextField!
    @IBOutlet weak var streetNumberTextField: UITextField!
    @IBOutlet weak var streetNameTextField: UITextField!
    @IBOutlet weak var postalCodeTextField: UITextField!
    @IBOutlet weak var provinceTextField: UITextField!
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: UIButton!

    var username: String = "" // 💡 Set from SignupEmailConfirmationViewController
    var disposeBag = DisposeBag()
    var textFields: [UITextField] = []
    let pickerView = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.slideLeftViews(delay: 0.1)
    }

    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
}

// MARK: - Setup
private extension ContinueSignupViewController {

    func setupViews() {
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Continue Signup"

        handleKeyboardVisibility()
        hideKeyboardOnTap(#selector(dismissKeyboard))

        textFields = [firstNameTextField, lastNameTextField, ssnTextField, telTextField,
                      unitNumberTextField, streetNumberTextField, streetNameTextField,
                      postalCodeTextField, provinceTextField]

        textFields.forEach {
            $0.delegate = self
            $0.addDoneToolbar()
        }

        submitButton.dropShadowAndCornerRadius(.regular)
        provinceTextField.inputView = pickerView
        provinceTextField.text = "State"
        pickerView.delegate = self
        pickerView.dataSource = self
    }

    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                self.submitButtonBottomConstraint.constant = height == 0 ? 20 : height
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Validation & Submission
private extension ContinueSignupViewController {

    func areFieldsValid() -> Bool {
        if textFields.contains(where: { $0.text?.isEmpty ?? true }) {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please fill all fields", style: .danger)
            return false
        }
        return true
    }

    func submitAction() {
        view.endEditing(true)
        guard areFieldsValid() else { return }

        let data: [String: Any] = [
            "username": username.lowercased(),
            "password": "N/A", // چون با Cognito ثبت‌نام شده
            "first_name": firstNameTextField.text!,
            "last_name": lastNameTextField.text!,
            "ssn": ssnTextField.text!,
            "phone": telTextField.text!,
            "unit_number": unitNumberTextField.text!,
            "street_number": streetNumberTextField.text!,
            "street_name": streetNameTextField.text!,
            "postal_code": postalCodeTextField.text!,
            "province": provinceTextField.text!
        ]

        NetworkManager.shared.postRequest(endpoint: "addUser", body: data) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    BannerManager.showMessage(messageText: "Success", messageSubtitle: "Proceed to security questions.", style: .success)
                    self.showSecurityQuestion()
                case .failure(let error):
                    BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
                }
            }
        }
    }

    func showSecurityQuestion() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SecurityQuestionViewController") as! SecurityQuestionViewController
        vc.isUserSigningUp = true
        vc.username = username
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ContinueSignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let index = textFields.firstIndex(of: textField), index + 1 < textFields.count {
            textFields[index + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == provinceTextField && textField.text == "State" {
            textField.text = provinces.first
        }
    }
}

// MARK: - UIPickerViewDelegate/DataSource
extension ContinueSignupViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return provinces.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return provinces[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        provinceTextField.text = provinces[row]
    }
}
