import UIKit
import AWSPluginsCore
import Amplify
import MarqueeLabel

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var greetingLabel: MarqueeLabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    var currentUser: User?
    let collectionViewCellMargin: CGFloat = 16
    
    var collectionViewCellSize: CGSize {
        let margins = collectionViewCellMargin * 3
        let cellWidth = (UIScreen.main.bounds.width - margins)
        let cellHeight = cellWidth / 2
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    var collectionViewCurrentCellIndex: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //        let user = currentUser
    //        allUsers = UserDefaults.standard.retrieveUsers()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            do {
                let authUser = try await Amplify.Auth.getCurrentUser() // ❗ بدون optional
                let userSub = authUser.userId
                print("✅ userSub:", userSub)
                
                NetworkManager.shared.getUser(by: userSub) { result in
                    switch result {
                    case .success(let userFromServer):
                        self.currentUser = userFromServer
                        DispatchQueue.main.async {
                            self.setupViews()
                        }
                    case .failure(let error):
                        print("❌ خطا در دریافت کاربر:", error.localizedDescription)
                    }
                }
            } catch {
                print("❌ خطا در گرفتن کاربر از Amplify:", error.localizedDescription)
            }
        }
    }
}

//MARK: - Setup Functions
private extension DashboardViewController {
    
    func setupViews() {
        setupNavigationController()
        setupBackgroundView()
        setupTableView()
        setupCollectionView()
        setupGreetingLabel()
    }
    
    func setupNavigationController() {
        tabBarController?.navigationItem.title = "Dashboard"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.hidesBackButton = true
        tabBarController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "exit"), style: .done, target: self, action: #selector(exitButton))
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+Account", style: .done, target: self, action: #selector(showCreateAccount))
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
    
    @objc private func exitButton() {
        DispatchQueue.main.async {
            AlertManager.shared.showAlert(parent: self, title: "Warning", body: "You are going to log out. \n Are you sure?", buttonTitles: ["Log out"], style: .alert) { buttonIndex in
                if buttonIndex == 0 {
                    self.tabBarController?.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    func setupBackgroundView() {
        if let accounts = currentUser?.accounts {
            backgroundView.isHidden = !accounts.isEmpty
            collectionView.isHidden = accounts.isEmpty
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: TableViewCell.identifier, bundle: nil), forCellReuseIdentifier: TableViewCell.identifier)
        tableView.separatorStyle = .none
        setupTableViewDataStatus()
    }
    
    private func setupTableViewDataStatus() {
        DispatchQueue.main.async {[self] in
            if let accounts = currentUser?.accounts {
                tableView.isHidden = accounts.isEmpty
            }
            if currentUser?.accounts.count != 0 {
                if let transactions = currentUser?.accounts[collectionViewCurrentCellIndex].transactions {
                    if transactions.isEmpty {
                        tableView.setEmptyMessage()
                    } else {
                        tableView.removeEmptyMessage()
                    }
                }
            } else {
                tableView.setEmptyMessage()
            }
        }
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: CollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: CollectionViewCell.identifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        scrollViewDidEndDecelerating(collectionView)
        scrollToNearestVisibleCollectionViewCell()
    }
    
    func setupGreetingLabel() {
        if let firstName = currentUser?.personalInfo.firstName {
            greetingLabel.text = getGreetingMessage() + " " + firstName
        }
        greetingLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
    }
    
    func getGreetingMessage()-> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<13 : return "Good Morning"
        case 13..<17 : return "Good Afternoon"
        case 17..<22 : return "Good Evening"
        default: return "Good Night"
        }
    }
}

//MARK: - TableView Functions
extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentUser?.accounts.count != 0 {
            if let account = currentUser?.accounts[collectionViewCurrentCellIndex] {
                return account.transactions.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.identifier, for: indexPath) as! TableViewCell
        let currencyUnit = currentUser?.accounts[collectionViewCurrentCellIndex].currency
        
        if let account = currentUser?.accounts[collectionViewCurrentCellIndex] {
            let transaction = account.transactions[indexPath.row]
            let config = TableViewCell.Config(date: transaction.date, amount: transaction.amount, type: transaction.type, currency: currencyUnit ?? .none, reason: transaction.reason, receiver: transaction.receiver)
            cell.setupCell(with: config)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

//MARK: - CollectionView Functions
extension DashboardViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentUser?.accounts.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.identifier, for: indexPath) as! CollectionViewCell
        
        if let account = currentUser?.accounts[indexPath.row] {
            let config = CollectionViewCell.Config(title: account.title, id: account.id, numberOfTransactions: account.transactions.count, totalBalance: account.balance, currency: account.currency, accountType: account.type, index: indexPath.row, delegate: self)
            cell.setupCell(config: config)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionViewCellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionViewCellMargin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionViewCellMargin
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollToNearestVisibleCollectionViewCell()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == collectionView {
            scrollToNearestVisibleCollectionViewCell()
        }
        let x = scrollView.contentOffset.x
        let margins = collectionViewCellMargin * 2.2
        let cellWidth = (UIScreen.main.bounds.width - margins)
        
        let currentIndex = Int(ceil(x/cellWidth))
        if currentIndex < currentUser?.accounts.count ?? 0 {
            DispatchQueue.main.async {[self] in
                tableView.reloadData()
                collectionView.reloadData()
                setupTableViewDataStatus()
            }
        }
    }
    
    func scrollToNearestVisibleCollectionViewCell() {
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + (collectionView.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<collectionView.visibleCells.count {
            let cell = collectionView.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = collectionView.indexPath(for: cell)!.row
                collectionViewCurrentCellIndex = closestCellIndex
                DispatchQueue.main.async {[self] in
                    tableView.reloadData()
                    collectionView.reloadData()
                    setupTableViewDataStatus()
                }
            }
        }
        if closestCellIndex != -1 {
            collectionView.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: true)
            collectionViewCurrentCellIndex = closestCellIndex
            DispatchQueue.main.async {[self] in
                tableView.reloadData()
                collectionView.reloadData()
                setupTableViewDataStatus()
            }
        }
    }
}

//MARK: - Delegate Functions
extension DashboardViewController: AddAccountViewControllerDelegate, CollectionViewCellDelegate {
    
    func informIfUserAddAccount() {
        DispatchQueue.main.async {[self] in
            setupBackgroundView()
            setupTableViewDataStatus()
            collectionView.reloadData()
            tableView.reloadData()
        }
    }
    
    func didSelectAccountEditButton(index: Int) {
        print("edit button at index \(index) pressed!")
        if (currentUser?.accounts) != nil {
            showEditAccount(accountIndex: index)
        }
    }
}

//MARK: - Navigation Functions
extension DashboardViewController {
    
    @objc func showCreateAccount() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "AddAccountViewController") as! AddAccountViewController
        viewController.delegate = self
        navigationController?.present(viewController, animated: true)
    }
    
    func showEditAccount(accountIndex: Int) {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "AddAccountViewController") as! AddAccountViewController
        viewController.isEditingMode = true
        viewController.accountIndex = accountIndex
        viewController.delegate = self
        navigationController?.present(viewController, animated: true)
    }
}
