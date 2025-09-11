//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Görkem Öztürk  on 9.09.2025.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    
    private let appGroupId = "group.com.office701.articapital" // App Group
    private let userDefaultsKey = "ShareMedia" // receive_sharing_intent key
    
    private var accountName: String = ""
    private var selectedFolder: String = "Proje1"
    private var shareWith: String = "Kişi ve grup ekle"
    private var noteText: String = ""
    
    // UI Elements
    private let containerView = UIView()
    private let headerView = UIView()
    private let headerBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let titleLabel = UILabel()
    private let cancelButton = UIButton()
    private let shareButton = UIButton()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let noteTextView = UITextView()
    private let optionsStackView = UIStackView()
    private let buttonsContainerView = UIView()
    private let buttonsStackView = UIStackView()
    private let sendProjectButton = UIButton(type: .system)
    private let sendMessageButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let ud = UserDefaults(suiteName: appGroupId)
        accountName = ud?.string(forKey: "LoggedInUserName") ?? ""
        
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Büyük bottom sheet görünümü için boyutları ayarla
        if let presentationController = presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.selectedDetentIdentifier = .medium
            presentationController.prefersGrabberVisible = true
        } else {
            // Fallback için manuel boyut ayarı
            preferredContentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 0.6)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Container View
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.addSubview(containerView)
        
        // Header
        headerView.backgroundColor = .clear
        headerView.addSubview(headerBlurView)
        containerView.addSubview(headerView)
        
        // Title
        titleLabel.text = "Arti Capital"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        // Cancel Button
        cancelButton.setTitle("İptal", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        headerView.addSubview(cancelButton)
        
        // Share Button
        shareButton.setTitle("Paylaş", for: .normal)
        shareButton.setTitleColor(.systemBlue, for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        headerView.addSubview(shareButton)
        
        // Scroll View
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .always
        containerView.addSubview(scrollView)
        
        // Content View
        scrollView.addSubview(contentView)
        
        // Note Text View (İsteğe bağlı not ekleme)
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.cornerRadius = 10
        noteTextView.font = .systemFont(ofSize: 16)
        noteTextView.backgroundColor = .secondarySystemBackground
        noteTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        noteTextView.text = "Not ekle..."
        noteTextView.textColor = .placeholderText
        noteTextView.delegate = self
        contentView.addSubview(noteTextView)
        
        // Options Stack View
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 8
        optionsStackView.backgroundColor = .clear
        contentView.addSubview(optionsStackView)
        
        // Buttons Container
        buttonsContainerView.backgroundColor = .systemBackground
        containerView.addSubview(buttonsContainerView)

        // Buttons Stack
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 10
        buttonsContainerView.addSubview(buttonsStackView)

        // Send Project Button (üstte)
        var configPrimary = UIButton.Configuration.filled()
        configPrimary.cornerStyle = .large
        configPrimary.baseBackgroundColor = .systemBlue
        configPrimary.baseForegroundColor = .white
        configPrimary.title = "Proje olarak gönder"
        sendProjectButton.configuration = configPrimary
        sendProjectButton.addTarget(self, action: #selector(shareAsProjectTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(sendProjectButton)

        // Send Message Button (altta)
        var configSecondary = UIButton.Configuration.gray()
        configSecondary.cornerStyle = .large
        configSecondary.baseBackgroundColor = .secondarySystemBackground
        configSecondary.baseForegroundColor = .label
        configSecondary.title = "Mesaj olarak gönder"
        sendMessageButton.configuration = configSecondary
        sendMessageButton.addTarget(self, action: #selector(shareAsMessageTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(sendMessageButton)

        setupOptions()
    }
    
    private func setupOptions() {
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Hesap seçeneği
        let accountOption = createOptionRow(
            title: "Firma",
            value: accountName.isEmpty ? "Giriş yapılmadı" : accountName,
            icon: "person.circle"
        ) { [weak self] in
            self?.showAccountOptions()
        }
        optionsStackView.addArrangedSubview(accountOption)
        
        // Projeler seçeneği
        let folderOption = createOptionRow(
            title: "Projeler",
            value: selectedFolder,
            icon: "folder"
        ) { [weak self] in
            self?.showFolderOptions()
        }
        optionsStackView.addArrangedSubview(folderOption)
        
        // Paylaşım seçeneği
        let shareOption = createOptionRow(
            title: "Belge Türü",
            value: shareWith,
            icon: "person.2"
        ) { [weak self] in
            self?.showShareOptions()
        }
        optionsStackView.addArrangedSubview(shareOption)
    }
    
    private func createOptionRow(title: String, value: String, icon: String, action: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let button = UIButton()
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        container.addSubview(button)

        let iconBackground = UIView()
        iconBackground.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        iconBackground.layer.cornerRadius = 18
        container.addSubview(iconBackground)

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        container.addSubview(iconImageView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .label
        container.addSubview(titleLabel)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 1
        container.addSubview(valueLabel)

        let chevronImageView = UIImageView()
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        container.addSubview(chevronImageView)

        let separator = UIView()
        separator.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        container.addSubview(separator)

        // Auto Layout
        [button, iconBackground, iconImageView, titleLabel, valueLabel, chevronImageView, separator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            iconBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 36),
            iconBackground.heightAnchor.constraint(equalToConstant: 36),

            iconImageView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 18),

            valueLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -10),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            container.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Store action in button tag or associated object
        objc_setAssociatedObject(button, "action", action, .OBJC_ASSOCIATION_RETAIN)

        return container
    }
    
    @objc private func optionTapped(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let action = objc_getAssociatedObject(sender, "action") as? () -> Void {
            action()
        }
    }
    
    private func setupConstraints() {
        [containerView, headerView, headerBlurView, titleLabel, cancelButton, shareButton, scrollView, contentView, noteTextView, optionsStackView, buttonsContainerView, buttonsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            // Header Blur fills header
            headerBlurView.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerBlurView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerBlurView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerBlurView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Cancel Button
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Share Button
            shareButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            shareButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Buttons Container (bottom)
            buttonsContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonsContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonsContainerView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),

            buttonsStackView.topAnchor.constraint(equalTo: buttonsContainerView.topAnchor, constant: 10),
            buttonsStackView.leadingAnchor.constraint(equalTo: buttonsContainerView.leadingAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: buttonsContainerView.trailingAnchor, constant: -16),
            buttonsStackView.bottomAnchor.constraint(equalTo: buttonsContainerView.bottomAnchor, constant: -10),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonsContainerView.topAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Options Stack View
            optionsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            optionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Note Text View (alta, butonların üstünde)
            noteTextView.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 16),
            noteTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noteTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            noteTextView.heightAnchor.constraint(equalToConstant: 96),
            noteTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Button Actions
    @objc private func cancelTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0, userInfo: nil))
    }
    
    @objc private func shareTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        collectItems { [weak self] result in
            guard let self else { return }
            
            var payload: [String: Any] = [
                "items": result,
                "type": "share",
            ]
            
            if !self.noteText.isEmpty && self.noteText != "Not ekle..." {
                payload["text"] = self.noteText
            }
            
            payload["account"] = self.accountName
            payload["folder"] = self.selectedFolder
            payload["shareWith"] = self.shareWith
            
            let ud = UserDefaults(suiteName: self.appGroupId)
            ud?.set(payload, forKey: self.userDefaultsKey)
            ud?.synchronize()
            
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.openHostApp()
                }
            })
        }
    }

    @objc private func shareAsProjectTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        share(withMode: "project")
    }

    @objc private func shareAsMessageTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        share(withMode: "message")
    }

    private func share(withMode mode: String) {
        collectItems { [weak self] result in
            guard let self else { return }
            var payload: [String: Any] = [
                "items": result,
                "type": "share",
                "mode": mode,
            ]
            if !self.noteText.isEmpty && self.noteText != "Not ekle..." {
                payload["text"] = self.noteText
            }
            payload["account"] = self.accountName
            payload["folder"] = self.selectedFolder
            payload["shareWith"] = self.shareWith
            let ud = UserDefaults(suiteName: self.appGroupId)
            ud?.set(payload, forKey: self.userDefaultsKey)
            ud?.synchronize()
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.openHostApp()
                }
            })
        }
    }
    
    // MARK: - Option Methods
    private func showAccountOptions() {
        let accounts = buildAccounts()
        showActionSheet(title: "Hesap Seç", options: accounts) { [weak self] selectedAccount in
            if let account = selectedAccount {
                self?.accountName = account
                self?.setupOptions()
            }
        }
    }
    
    private func showFolderOptions() {
        let folders = ["Drive'ım", "Belgeler", "İndirilenler"]
        showActionSheet(title: "Klasör Seç", options: folders) { [weak self] selectedFolder in
            if let folder = selectedFolder {
                self?.selectedFolder = folder
                self?.setupOptions()
            }
        }
    }
    
    private func showShareOptions() {
        let shareOptions = ["Kişi ve grup ekle", "Sadece ben", "Ekip"]
        showActionSheet(title: "Paylaşım Türü", options: shareOptions) { [weak self] selectedOption in
            if let option = selectedOption {
                self?.shareWith = option
                self?.setupOptions()
            }
        }
    }
    
    private func showActionSheet(title: String, options: [String], completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for option in options {
            let action = UIAlertAction(title: option, style: .default) { _ in
                completion(option)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel) { _ in
            completion(nil)
        }
        alertController.addAction(cancelAction)
        
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
    
    // Basit hesap listesi üretir. İleride gerçek hesaplar buradan beslenebilir.
    private func buildAccounts() -> [String] {
        var accounts: [String] = []
        if !accountName.isEmpty { accounts.append(accountName) }
        // Örnek seçenekler
        accounts.append(contentsOf: [
            "gorkemoa35@gmail.com",
            "info@articapital.app"
        ])
        return Array(Set(accounts))
    }

    private func collectItems(completion: @escaping ([[String: Any]]) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { completion([]); return }
        var results: [[String: Any]] = []
        let group = DispatchGroup()

        func append(url: URL, type: String) {
            results.append(["path": url.absoluteString, "type": type])
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if #available(iOS 14.0, *) {
                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, _ in
                            if let url = data as? URL { append(url: url, type: "image") }
                            group.leave()
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { data, _ in
                            if let url = data as? URL { append(url: url, type: "video") }
                            group.leave()
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                            if let url = data as? URL { append(url: url, type: "file") }
                            group.leave()
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                            if let text = data as? String {
                                results.append(["text": text, "type": "text"])
                            }
                            group.leave()
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) { completion(results) }
    }

    private func openHostApp() {
        let extensionBundleId = (Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String) ?? ""
        let hostBundleId: String = {
            if extensionBundleId.hasSuffix(".ShareExtension") {
                return String(extensionBundleId.dropLast(".ShareExtension".count))
            }
            let parts = extensionBundleId.split(separator: ".")
            if parts.count > 1 { return parts.dropLast().joined(separator: ".") }
            return extensionBundleId
        }()
        guard let url = URL(string: "ShareMedia-\(hostBundleId)://") else { return }
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while responder != nil {
            if responder!.responds(to: selector) {
                _ = responder!.perform(selector, with: url)
                break
            }
            responder = responder?.next
        }
    }
}

// MARK: - UITextViewDelegate
extension ShareViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Not ekle..."
            textView.textColor = .placeholderText
            noteText = ""
        } else {
            noteText = textView.text
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.textColor != .placeholderText {
            noteText = textView.text
        }
    }
}

