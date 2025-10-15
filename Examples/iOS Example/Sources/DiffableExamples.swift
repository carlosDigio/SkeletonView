//  DiffableExamples.swift
//  iOS Example
//
//  Demonstrates usage of SkeletonDiffableTableViewDataSource and SkeletonDiffableCollectionViewDataSource
//  within the example app. These controllers are not wired in the storyboard by default; you can
//  instantiate and push them from existing UI (e.g., add a button) or set one as initial for quick testing.
//
//  Created for diffable integration showcase.

import UIKit
import SkeletonView

// MARK: - Table View Diffable Example
@available(iOS 13.0, *)
final class DiffableTableViewController: UIViewController {
    private enum Section: Hashable { case main }
    private struct Row: Hashable { let id = UUID(); let title: String }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var dataSource: SkeletonDiffableTableViewDataSource<Section, Row>!
    private var currentItems: [Row] = []
    private var didStartInitialLoad = false // ensures skeleton starts after first appearance

    private enum SkeletonStyle: Int { case solid = 0, gradient, multi }
    private enum LoadSpeed: Int { case fast = 0, slow }
    private var skeletonStyle: SkeletonStyle = .multi
    private var loadSpeed: LoadSpeed = .slow
    private let styleControl = UISegmentedControl(items: ["Solid","Grad","Multi"]) // style selector
    private let speedControl = UISegmentedControl(items: ["Fast","Slow"])             // speed selector

    private let minSkeletonVisible: TimeInterval = 0.6
    private var skeletonStartDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Diffable Table"
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(DiffableTableCell.self, forCellReuseIdentifier: DiffableTableCell.reuseID)
        tableView.isSkeletonable = true
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        dataSource = tableView.makeSkeletonDiffableDataSource(placeholderRows: 10, useInlinePlaceholders: true) { [weak self] tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: DiffableTableCell.reuseID, for: indexPath) as! DiffableTableCell
            cell.configure(title: item.title, subtitle: "Subtitle for \(item.title)")
            self?.view.layoutSkeletonIfNeeded()
            return cell
        }
        
        // Configure placeholder cells for skeleton display
        dataSource.configurePlaceholderCell = { [weak self] tv, indexPath in
            let cell = tv.dequeueReusableCell(withIdentifier: DiffableTableCell.reuseID, for: indexPath) as! DiffableTableCell
            // Keep the placeholder text so skeleton can render on the labels
            cell.titleLabel.text = "Loading placeholder text"
            cell.subtitleLabel.text = "Loading subtitle placeholder"
            // Show skeleton directly on the cell
            let gradient = self?.configureAndGetGradient() ?? SkeletonGradient(baseColor: .clouds)
            cell.showAnimatedGradientSkeleton(usingGradient: gradient, transition: .none)
            return cell
        }
        
        // Initialize with empty snapshot so skeleton can be displayed
        var initialSnapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        initialSnapshot.appendSections([.main])
        dataSource.apply(initialSnapshot, animatingDifferences: false)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Actions", style: .plain, target: self, action: #selector(showActions))
        configureControls()
    }

    private func configureControls() {
        styleControl.selectedSegmentIndex = skeletonStyle.rawValue
        speedControl.selectedSegmentIndex = loadSpeed.rawValue
        styleControl.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        speedControl.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        let stack = UIStackView(arrangedSubviews: [styleControl, speedControl])
        stack.axis = .horizontal
        stack.spacing = 8
        navigationItem.titleView = stack
    }

    @objc private func styleChanged() {
        skeletonStyle = SkeletonStyle(rawValue: styleControl.selectedSegmentIndex) ?? .multi
        updateSkeletonAppearanceIfNeeded()
    }
    @objc private func speedChanged() {
        loadSpeed = LoadSpeed(rawValue: speedControl.selectedSegmentIndex) ?? .slow
        // No immediate effect unless loading cycle restarts; offer restart if currently loading.
    }

    private func configureSkeletonAppearance() {
        // Adaptive base color per interface style for better contrast
        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseColor: UIColor
        switch skeletonStyle {
        case .solid:
            baseColor = isDark ? .belizeHole : .peterRiver
        case .gradient:
            baseColor = isDark ? .wisteria : .amethyst
        case .multi:
            baseColor = isDark ? .turquoise : .sunFlower
        }
        SkeletonAppearance.default.tintColor = baseColor
        switch skeletonStyle {
        case .solid:
            SkeletonAppearance.default.gradient = SkeletonGradient(baseColor: baseColor)
        case .gradient:
            // simple two/three-stop gradient from complementary
            let comp = baseColor.complementaryColor
            SkeletonAppearance.default.gradient = SkeletonGradient(colors: [baseColor, comp])
        case .multi:
            let comp = baseColor.complementaryColor
            SkeletonAppearance.default.gradient = SkeletonGradient(colors: [baseColor, comp, baseColor])
        }
    }
    
    private func configureAndGetGradient() -> SkeletonGradient {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseColor: UIColor
        switch skeletonStyle {
        case .solid:
            baseColor = isDark ? .belizeHole : .peterRiver
            return SkeletonGradient(baseColor: baseColor)
        case .gradient:
            baseColor = isDark ? .wisteria : .amethyst
            let comp = baseColor.complementaryColor
            return SkeletonGradient(colors: [baseColor, comp])
        case .multi:
            baseColor = isDark ? .turquoise : .sunFlower
            let comp = baseColor.complementaryColor
            return SkeletonGradient(colors: [baseColor, comp, baseColor])
        }
    }

    private func showSkeletonNow() {
        let gradient = SkeletonAppearance.default.gradient
        switch skeletonStyle {
        case .solid:
            tableView.showAnimatedSkeleton(usingColor: SkeletonAppearance.default.tintColor)
        case .gradient, .multi:
            tableView.showAnimatedGradientSkeleton(usingGradient: gradient)
        }
    }

    private func scheduleInitialFetch() {
        let delay: TimeInterval = (loadSpeed == .fast) ? 1.0 : 2.5
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.currentItems = (0..<12).map { Row(title: "Row \($0)") }
            var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
            snapshot.appendSections([.main])
            snapshot.appendItems(self.currentItems)
            DispatchQueue.main.async { self.handleFetched(snapshot) }
        }
    }
    private func handleFetched(_ snapshot: NSDiffableDataSourceSnapshot<Section, Row>) {
        let elapsed = Date().timeIntervalSince(skeletonStartDate ?? Date())
        let remaining = max(0, minSkeletonVisible - elapsed)
        if remaining == 0 { applyLoadedSnapshot(snapshot) } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { self.applyLoadedSnapshot(snapshot) }
        }
    }
    private func applyLoadedSnapshot(_ snapshot: NSDiffableDataSourceSnapshot<Section, Row>) {
        dataSource.endLoadingAndApply(snapshot)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartInitialLoad else { return }
        didStartInitialLoad = true
        configureSkeletonAppearance()
        skeletonStartDate = Date()
        dataSource.beginLoading(showSkeleton: false)
        tableView.reloadData() // Force reload to show inline placeholders
        // Apply skeleton to all visible cells after reload completes
        DispatchQueue.main.async {
            let gradient = self.configureAndGetGradient()
            for cell in self.tableView.visibleCells {
                if self.dataSource.isLoading {
                    cell.showAnimatedGradientSkeleton(usingGradient: gradient, transition: .none)
                }
            }
        }
        scheduleInitialFetch()
    }

    private func resetSkeleton() {
        currentItems.removeAll()
        configureSkeletonAppearance()
        skeletonStartDate = Date()
        dataSource.beginLoading(showSkeleton: false)
        var emptySnapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        emptySnapshot.appendSections([.main])
        dataSource.apply(emptySnapshot, animatingDifferences: false)
        tableView.reloadData()
        scheduleInitialFetch()
    }

    private func updateSkeletonAppearanceIfNeeded() {
        configureSkeletonAppearance()
        guard dataSource.isLoading else { return }
        // Update live animation without restarting layout
        switch skeletonStyle {
        case .solid:
            tableView.updateAnimatedSkeleton(usingColor: SkeletonAppearance.default.tintColor)
        case .gradient, .multi:
            tableView.updateAnimatedGradientSkeleton(usingGradient: SkeletonAppearance.default.gradient)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateSkeletonAppearanceIfNeeded()
        }
    }
    private func addRow() {
        currentItems.append(Row(title: "Row \(currentItems.count)"))
        applySnapshotFromCurrent()
    }
    private func removeRow() {
        guard !currentItems.isEmpty else { return }
        currentItems.removeLast()
        applySnapshotFromCurrent()
    }
    private func shuffleRows() {
        currentItems.shuffle()
        applySnapshotFromCurrent()
    }
    private func applySnapshotFromCurrent(animated: Bool = true) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.main])
        snapshot.appendItems(currentItems)
        dataSource.applySnapshot(snapshot, animatingDifferences: animated)
    }

    // Action sheet for demo interactions
    @objc private func showActions() {
        let alert = UIAlertController(title: "Table Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add Row", style: .default) { _ in self.addRow() })
        alert.addAction(UIAlertAction(title: "Remove Row", style: .default) { _ in self.removeRow() })
        alert.addAction(UIAlertAction(title: "Shuffle", style: .default) { _ in self.shuffleRows() })
        alert.addAction(UIAlertAction(title: "Reset Skeleton", style: .destructive) { _ in self.resetSkeleton() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Collection View Diffable Example
@available(iOS 13.0, *)
final class DiffableCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    private enum Section: Hashable { case main }
    private struct Item: Hashable { let id = UUID(); let title: String }
    
    private var collectionView: UICollectionView!
    private var dataSource: SkeletonDiffableCollectionViewDataSource<Section, Item>!
    private var items: [Item] = []
    private var didStartInitialLoad = false
    
    private enum SkeletonStyle: Int { case solid = 0, gradient, multi }
    private enum LoadSpeed: Int { case fast = 0, slow }
    private var skeletonStyle: SkeletonStyle = .multi
    private var loadSpeed: LoadSpeed = .slow
    private let styleControl = UISegmentedControl(items: ["Solid","Grad","Multi"])
    private let speedControl = UISegmentedControl(items: ["Fast","Slow"])
    
    private let minSkeletonVisible: TimeInterval = 0.6
    private var skeletonStartDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Diffable Collection"
        view.backgroundColor = .systemBackground
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.register(PlaceholderCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.isSkeletonable = true
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        dataSource = collectionView.makeSkeletonDiffableDataSource(placeholderItems: 40, useInlinePlaceholders: true) { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PlaceholderCell
            cell.configureContent(text: item.title)
            self?.view.layoutSkeletonIfNeeded()
            return cell
        }
        
        // Configure placeholder cells for skeleton display
        dataSource.configurePlaceholderCell = { [weak self] cv, indexPath in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PlaceholderCell
            cell.prepareForPlaceholder(at: indexPath.item)
            // Show skeleton directly on the cell
            let gradient = self?.configureAndGetGradient() ?? SkeletonGradient(baseColor: .clouds)
            cell.showAnimatedGradientSkeleton(usingGradient: gradient, transition: .none)
            return cell
        }
        
        // Set delegate for proper cell sizing
        collectionView.delegate = self
        
        // Initialize with empty snapshot so skeleton can be displayed
        var initialSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        initialSnapshot.appendSections([.main])
        dataSource.apply(initialSnapshot, animatingDifferences: false)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Actions", style: .plain, target: self, action: #selector(showActions))
        configureControls()
    }
    
    private func configureControls() {
        styleControl.selectedSegmentIndex = skeletonStyle.rawValue
        speedControl.selectedSegmentIndex = loadSpeed.rawValue
        styleControl.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        speedControl.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        let stack = UIStackView(arrangedSubviews: [styleControl, speedControl])
        stack.axis = .horizontal
        stack.spacing = 8
        navigationItem.titleView = stack
    }
    
    @objc private func styleChanged() { skeletonStyle = SkeletonStyle(rawValue: styleControl.selectedSegmentIndex) ?? .multi; updateSkeletonAppearanceIfNeeded() }
    @objc private func speedChanged() { loadSpeed = LoadSpeed(rawValue: speedControl.selectedSegmentIndex) ?? .slow }
    
    private func configureSkeletonAppearance() {
        // Adaptive base color per interface style for better contrast
        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseColor: UIColor
        switch skeletonStyle {
        case .solid: baseColor = isDark ? .belizeHole : .peterRiver
        case .gradient: baseColor = isDark ? .wisteria : .amethyst
        case .multi: baseColor = isDark ? .turquoise : .sunFlower
        }
        SkeletonAppearance.default.tintColor = baseColor
        switch skeletonStyle {
        case .solid: SkeletonAppearance.default.gradient = SkeletonGradient(baseColor: baseColor)
        case .gradient:
            let comp = baseColor.complementaryColor
            SkeletonAppearance.default.gradient = SkeletonGradient(colors: [baseColor, comp])
        case .multi:
            let comp = baseColor.complementaryColor
            SkeletonAppearance.default.gradient = SkeletonGradient(colors: [baseColor, comp, baseColor])
        }
    }
    
    private func configureAndGetGradient() -> SkeletonGradient {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseColor: UIColor
        switch skeletonStyle {
        case .solid:
            baseColor = isDark ? .belizeHole : .peterRiver
            return SkeletonGradient(baseColor: baseColor)
        case .gradient:
            baseColor = isDark ? .wisteria : .amethyst
            let comp = baseColor.complementaryColor
            return SkeletonGradient(colors: [baseColor, comp])
        case .multi:
            baseColor = isDark ? .turquoise : .sunFlower
            let comp = baseColor.complementaryColor
            return SkeletonGradient(colors: [baseColor, comp, baseColor])
        }
    }
    
    private func showSkeletonNow() {
        switch skeletonStyle {
        case .solid: collectionView.showAnimatedSkeleton(usingColor: SkeletonAppearance.default.tintColor)
        case .gradient, .multi: collectionView.showAnimatedGradientSkeleton(usingGradient: SkeletonAppearance.default.gradient)
        }
    }
    
    private func scheduleFetch() {
        let delay: TimeInterval = (loadSpeed == .fast) ? 1.0 : 2.0
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.items = (0..<40).map { Item(title: "Item \($0)") }
            var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems(self.items)
            DispatchQueue.main.async { self.handleFetched(snapshot) }
        }
    }
    private func handleFetched(_ snapshot: NSDiffableDataSourceSnapshot<Section, Item>) {
        let elapsed = Date().timeIntervalSince(skeletonStartDate ?? Date())
        let remaining = max(0, minSkeletonVisible - elapsed)
        if remaining == 0 { applyLoadedSnapshot(snapshot) } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { self.applyLoadedSnapshot(snapshot) }
        }
    }
    private func applyLoadedSnapshot(_ snapshot: NSDiffableDataSourceSnapshot<Section, Item>) {
        dataSource.endLoadingAndApply(snapshot)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartInitialLoad else { return }
        didStartInitialLoad = true
        configureSkeletonAppearance()
        skeletonStartDate = Date()
        dataSource.beginLoading(showSkeleton: false)
        collectionView.reloadData() // Force reload to show inline placeholders
        scheduleFetch()
    }
    
    private func resetSkeleton() {
        items.removeAll()
        configureSkeletonAppearance()
        skeletonStartDate = Date()
        dataSource.beginLoading(showSkeleton: false)
        var emptySnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        emptySnapshot.appendSections([.main])
        dataSource.apply(emptySnapshot, animatingDifferences: false)
        collectionView.reloadData()
        scheduleFetch()
    }
    @objc private func showActions() {
        let alert = UIAlertController(title: "Collection Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add Item", style: .default) { _ in self.addItem() })
        alert.addAction(UIAlertAction(title: "Remove Item", style: .default) { _ in self.removeItem() })
        alert.addAction(UIAlertAction(title: "Shuffle", style: .default) { _ in self.shuffleAll() })
        alert.addAction(UIAlertAction(title: "Reset Skeleton", style: .destructive) { _ in self.resetSkeleton() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    private func updateSkeletonAppearanceIfNeeded() {
        configureSkeletonAppearance()
        guard dataSource.isLoading else { return }
        switch skeletonStyle {
        case .solid: collectionView.updateAnimatedSkeleton(usingColor: SkeletonAppearance.default.tintColor)
        case .gradient, .multi: collectionView.updateAnimatedGradientSkeleton(usingGradient: SkeletonAppearance.default.gradient)
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateSkeletonAppearanceIfNeeded()
        }
    }

    // MARK: - Diffable mutation helpers (added)
    private func applySnapshotFromItems(animated: Bool = true) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.applySnapshot(snapshot, animatingDifferences: animated)
    }
    private func addItem() {
        items.append(Item(title: "Item \(items.count)"))
        applySnapshotFromItems()
    }
    private func removeItem() {
        guard !items.isEmpty else { return }
        items.removeLast()
        applySnapshotFromItems()
    }
    private func shuffleAll() {
        guard !items.isEmpty else { return }
        items.shuffle()
        applySnapshotFromItems()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16 - 16 - 12) / 2 // padding and spacing
        return CGSize(width: width, height: 120)
    }
}

// MARK: - Custom skeleton-friendly table cell (shared)
@available(iOS 13.0, *)
private final class DiffableTableCell: UITableViewCell {
    static let reuseID = "DiffableTableCell"
    
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    private let separatorView = UIView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        isSkeletonable = true
        contentView.isSkeletonable = true
        titleLabel.isSkeletonable = true
        subtitleLabel.isSkeletonable = true
        separatorView.isSkeletonable = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        titleLabel.linesCornerRadius = 8
        subtitleLabel.linesCornerRadius = 6
        // Add placeholder text so labels have size for skeleton
        titleLabel.text = "Loading placeholder text"
        subtitleLabel.text = "Loading subtitle placeholder"
        separatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.isSkeletonable = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        titleLabel.alpha = 1
        subtitleLabel.alpha = 1
        contentView.backgroundColor = .systemBackground
    }
    func configurePlaceholder(index: Int) {
        let titleLength = 8 + (index % 5)
        let subtitleLength = 20 + (index % 10)
        titleLabel.text = String(repeating: " ", count: titleLength)
        subtitleLabel.text = String(repeating: " ", count: subtitleLength)
        titleLabel.alpha = 0
        subtitleLabel.alpha = 0
        contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.55)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.alpha = 1
        subtitleLabel.alpha = 1
    }
}

// MARK: - Custom skeleton-friendly collection cell
@available(iOS 13.0, *)
private final class PlaceholderCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    private let contentLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isSkeletonable = true
        contentView.isSkeletonable = true
        contentView.backgroundColor = UIColor.secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        // Setup placeholder labels for skeleton
        titleLabel.isSkeletonable = true
        subtitleLabel.isSkeletonable = true
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        titleLabel.numberOfLines = 1
        subtitleLabel.numberOfLines = 1
        titleLabel.linesCornerRadius = 6
        subtitleLabel.linesCornerRadius = 5
        titleLabel.text = "Loading placeholder"
        subtitleLabel.text = "Loading subtitle"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup content label for real data
        contentLabel.isSkeletonable = false
        contentLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        contentLabel.textColor = .label
        contentLabel.numberOfLines = 2
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.isHidden = true
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isSkeletonable = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        contentView.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),
            
            contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),
            contentLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func prepareForPlaceholder(at index: Int) {
        contentLabel.isHidden = true
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        titleLabel.text = "Loading placeholder text"
        subtitleLabel.text = "Loading subtitle"
        contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.55)
    }
    
    func configureContent(text: String) {
        contentLabel.text = text
        contentLabel.isHidden = false
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        contentView.backgroundColor = UIColor.secondarySystemBackground
    }
    
    func configure(text: String) { configureContent(text: text) }
}
