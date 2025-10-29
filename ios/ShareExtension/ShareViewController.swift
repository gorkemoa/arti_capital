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
import ObjectiveC

final class ShareViewController: UIViewController {
    
    private let appGroupId = "group.com.office701.articapital" // App Group
    private let userDefaultsKey = "ShareMedia" // receive_sharing_intent key
    // Projeler (API'den yüklenecek); boşsa geçici fallback olarak mock kullanılabilir
    private struct Project { let id: Int; let name: String }
    private var projects: [Project] = []
    private let fallbackProjects: [Project] = [Project(id: -1, name: "Seçiniz")]
    // Belgeler projeye göre dinamik olarak duties'den gelir
    private var documentTypes: [String] = []
    private static var actionKey: UInt8 = 0
    
    private var accountName: String = ""
    private var selectedFolder: String = ""
    private var selectedProjectId: Int?
    private var shareWith: String = ""
    private var noteText: String = ""
    private var userRank: String = ""
    private var isAdmin: Bool = false
    private var companies: [String] = []
    private var userToken: String = ""
    private var compID: Int = 0
    private var compAdrID: Int = 0
    private var projectTitle: String = ""
    
    // UI Elements
    private let containerView = UIView()
    private let headerView = UIView()
    private let headerBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let titleLabel = UILabel()
    private let cancelButton = UIButton()
    private let shareButton = UIButton()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let optionsTitleLabel = UILabel()
    private let noteTextView = UITextView()
    private let noteTitleLabel = UILabel()
    private let projectTitleTextField = UITextField()
    private let projectTitleLabel = UILabel()
    private let optionsStackView = UIStackView()
    private let buttonsContainerView = UIView()
    private let footerBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    private let footerSeparatorView = UIView()
    private let buttonsStackView = UIStackView()
    private let sendProjectButton = UIButton(type: .system)
    private let sendMessageButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let ud = UserDefaults(suiteName: appGroupId)
        accountName = ud?.string(forKey: "LoggedInUserName") ?? ""
        userRank = ud?.string(forKey: "UserRank") ?? ""
        userToken = ud?.string(forKey: "UserToken") ?? ""
        compID = ud?.integer(forKey: "CompID") ?? 0
        compAdrID = ud?.integer(forKey: "CompAdrID") ?? 0
        
        // App Group'tan firma listelerini al (tüm kullanıcılar için)
        if let companiesString = ud?.string(forKey: "Companies") {
            companies = companiesString.components(separatedBy: "|").filter { !$0.isEmpty }
        }
        // Rank 50 ise yönetici flag'i
        isAdmin = (userRank == "50")
        // Yönetici olmayanlarda isim-soyisim kullanma; firma listesinin ilkini seç
        if !isAdmin {
            if let first = companies.first { accountName = first }
        } else if accountName.isEmpty, let first = companies.first {
            accountName = first
        }
        if isAdmin {
            // Yönetici için dosya adından otomatik parse et
            parseFileNameForAdmin()
        }
        
        if selectedFolder.isEmpty { selectedFolder = projects.first?.name ?? fallbackProjects.first?.name ?? "" }
        if shareWith.isEmpty { shareWith = documentTypes.first ?? "" }
        
        setupUI()
        setupConstraints()
        // Projeleri API'den çek
        fetchProjects()
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
        
        // Section Title: Seçimler
        optionsTitleLabel.text = "Seçimler"
        optionsTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        optionsTitleLabel.textColor = .secondaryLabel
        contentView.addSubview(optionsTitleLabel)

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
        
        // Section Title: Not
        noteTitleLabel.text = "Not (opsiyonel)"
        noteTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        noteTitleLabel.textColor = .secondaryLabel
        contentView.addSubview(noteTitleLabel)
        
        // Options Stack View
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 8
        optionsStackView.backgroundColor = .clear
        contentView.addSubview(optionsStackView)
        
        // Section Title: Proje Başlığı
        projectTitleLabel.text = "Proje Başlığı"
        projectTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        projectTitleLabel.textColor = .secondaryLabel
        contentView.addSubview(projectTitleLabel)
        
        // Project Title Text Field
        projectTitleTextField.placeholder = "Proje başlığı girin..."
        projectTitleTextField.borderStyle = .roundedRect
        projectTitleTextField.backgroundColor = .secondarySystemBackground
        projectTitleTextField.font = .systemFont(ofSize: 16)
        projectTitleTextField.autocapitalizationType = .sentences
        projectTitleTextField.delegate = self
        contentView.addSubview(projectTitleTextField)
        
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
        
        // Section Title: Not
        noteTitleLabel.text = "Not (opsiyonel)"
        noteTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        noteTitleLabel.textColor = .secondaryLabel
        contentView.addSubview(noteTitleLabel)
        
        // Buttons Container
        buttonsContainerView.backgroundColor = .systemBackground
        containerView.addSubview(buttonsContainerView)
        
        // Footer Blur & Separator
        buttonsContainerView.addSubview(footerBlurView)
        footerSeparatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        buttonsContainerView.addSubview(footerSeparatorView)

        // Buttons Stack
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 10
        buttonsContainerView.addSubview(buttonsStackView)

        // Yönetici ise sadece "Mesaj olarak gönder" butonu
        if isAdmin {
            // Send Message Button (tek buton)
            var configPrimary = UIButton.Configuration.filled()
            configPrimary.cornerStyle = .large
            configPrimary.baseBackgroundColor = .systemBlue
            configPrimary.baseForegroundColor = .white
            configPrimary.title = "Mesaj Olarak Gönder"
            sendMessageButton.configuration = configPrimary
            sendMessageButton.addTarget(self, action: #selector(shareAsMessageTapped), for: .touchUpInside)
            buttonsStackView.addArrangedSubview(sendMessageButton)
        } else {
            // Normal kullanıcı için her iki buton
            // Send Project Button (üstte)
            var configPrimary = UIButton.Configuration.filled()
            configPrimary.cornerStyle = .large
            configPrimary.baseBackgroundColor = .systemBlue
            configPrimary.baseForegroundColor = .white
            configPrimary.title = "Projeye Kaydet"
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
        }

        setupOptions()
    }
    
    private func setupOptions() {
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Hesap seçeneği
        let firmaTitleText = "Firma"
        let accountOption = createOptionRow(
            title: firmaTitleText,
            value: accountName.isEmpty ? "Giriş yapılmadı" : accountName,
            icon: "person.circle"
        ) { [weak self] in
            self?.showAccountOptions()
        }
        optionsStackView.addArrangedSubview(accountOption)
        
        // Projeler seçeneği
        let folderOption = createOptionRow(
            title: "Projeler",
            value: selectedFolder.isEmpty ? "Yükleniyor..." : selectedFolder,
            icon: "folder"
        ) { [weak self] in
            self?.showFolderOptions()
        }
        optionsStackView.addArrangedSubview(folderOption)
        
        // Paylaşım seçeneği
        let shareOption = createOptionRow(
            title: "Belge Türü",
            value: shareWith.isEmpty ? "Seçiniz" : shareWith,
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
        objc_setAssociatedObject(button, &ShareViewController.actionKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return container
    }
    
    @objc private func optionTapped(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let action = objc_getAssociatedObject(sender, &ShareViewController.actionKey) as? () -> Void {
            action()
        }
    }
    
    private func setupConstraints() {
        [containerView, headerView, headerBlurView, titleLabel, cancelButton, shareButton, scrollView, contentView, optionsTitleLabel, projectTitleLabel, projectTitleTextField, noteTextView, noteTitleLabel, optionsStackView, buttonsContainerView, footerBlurView, footerSeparatorView, buttonsStackView].forEach {
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

            // Footer blur fills buttons container
            footerBlurView.topAnchor.constraint(equalTo: buttonsContainerView.topAnchor),
            footerBlurView.leadingAnchor.constraint(equalTo: buttonsContainerView.leadingAnchor),
            footerBlurView.trailingAnchor.constraint(equalTo: buttonsContainerView.trailingAnchor),
            footerBlurView.bottomAnchor.constraint(equalTo: buttonsContainerView.bottomAnchor),

            // Footer top separator
            footerSeparatorView.topAnchor.constraint(equalTo: buttonsContainerView.topAnchor),
            footerSeparatorView.leadingAnchor.constraint(equalTo: buttonsContainerView.leadingAnchor),
            footerSeparatorView.trailingAnchor.constraint(equalTo: buttonsContainerView.trailingAnchor),
            footerSeparatorView.heightAnchor.constraint(equalToConstant: 0.5),

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
            
            // Options Title
            optionsTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            optionsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            // Options Stack View
            optionsStackView.topAnchor.constraint(equalTo: optionsTitleLabel.bottomAnchor, constant: 8),
            optionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Project Title Label
            projectTitleLabel.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 16),
            projectTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            projectTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Project Title Text Field
            projectTitleTextField.topAnchor.constraint(equalTo: projectTitleLabel.bottomAnchor, constant: 8),
            projectTitleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            projectTitleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            projectTitleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Note Title
            noteTitleLabel.topAnchor.constraint(equalTo: projectTitleTextField.bottomAnchor, constant: 16),
            noteTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noteTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            // Note Text View (alta, butonların üstünde)
            noteTextView.topAnchor.constraint(equalTo: noteTitleLabel.bottomAnchor, constant: 8),
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
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                ud?.set(jsonString, forKey: "ShareMediaJSON")
            }
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
        
        // Validasyon
        guard !userToken.isEmpty else {
            showAlert(title: "Hata", message: "Kullanıcı token bulunamadı. Lütfen uygulamaya giriş yapın.")
            return
        }
        
        guard compID > 0 else {
            showAlert(title: "Hata", message: "Firma seçilmedi.")
            return
        }
        
        guard let serviceID = selectedProjectId, serviceID > 0 else {
            showAlert(title: "Hata", message: "Proje seçilmedi.")
            return
        }
        
        guard !projectTitle.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen proje başlığı girin.")
            return
        }
        
        // Dosyaları topla ve API'ye gönder
        collectItems { [weak self] items in
            guard let self = self else { return }
            self.createProject(items: items)
        }
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
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                ud?.set(jsonString, forKey: "ShareMediaJSON")
            }
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
        showBottomSheetSelection(title: "Firma Seç", options: accounts, currentSelection: accountName) { [weak self] selectedAccount in
            if let account = selectedAccount {
                self?.accountName = account
                self?.setupOptions()
                // Firma seçildikten sonra otomatik olarak Proje seçimine geç
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.showFolderOptions()
                }
            }
        }
    }
    
    private func showFolderOptions() {
        let sourceProjects = projects.isEmpty ? fallbackProjects : projects
        let folders = sourceProjects.map { $0.name }
        showBottomSheetSelection(title: "Proje Seç", options: folders, currentSelection: selectedFolder) { [weak self] selectedFolder in
            guard let self = self else { return }
            if let folder = selectedFolder {
                self.selectedFolder = folder
                self.selectedProjectId = sourceProjects.first(where: { $0.name == folder })?.id
                self.setupOptions()
                if let pid = self.selectedProjectId, pid > 0 {
                    self.fetchServiceDetail(projectId: pid)
                } else {
                    // Belgeler yalnızca API'den gelir; fallback yok
                    self.documentTypes = []
                    self.shareWith = ""
                    self.setupOptions()
                }
                // Proje seçildikten sonra otomatik olarak Belge Türü seçimine geç
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.showShareOptions()
                }
            }
        }
    }
    
    private func showShareOptions() {
        let shareOptions = documentTypes
        if shareOptions.isEmpty { return }
        showBottomSheetSelection(title: "Belge Türü Seç", options: shareOptions, currentSelection: shareWith) { [weak self] selectedOption in
            if let option = selectedOption {
                self?.shareWith = option
                self?.setupOptions()
                // Belge türü seçildikten sonra Not alanına odaklan
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.noteTextView.becomeFirstResponder()
                }
            }
        }
    }
    
    private func showBottomSheetSelection(title: String, options: [String], currentSelection: String, completion: @escaping (String?) -> Void) {
        let selectionVC = BottomSheetSelectionViewController(title: title, options: options, currentSelection: currentSelection, completion: completion)
        
        if let sheet = selectionVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            if #available(iOS 16.0, *) {
                // İçeride scroll yapılırken sheet büyümesin; sadece grabber ile büyüsün
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
        }
        
        present(selectionVC, animated: true)
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
        // Tüm kullanıcılar: sadece firma adları listelenir
        // Yönetici ise ve accountName listede yoksa en üste eklenebilir (opsiyonel)
        var accounts: [String] = companies
        if isAdmin, !accountName.isEmpty, !accounts.contains(accountName) {
            accounts.insert(accountName, at: 0)
        }
        return accounts
    }
    
    private func parseFileNameForAdmin() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if #available(iOS 14.0, *) {
                    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] data, _ in
                            guard let self = self, let url = data as? URL else { return }
                            
                            DispatchQueue.main.async {
                                self.parseFileName(from: url)
                            }
                        }
                        return // İlk dosyayı parse et ve çık
                    }
                }
            }
        }
    }
    
    private func parseFileName(from url: URL) {
        let fileName = url.deletingPathExtension().lastPathComponent
        let components = fileName.components(separatedBy: "_")
        
        // Format: Firma_Proje_BelgeTürü
        if components.count >= 3 {
            let parsedCompany = components[0].trimmingCharacters(in: .whitespaces)
            let parsedProject = components[1].trimmingCharacters(in: .whitespaces)
            let parsedDocType = components[2].trimmingCharacters(in: .whitespaces)
            
            // Firma listesinde varsa seç
            if companies.contains(parsedCompany) {
                accountName = parsedCompany
            }
            
            // Proje listesinde varsa seç
            if let match = projects.first(where: { $0.name == parsedProject }) {
                selectedFolder = match.name
                selectedProjectId = match.id
                if match.id > 0 { fetchServiceDetail(projectId: match.id) }
            }
            
            // Belge türü listesinde varsa seç (dinamik documentTypes)
            if documentTypes.contains(parsedDocType) {
                shareWith = parsedDocType
            }
            
            // UI'ı güncelle
            setupOptions()
        }
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

// MARK: - Networking (Projects)
extension ShareViewController {
    private func fetchProjects() {
        // API: services/all
        guard let url = URL(string: "https://api.office701.com/arti-capital/service/general/general/services/all") else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "GET"
        // Basic Auth (App ile aynı kimlik)
        let username = "Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM"
        let password = "vRParTCAqTjtmkI17I1EVpPH57Edl0"
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let authHeader = authData.base64EncodedString()
            request.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                // Sessizce fallback ile devam et
                print("[ShareExtension] fetchProjects error: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                // Beklenen JSON şeması: { data: { services: [ { serviceID:Int, serviceName:String } ] } }
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let services = dataObj["services"] as? [[String: Any]] {
                    let items: [Project] = services.compactMap { dict in
                        let name = (dict["serviceName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let idVal = dict["serviceID"]
                        let id: Int
                        if let i = idVal as? Int { id = i } else if let s = idVal as? String, let parsed = Int(s) { id = parsed } else { id = -1 }
                        return name.isEmpty ? nil : Project(id: id, name: name)
                    }
                    DispatchQueue.main.async {
                        self.projects = items.isEmpty ? self.fallbackProjects : items
                        if self.selectedFolder.isEmpty { self.selectedFolder = (self.projects.first?.name ?? self.fallbackProjects.first?.name) ?? "" }
                        self.selectedProjectId = self.projects.first(where: { $0.name == self.selectedFolder })?.id
                        if let pid = self.selectedProjectId, pid > 0 {
                            self.fetchServiceDetail(projectId: pid)
                        } else {
                            self.documentTypes = []
                            if self.shareWith.isEmpty { self.shareWith = "" }
                        }
                        self.setupOptions()
                    }
                }
            } catch {
                print("[ShareExtension] parse error: \(error)")
            }
        }
        task.resume()
    }
}

// MARK: - Networking (Service Detail -> Duties)
extension ShareViewController {
    private func createProject(items: [[String: Any]]) {
        let urlString = "https://api.office701.com/arti-capital/service/user/account/projects/add"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "POST"
        
        // Basic Auth
        let username = "Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM"
        let password = "vRParTCAqTjtmkI17I1EVpPH57Edl0"
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let authHeader = authData.base64EncodedString()
            request.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Request Body
        let projectDesc = noteText.isEmpty || noteText == "Not ekle..." ? "" : noteText
        let body: [String: Any] = [
            "userToken": userToken,
            "compID": compID,
            "compAdrID": compAdrID > 0 ? compAdrID : 1, // Default 1 if not set
            "serviceID": selectedProjectId ?? 0,
            "projectTitle": projectTitle,
            "projectDesc": projectDesc
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "Hata", message: "İstek oluşturulamadı.")
            }
            return
        }
        
        // Loading göster
        DispatchQueue.main.async {
            self.showLoading()
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoading()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Hata", message: "Bağlantı hatası: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Hata", message: "Veri alınamadı.")
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let success = json["success"] as? Bool ?? false
                    let message = json["message"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        if success {
                            self.showAlert(title: "Başarılı", message: message.isEmpty ? "Proje başarıyla oluşturuldu." : message) {
                                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                            }
                        } else {
                            self.showAlert(title: "Hata", message: message.isEmpty ? "Proje oluşturulamadı." : message)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Hata", message: "Yanıt işlenemedi.")
                }
            }
        }
        task.resume()
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    private func showLoading() {
        // Basit loading gösterimi (activity indicator)
        let alert = UIAlertController(title: nil, message: "Lütfen bekleyin...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true)
    }
    
    private func hideLoading() {
        if let presented = presentedViewController as? UIAlertController,
           presented.title == nil && presented.message == "Lütfen bekleyin..." {
            presented.dismiss(animated: true)
        }
    }
    
    private func fetchServiceDetail(projectId: Int) {
        guard projectId > 0 else { return }
        let urlString = "https://api.office701.com/arti-capital/service/general/general/services/\(projectId)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "GET"
        let username = "Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM"
        let password = "vRParTCAqTjtmkI17I1EVpPH57Edl0"
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let authHeader = authData.base64EncodedString()
            request.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("[ShareExtension] fetchServiceDetail error: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                // Beklenen JSON: { data: { service: { duties: [ { dutyName:String } ] } } }
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let serviceObj = dataObj["service"] as? [String: Any] {
                    let duties = (serviceObj["duties"] as? [[String: Any]] ?? [])
                    let names: [String] = duties.compactMap { ($0["dutyName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    DispatchQueue.main.async {
                        self.documentTypes = names
                        if self.shareWith.isEmpty || !self.documentTypes.contains(self.shareWith) { self.shareWith = self.documentTypes.first ?? "" }
                        self.setupOptions()
                    }
                }
            } catch {
                print("[ShareExtension] fetchServiceDetail parse error: \(error)")
            }
        }
        task.resume()
    }
}

// MARK: - BottomSheetSelectionViewController
class BottomSheetSelectionViewController: UIViewController {
    private let titleText: String
    private let options: [String]
    private let currentSelection: String
    private let completion: (String?) -> Void
    private var filteredOptions: [String] = []
    
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let searchTextField = UITextField()
    private let tableView = UITableView()
    
    init(title: String, options: [String], currentSelection: String, completion: @escaping (String?) -> Void) {
        self.titleText = title
        self.options = options
        self.currentSelection = currentSelection
        self.completion = completion
        self.filteredOptions = options
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Header
        headerView.backgroundColor = .systemBackground
        view.addSubview(headerView)
        
        // Title
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        // Search TextField
        searchTextField.placeholder = "Ara..."
        searchTextField.borderStyle = .roundedRect
        searchTextField.backgroundColor = .secondarySystemBackground
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        headerView.addSubview(searchTextField)
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        [headerView, titleLabel, searchTextField, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Search
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            searchTextField.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func searchTextChanged() {
        let searchText = searchTextField.text?.lowercased() ?? ""
        if searchText.isEmpty {
            filteredOptions = options
        } else {
            filteredOptions = options.filter { $0.lowercased().contains(searchText) }
        }
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension BottomSheetSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let option = filteredOptions[indexPath.row]
        
        cell.textLabel?.text = option
        cell.textLabel?.font = .systemFont(ofSize: 16)
        
        // Mevcut seçimi işaretle
        if option == currentSelection {
            cell.accessoryType = .checkmark
            cell.tintColor = .systemBlue
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedOption = filteredOptions[indexPath.row]
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        dismiss(animated: true) { [weak self] in
            self?.completion(selectedOption)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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

// MARK: - UITextFieldDelegate
extension ShareViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        projectTitle = textField.text ?? ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

