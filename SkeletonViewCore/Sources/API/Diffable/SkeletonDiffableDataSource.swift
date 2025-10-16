//  SkeletonDiffableDataSource.swift
//  SkeletonView
//
//  Created for Diffable DataSource support.
//
//  This file adds integration helpers to use SkeletonView seamlessly with UITableViewDiffableDataSource.
//  It provides a subclass that coordinates the skeleton lifecycle with diffable snapshots
//  so you can show a skeleton while loading and automatically hide it after applying the first non-empty snapshot.
//
//  NOTE: This is additive and does not modify existing public APIs.
//
//  Usage example:
//  enum Section { case main }
//  struct Row: Hashable { let id = UUID(); let title: String }
//  let ds = SkeletonDiffableTableViewDataSource<Section, Row>(tableView: tableView) { tableView, indexPath, item in
//      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//      cell.isSkeletonable = true
//      cell.textLabel?.text = item.title
//      return cell
//  }
//  ds.beginLoading() // shows skeleton
//  // After fetching data:
//  var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
//  snapshot.appendSections([.main])
//  snapshot.appendItems(items)
//  ds.endLoadingAndApply(snapshot)

#if canImport(UIKit)
import UIKit

@available(iOS 13.0, tvOS 13.0, *)
public protocol AnySkeletonDiffableTableDataSource: SkeletonTableViewDataSource {}

@available(iOS 13.0, tvOS 13.0, *)
public final class SkeletonDiffableTableViewDataSource<SectionID: Hashable, ItemID: Hashable>: UITableViewDiffableDataSource<SectionID, ItemID>, SkeletonTableViewDataSource, AnySkeletonDiffableTableDataSource {
    // Indicates whether we are currently in loading (skeleton) state.
    public private(set) var isLoading: Bool = false
    // Placeholder row count (only used when developer wants inline placeholders without swapping to Skeleton's dummy data source).
    private var placeholderRowCount: Int
    // Optional closure to configure a placeholder cell when using inline placeholders.
    public var configurePlaceholderCell: ((UITableView, IndexPath) -> UITableViewCell)?
    // Internal toggle: whether inline placeholders are enabled. If a skeleton is shown via SkeletonView, dummy data source takes precedence.
    private let useInlinePlaceholders: Bool
    // Weak reference to the host table view (mirrors collection variant to avoid ambiguity and for symmetry).
    private weak var hostTableViewRef: UITableView?

    // MARK: - Init
    public init(tableView hostTableView: UITableView,
                placeholderRowCount: Int = 30,
                useInlinePlaceholders: Bool = false,
                cellProvider: @escaping UITableViewDiffableDataSource<SectionID, ItemID>.CellProvider) {
        self.placeholderRowCount = placeholderRowCount
        self.useInlinePlaceholders = useInlinePlaceholders
        self.hostTableViewRef = hostTableView
        super.init(tableView: hostTableView, cellProvider: cellProvider)
        if useInlinePlaceholders {
            // Ensure a basic placeholder cell is registered to avoid crashes if user forgets.
            hostTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SkeletonPlaceholderCell")
        }
    }

    // MARK: - Loading lifecycle

    /// Starts loading mode and optionally shows skeleton.
    /// - Parameter showSkeleton: When true, shows skeleton automatically. Safe for diffable datasources.
    public func beginLoading(showSkeleton: Bool = true) {
        guard !isLoading else { return }
        isLoading = true
        
        // Show skeleton if requested - safe for diffable datasources since we maintain the same dataSource
        if showSkeleton {
            if useInlinePlaceholders {
                // For inline placeholders, we just need to reload to show placeholder cells
                let empty = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
                apply(empty, animatingDifferences: false)
            } else {
                // For traditional skeleton overlay, show it directly
                hostTableViewRef?.showAnimatedSkeleton()
            }
        }
    }

    /// Marks the end of loading. You should call `endLoadingAndApply(_:)` to both end loading and apply the snapshot.
    public func endLoading() {
        isLoading = false
    }

    /// Convenience to end loading and apply a snapshot in a single call.
    /// - Parameters:
    ///   - snapshot: The snapshot to apply.
    ///   - animatingDifferences: Animation flag.
    ///   - completion: Completion executed after snapshot is applied and skeleton hidden (if needed).
    public func endLoadingAndApply(_ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
                                   animatingDifferences: Bool = true,
                                   completion: (() -> Void)? = nil) {
        endLoading()
        applySnapshot(snapshot, animatingDifferences: animatingDifferences, completion: completion)
    }

    /// Resets the data source into a fresh loading state and (optionally) shows the skeleton again.
    /// Call this if you need to re-run a loading cycle (e.g. pull-to-refresh that wants the skeleton back).
    /// - Parameters:
    ///   - keepSections: When true, existing section identifiers are preserved (emptied of items) so layout/sticky headers remain.
    ///   - showSkeleton: If true (default) triggers `showAnimatedSkeleton()` immediately.
    ///   - animatingDifferences: Whether to animate the transition to the empty snapshot (default false for a crisp reset).
    public func resetAndShowSkeleton(keepSections: Bool = true,
                                     showSkeleton: Bool = true,
                                     animatingDifferences: Bool = false) {
        let performReset = { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            if showSkeleton { self.hostTableViewRef?.showAnimatedSkeleton() }
            var newSnapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()
            if keepSections {
                let sections = self.snapshot().sectionIdentifiers
                if !sections.isEmpty { newSnapshot.appendSections(sections) }
            }
            self.applySnapshot(newSnapshot, animatingDifferences: animatingDifferences)
        }
        if Thread.isMainThread { performReset() } else { DispatchQueue.main.async(execute: performReset) }
    }

    /// Applies a snapshot coordinating with skeleton visibility.
    /// - If still loading and the snapshot is empty, it is applied but skeleton remains.
    /// - If loading has ended or snapshot has items, skeleton is hidden after applying.
    public func applySnapshot(_ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
                              animatingDifferences: Bool = true,
                              completion: (() -> Void)? = nil) {
        let work = { [weak self] in
            guard let self = self else { return }
            // Reasignar el dataSource original diffable si fue reemplazado por el dummy skeleton
            if let tv = self.hostTableViewRef, tv.dataSource !== self {
                tv.dataSource = self
            }
            self.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
                guard let self = self else { return }
                let isEmpty = snapshot.numberOfItems == 0
                if self.isLoading && !isEmpty { self.isLoading = false }
                if !self.isLoading { self.hostTableViewRef?.hideSkeleton(reloadDataAfter: false) }
                completion?()
            }
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    // MARK: - Inline placeholder support (optional)
    // Inline placeholders allow showing a lightweight set of rows during loading WITHOUT switching
    // the tableView dataSource to the internal SkeletonView dummy provider. This is handy when you
    // want diffable section structure to be known up-front (e.g. to reserve header heights) while still
    // presenting the shimmer effect. Enable by passing `useInlinePlaceholders: true` in the factory/init.
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if useInlinePlaceholders && isLoading && snapshot().numberOfItems == 0 { return placeholderRowCount }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if useInlinePlaceholders && isLoading && snapshot().numberOfItems == 0 {
            if let configured = configurePlaceholderCell?(tableView, indexPath) { return configured }
            let cell = tableView.dequeueReusableCell(withIdentifier: "SkeletonPlaceholderCell") ?? UITableViewCell(style: .default, reuseIdentifier: "SkeletonPlaceholderCell")
            cell.isSkeletonable = true
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    // MARK: - SkeletonTableViewDataSource
    public func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    
    public func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeholderRowCount
    }
    
    public func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "DiffableTableCell"
    }
}

@available(iOS 13.0, tvOS 13.0, *)
public extension UITableView {
    /// Convenience factory that sets the dataSource and returns the diffable data source ready for skeleton usage.
    /// - Parameters:
    ///   - placeholderRows: Number of inline placeholder rows (only used if `useInlinePlaceholders` is true).
    ///   - useInlinePlaceholders: When true, shows placeholder rows instead of calling the SkeletonView dummy data source (skeleton still can be shown for shimmer effect).
    ///   - cellProvider: Standard diffable cell provider.
    func makeSkeletonDiffableDataSource<SectionID: Hashable, ItemID: Hashable>(
        placeholderRows: Int = 5,
        useInlinePlaceholders: Bool = false,
        cellProvider: @escaping UITableViewDiffableDataSource<SectionID, ItemID>.CellProvider,
    ) -> SkeletonDiffableTableViewDataSource<SectionID, ItemID> {
        let ds = SkeletonDiffableTableViewDataSource<SectionID, ItemID>(tableView: self,
                                                                        placeholderRowCount: placeholderRows,
                                                                        useInlinePlaceholders: useInlinePlaceholders,
                                                                        cellProvider: cellProvider)
        self.dataSource = ds
        return ds
    }
    
    // MARK: - Convenient Skeleton Diffable Methods
    
    /// Starts loading and shows skeleton if the current dataSource is a SkeletonDiffableTableViewDataSource
    /// - Parameter showSkeleton: Whether to show the skeleton automatically (default: true)
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func beginSkeletonLoading(showSkeleton: Bool = true) -> Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableTableViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        skeletonDataSource.beginLoading(showSkeleton: showSkeleton)
        return true
    }
    
    /// Ends loading if the current dataSource is a SkeletonDiffableTableViewDataSource
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func endSkeletonLoading() -> Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableTableViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        skeletonDataSource.endLoading()
        return true
    }
    
    /// Ends loading and applies snapshot if the current dataSource is a SkeletonDiffableTableViewDataSource
    /// - Parameters:
    ///   - snapshot: The snapshot to apply
    ///   - animatingDifferences: Whether to animate the changes
    ///   - completion: Completion closure
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func endSkeletonLoadingAndApply<SectionID: Hashable, ItemID: Hashable>(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionID, ItemID>,
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil) -> Bool {
        
        guard let skeletonDataSource = dataSource as? SkeletonDiffableTableViewDataSource<SectionID, ItemID> else {
            return false
        }
        skeletonDataSource.endLoadingAndApply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        return true
    }
    
    /// Resets and shows skeleton if the current dataSource is a SkeletonDiffableTableViewDataSource
    /// - Parameters:
    ///   - keepSections: Whether to preserve existing sections
    ///   - showSkeleton: Whether to show skeleton immediately
    ///   - animatingDifferences: Whether to animate the transition
    /// - Returns: true if operation was successful, false if dataSource is not a skeleton diffable dataSource
    @discardableResult
    func resetAndShowSkeleton(keepSections: Bool = true,
                              showSkeleton: Bool = true,
                              animatingDifferences: Bool = false) -> Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableTableViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        skeletonDataSource.resetAndShowSkeleton(keepSections: keepSections,
                                               showSkeleton: showSkeleton,
                                               animatingDifferences: animatingDifferences)
        return true
    }
    
    /// Checks if the current dataSource is in loading state
    var isSkeletonLoading: Bool {
        guard let skeletonDataSource = dataSource as? SkeletonDiffableTableViewDataSource<AnyHashable, AnyHashable> else {
            return false
        }
        return skeletonDataSource.isLoading
    }
}

#endif
