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
    private struct Project { let id: Int; let name: String; let code: String; let compID: Int; let compName: String }
    private struct RequiredDocument { 
        let documentID: Int          // Belge türü ID'si
        let documentName: String
        let isRequired: Bool
        let isAdded: Bool
        let compDocumentID: Int?     // Şirket belgesinin kendi ID'si (isAdded=true ise)
    }
    private var projects: [Project] = []
    private var filteredProjects: [Project] = []
    private let fallbackProjects: [Project] = [Project(id: -1, name: "Seçiniz", code: "", compID: 0, compName: "")]
    // Belgeler projeye göre dinamik olarak requiredDocuments'tan gelir
    private var requiredDocuments: [RequiredDocument] = []
    private var selectedDocumentType: RequiredDocument?
    private static var actionKey: UInt8 = 0
    
    private var accountName: String = ""
    private var selectedFolder: String = ""
    private var selectedProjectId: Int?
    private var selectedProjectCode: String = ""
    private var selectedProjectCompID: Int = 0
    private var selectedProjectCompAdrID: Int = 0
    private var shareWith: String = ""
    private var noteText: String = ""
    private var companies: [String] = []
    private var companiesWithIDs: [(name: String, compID: Int)] = [] // Firma adı ve ID eşleşmesi
    private var userToken: String = ""
    private var compID: Int = 0
    private var compAdrID: Int = 0
    private var selectedCompanyID: Int = 0 // Seçilen firmanın compID'si
    
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
    private let optionsStackView = UIStackView()
    private let buttonsContainerView = UIView()
    private let footerBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    private let footerSeparatorView = UIView()
    private let buttonsStackView = UIStackView()
    private let sendDocumentButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ud = UserDefaults(suiteName: appGroupId)
        accountName = ud?.string(forKey: "LoggedInUserName") ?? ""
        userToken = ud?.string(forKey: "UserToken") ?? ""
        compID = ud?.integer(forKey: "CompID") ?? 0
        compAdrID = ud?.integer(forKey: "CompAdrID") ?? 0
        
        // App Group'tan firma listelerini al (tüm kullanıcılar için)
        if let companiesString = ud?.string(forKey: "Companies") {
            companies = companiesString.components(separatedBy: "|").filter { !$0.isEmpty }
        }
        
        // Firma ID'lerini yükle
        if let companiesWithIDsString = ud?.string(forKey: "CompaniesWithIDs"),
           let data = companiesWithIDsString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
            companiesWithIDs = json.compactMap { dict in
                guard let name = dict["compName"] as? String,
                      let compID = dict["compID"] as? Int else { return nil }
                return (name: name, compID: compID)
            }
        }
        
        // İlk açılışta firma seçilmemiş olarak başla
        // Kullanıcı manuel olarak firma seçmeli
        accountName = ""
        selectedCompanyID = 0
        
        if selectedFolder.isEmpty { selectedFolder = "" }
        if shareWith.isEmpty { shareWith = requiredDocuments.first?.documentName ?? "" }
        
        setupUI()
        setupConstraints()
        
        // Tap gesture'ı ekle - UITextView dışında dokunuldğunda klavyeyi kapat
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        if userToken.isEmpty {
            showAlert(title: "Giriş Gerekli", message: "Lütfen önce Arti Capital uygulamasından giriş yapın.")
        } else {
            // Firma seçilmeden projeler yüklenmesin
            if selectedCompanyID > 0 {
                fetchProjects()
            }
        }
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
        noteTitleLabel.text = "Açıklama (opsiyonel)"
        noteTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        noteTitleLabel.textColor = .secondaryLabel
        contentView.addSubview(noteTitleLabel)
        
        // Options Stack View
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 8
        optionsStackView.backgroundColor = .clear
        contentView.addSubview(optionsStackView)
        
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

        // Send Document Button
        var configPrimary = UIButton.Configuration.filled()
        configPrimary.cornerStyle = .large
        configPrimary.baseBackgroundColor = .systemBlue
        configPrimary.baseForegroundColor = .white
        configPrimary.title = "Belgeyi Yükle" // Dinamik olarak güncellenecek
        sendDocumentButton.configuration = configPrimary
        sendDocumentButton.addTarget(self, action: #selector(uploadDocumentTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(sendDocumentButton)
        
        // Buton başlığını güncelle
        updateSendButtonTitle()

        setupOptions()
    }
    
    private func updateSendButtonTitle() {
        var config = sendDocumentButton.configuration
        if let docType = selectedDocumentType {
            config?.title = docType.isAdded ? "Belgeyi Güncelle" : "Belgeyi Yükle"
        } else {
            config?.title = "Belgeyi Yükle"
        }
        sendDocumentButton.configuration = config
    }
    
    private func setupOptions() {
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Hesap seçeneği
        let firmaTitleText = "Firma"
        let accountOption = createOptionRow(
            title: firmaTitleText,
            value: accountName.isEmpty ? "Seçiniz" : accountName,
            icon: "person.circle"
        ) { [weak self] in
            self?.showAccountOptions()
        }
        optionsStackView.addArrangedSubview(accountOption)
        
        // Projeler seçeneği
        let isCompanySelected = selectedCompanyID > 0
        let folderOption: UIView
        if isCompanySelected {
            folderOption = createOptionRow(
                title: "Projeler",
                value: selectedFolder.isEmpty ? "Seçiniz" : selectedFolder,
                icon: "folder"
            ) { [weak self] in
                self?.showFolderOptions()
            }
        } else {
            // Firma seçilmeden pasif ve bilgi verici
            folderOption = createOptionRow(
                title: "Projeler",
                value: "Firma seçiniz",
                icon: "folder"
            ) { [weak self] in
                self?.showAccountOptions()
            }
            folderOption.alpha = 0.6
        }
        optionsStackView.addArrangedSubview(folderOption)
        
        // Paylaşım seçeneği
        let shareOption = createOptionRow(
            title: "Belge Türü",
            value: shareWith.isEmpty ? "Seçiniz" : shareWith,
            icon: "doc.fill"
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
        [containerView, headerView, headerBlurView, titleLabel, cancelButton, shareButton, scrollView, contentView, optionsTitleLabel, noteTextView, noteTitleLabel, optionsStackView, buttonsContainerView, footerBlurView, footerSeparatorView, buttonsStackView].forEach {
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
            
            // Note Title
            noteTitleLabel.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 16),
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
    
    @objc private func dismissKeyboard() {
        noteTextView.resignFirstResponder()
    }
    
    @objc private func shareTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        uploadDocumentTapped()
    }

    @objc private func uploadDocumentTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Validasyon
        guard !userToken.isEmpty else {
            showAlert(title: "Hata", message: "Kullanıcı token bulunamadı. Lütfen uygulamaya giriş yapın.")
            return
        }
        
        guard let projectId = selectedProjectId, projectId > 0 else {
            showAlert(title: "Hata", message: "Proje seçilmedi.")
            return
        }
        
        guard selectedProjectCompID > 0 else {
            showAlert(title: "Hata", message: "Proje bilgileri yüklenemedi. Lütfen tekrar proje seçin.")
            return
        }
        
        guard let docType = selectedDocumentType else {
            showAlert(title: "Hata", message: "Belge türü seçilmedi.")
            return
        }
        
        // Loading göster
        showLoading()
        
        // Dosyaları topla ve API'ye gönder
        collectItems { [weak self] items in
            guard let self = self else {
                DispatchQueue.main.async {
                    self?.hideLoading()
                }
                return
            }
            
            guard !items.isEmpty else {
                DispatchQueue.main.async {
                    self.hideLoading()
                    self.showAlert(title: "Hata", message: "Yüklenecek dosya bulunamadı.")
                }
                return
            }
            
            // Background thread'de upload et
            DispatchQueue.global(qos: .userInitiated).async {
                self.uploadDocument(projectId: projectId, documentType: docType, items: items)
            }
        }
    }
    
    // MARK: - Option Methods
    private func showAccountOptions() {
        let accounts = buildAccounts()
        showBottomSheetSelection(title: "Firma Seç", options: accounts, currentSelection: accountName) { [weak self] selectedAccount in
            guard let self = self else { return }
            if let account = selectedAccount {
                self.accountName = account
                
                // Seçilen firmaya ait compID'yi bul
                if let company = self.companiesWithIDs.first(where: { $0.name == account }) {
                    self.selectedCompanyID = company.compID
                } else {
                    self.selectedCompanyID = 0
                }
                
                // Firma değiştiğinde projeleri API'den yeniden yükle
                self.projects = []
                self.filteredProjects = []
                self.selectedFolder = ""
                self.selectedProjectId = nil
                self.selectedProjectCode = ""
                self.setupOptions()
                
                // Projeleri yeniden yükle
                self.fetchProjects()
                
                // Projeler yüklendikten sonra otomatik olarak Proje seçimine geç
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !self.filteredProjects.isEmpty {
                        self.showFolderOptions()
                    }
                }
            }
        }
    }
    
    
    private func showFolderOptions() {
        // Filtrelenmiş projeleri kullan (firma seçimine göre)
        let sourceProjects = filteredProjects.isEmpty ? (projects.isEmpty ? fallbackProjects : projects) : filteredProjects
        let folders = sourceProjects.map { $0.name }
        
        showBottomSheetSelection(title: "Proje Seç", options: folders, currentSelection: selectedFolder) { [weak self] selectedFolder in
            guard let self = self else { return }
            if let folder = selectedFolder {
                self.selectedFolder = folder
                if let project = sourceProjects.first(where: { $0.name == folder }) {
                    self.selectedProjectId = project.id
                    self.selectedProjectCode = project.code
                }
                self.setupOptions()
                if let pid = self.selectedProjectId, pid > 0 {
                    // Proje detayını çek, tamamlandığında Belge Türü seçimine geç
                    self.fetchProjectDetail(projectId: pid) {
                        // Proje detayı yüklendikten sonra otomatik olarak Belge Türü seçimine geç
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.showShareOptions()
                        }
                    }
                } else {
                    // Belgeler yalnızca API'den gelir
                    self.requiredDocuments = []
                    self.shareWith = ""
                    self.selectedDocumentType = nil
                    self.setupOptions()
                }
            }
        }
    }
    
    private func showShareOptions() {
        // TÜM belgeleri göster (isAdded true/false fark etmez)
        let allDocs = requiredDocuments
        let shareOptions = allDocs.map { $0.documentName }
        
        if shareOptions.isEmpty {
            showAlert(title: "Bilgi", message: "Bu proje için gerekli belge bulunmamaktadır.")
            return
        }
        
        showBottomSheetSelection(title: "Belge Türü Seç", options: shareOptions, currentSelection: shareWith) { [weak self] selectedOption in
            guard let self = self else { return }
            if let option = selectedOption {
                self.shareWith = option
                self.selectedDocumentType = allDocs.first(where: { $0.documentName == option })
                self.setupOptions()
                self.updateSendButtonTitle() // Buton başlığını güncelle
                // Belge türü seçildikten sonra Not alanına odaklan
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.noteTextView.becomeFirstResponder()
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
        return companies
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
        // API: projects/all - Kullanıcının projeleri (selectedCompanyID ile filtreli)
        var urlString = "https://api.office701.com/arti-capital/service/user/account/projects/all?userToken=\(userToken)"
        
        // Eğer bir firma seçilmişse compID parametresini ekle
        if selectedCompanyID > 0 {
            urlString += "&compID=\(selectedCompanyID)"
        }
        
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "GET"
        // Basic Auth
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
                DispatchQueue.main.async {
                    self.showAlert(title: "Bağlantı Hatası", message: "Projeler yüklenemedi: \(error.localizedDescription)")
                }
                return
            }
            guard let data = data else {
                return
            }
            
            do {
                // Beklenen JSON: { data: { projects: [ { appID:Int, appTitle:String, appCode:String, compID:Int, compName:String } ] } }
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // API hata kontrolü
                    if let success = json["success"] as? Bool, !success {
                        let message = json["message"] as? String ?? "Bilinmeyen hata"
                        DispatchQueue.main.async {
                            self.showAlert(title: "API Hatası", message: message)
                        }
                        return
                    }
                    
                    if let dataObj = json["data"] as? [String: Any],
                       let projectsArray = dataObj["projects"] as? [[String: Any]] {
                        let items: [Project] = projectsArray.compactMap { dict in
                            let name = (dict["appTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let code = (dict["appCode"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let compName = (dict["compName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            
                            let idVal = dict["appID"]
                            let id: Int
                            if let i = idVal as? Int { id = i } else if let s = idVal as? String, let parsed = Int(s) { id = parsed } else { id = -1 }
                            
                            let compIDVal = dict["compID"]
                            let compID: Int
                            if let i = compIDVal as? Int { compID = i } else if let s = compIDVal as? String, let parsed = Int(s) { compID = parsed } else { compID = 0 }
                            
                            return name.isEmpty ? nil : Project(id: id, name: name, code: code, compID: compID, compName: compName)
                        }
                        DispatchQueue.main.async {
                            self.projects = items.isEmpty ? self.fallbackProjects : items
                            
                            // API'den filtrelenmiş projeler geldiği için doğrudan kullan
                            self.filteredProjects = self.projects
                            
                            if self.selectedFolder.isEmpty { 
                                self.selectedFolder = (self.filteredProjects.first?.name ?? self.fallbackProjects.first?.name) ?? "" 
                            }
                            if let first = self.filteredProjects.first {
                                self.selectedProjectId = first.id
                                self.selectedProjectCode = first.code
                            }
                            self.setupOptions()
                        }
                    }
                }
            } catch {
            }
        }
        task.resume()
    }
}

// MARK: - Networking (Project Detail & Document Upload)
extension ShareViewController {
    private func fetchProjectDetail(projectId: Int, completion: (() -> Void)? = nil) {
        guard projectId > 0 else {
            completion?()
            return
        }
        
        let urlString = "https://api.office701.com/arti-capital/service/user/account/projects/\(projectId)?userToken=\(userToken)"
        guard let url = URL(string: urlString) else {
            completion?()
            return
        }
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
            guard let self = self else {
                completion?()
                return
            }
            if let error = error {
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            do {
                // Beklenen JSON: { data: { project: { requiredDocuments: [ { documentID, documentName, isRequired, isAdded } ] } } }
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // API hata kontrolü
                    if let success = json["success"] as? Bool, !success {
                        let message = json["message"] as? String ?? "Bilinmeyen hata"
                        DispatchQueue.main.async {
                            self.showAlert(title: "API Hatası", message: message)
                            completion?()
                        }
                        return
                    }
                    
                    if let dataObj = json["data"] as? [String: Any],
                       let projectObj = dataObj["project"] as? [String: Any] {
                        
                        // CompID ve CompAdrID'yi parse et
                        if let compIDVal = projectObj["compID"] {
                            if let i = compIDVal as? Int {
                                self.selectedProjectCompID = i
                            } else if let s = compIDVal as? String, let parsed = Int(s) {
                                self.selectedProjectCompID = parsed
                            }
                        }
                        if let compAdrIDVal = projectObj["compAdrID"] {
                            if let i = compAdrIDVal as? Int {
                                self.selectedProjectCompAdrID = i
                            } else if let s = compAdrIDVal as? String, let parsed = Int(s) {
                                self.selectedProjectCompAdrID = parsed
                            }
                        }
                        
                        let requiredDocsArray = (projectObj["requiredDocuments"] as? [[String: Any]] ?? [])
                        let documentsArray = (projectObj["documents"] as? [[String: Any]] ?? [])
                        
                        let docs: [RequiredDocument] = requiredDocsArray.compactMap { dict in
                            guard let docID = dict["documentID"] as? Int,
                                  let docName = dict["documentName"] as? String else {
                                return nil
                            }
                            let isRequired = dict["isRequired"] as? Bool ?? false
                            let isAdded = dict["isAdded"] as? Bool ?? false
                            
                            // Eğer isAdded=true ise, documents array'inden bu belgenin compDocumentID'sini bul
                            var compDocumentID: Int? = nil
                            if isAdded {
                                // documents array'inde documentType veya documentName ile eşleştir
                                for docDict in documentsArray {
                                    let docTypeName = (docDict["documentType"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespaces)
                                    let reqDocName = docName.lowercased().trimmingCharacters(in: .whitespaces)
                                    if docTypeName == reqDocName {
                                        compDocumentID = docDict["documentID"] as? Int
                                        break
                                    }
                                }
                            }
                            
                            return RequiredDocument(documentID: docID, documentName: docName, isRequired: isRequired, isAdded: isAdded, compDocumentID: compDocumentID)
                        }
                        
                        DispatchQueue.main.async {
                            self.requiredDocuments = docs
                            
                            // İLK belgeyi seç (isAdded fark etmez)
                            if let first = docs.first {
                                self.shareWith = first.documentName
                                self.selectedDocumentType = first
                            } else {
                                self.shareWith = ""
                                self.selectedDocumentType = nil
                            }
                            self.setupOptions()
                            completion?()
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion?()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
        task.resume()
    }
    
    private func uploadDocument(projectId: Int, documentType: RequiredDocument, items: [[String: Any]]) {
        // İlk item'ı al (path içeren dosya)
        guard let firstItem = items.first,
              let pathString = firstItem["path"] as? String,
              let fileURL = URL(string: pathString) else {
            DispatchQueue.main.async {
                self.hideLoading()
                self.showAlert(title: "Hata", message: "Dosya yolu bulunamadı.")
            }
            return
        }
        
        // Dosyayı oku ve base64'e çevir
        do {
            let fileData = try Data(contentsOf: fileURL)
            let base64String = fileData.base64EncodedString()
            
            // MIME type belirle
            let ext = fileURL.pathExtension.lowercased()
            
            var mimeType = "application/octet-stream"
            if ext == "pdf" {
                mimeType = "application/pdf"
            } else if ["jpg", "jpeg"].contains(ext) {
                mimeType = "image/jpeg"
            } else if ext == "png" {
                mimeType = "image/png"
            } else if ["doc", "docx"].contains(ext) {
                mimeType = "application/msword"
            } else if ["xls", "xlsx"].contains(ext) {
                mimeType = "application/vnd.ms-excel"
            }
            
            let fileDataString = "data:\(mimeType);base64,\(base64String)"
            
            // API'ye gönder (main thread'e dön)
            DispatchQueue.main.async {
                self.uploadToAPI(projectId: projectId, documentTypeID: documentType.documentID, fileData: fileDataString)
            }
        } catch {
            DispatchQueue.main.async {
                self.hideLoading()
                let errorDetail = "Dosya okunamadı:\n\(error.localizedDescription)\n\nKod: \((error as NSError).code)"
                self.showAlert(title: "Dosya Hatası", message: errorDetail)
            }
        }
    }
    
    private func uploadToAPI(projectId: Int, documentTypeID: Int, fileData: String) {
        // isAdded kontrolüne göre endpoint seç
        let isUpdate = selectedDocumentType?.isAdded ?? false
        let urlString = isUpdate 
            ? "https://api.office701.com/arti-capital/service/user/account/company/documentUpdate"
            : "https://api.office701.com/arti-capital/service/user/account/projects/documentAdd"
        
        guard let url = URL(string: urlString) else {
            hideLoading()
            showAlert(title: "Hata", message: "Geçersiz URL.")
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        // Güncelleme için PUT, ekleme için POST
        request.httpMethod = isUpdate ? "PUT" : "POST"
        
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
        let documentDesc = noteText.isEmpty || noteText == "Not ekle..." ? "" : noteText
        var body: [String: Any] = [
            "userToken": userToken,
            "compID": selectedProjectCompID,
            "documentType": documentTypeID,
            "documentDesc": documentDesc,
            "file": fileData
        ]
        
        // Eğer güncelleme (update) modundaysa documentID ekle (company document update için)
        if isUpdate, let docType = selectedDocumentType {
            // compDocumentID kullan (şirket belgesinin kendi ID'si)
            guard let compDocID = docType.compDocumentID, compDocID > 0 else {
                DispatchQueue.main.async {
                    self.hideLoading()
                    self.showAlert(title: "Hata", message: "Belge ID'si bulunamadı. Lütfen tekrar deneyin.")
                }
                return
            }
            body["documentID"] = compDocID
        } else {
            // Ekleme modunda appID ve isAdditional parametresi (project document add için)
            body["appID"] = projectId
            body["isAdditional"] = 0
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            DispatchQueue.main.async {
                self.hideLoading()
                self.showAlert(title: "İstek Hatası", message: "İstek oluşturulamadı: \(error.localizedDescription)")
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoading()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    let errorDetail = "Bağlantı hatası: \(error.localizedDescription)\nKod: \((error as NSError).code)"
                    self.showAlert(title: "Ağ Hatası", message: errorDetail)
                }
                return
            }
            
            // HTTP response status code'u kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                // Response status bilgisi - isteğe bağlı log için burası kullanılabilir
                _ = httpResponse.statusCode
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Hata", message: "Sunucudan veri alınamadı.")
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let success = json["success"] as? Bool ?? false
                    let message = json["message"] as? String ?? ""
                    let errorMessage = json["errorMessage"] as? String ?? ""
                    let statusCode = json["statusCode"] as? Int ?? 0
                    
                    DispatchQueue.main.async {
                        if success {
                            self.showAlert(title: "Başarılı", message: message.isEmpty ? "Belge başarıyla yüklendi." : message) {
                                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                            }
                        } else {
                            // Daha detaylı hata mesajı göster
                            var detailedError = ""
                            if !message.isEmpty {
                                detailedError = message
                            }
                            if !errorMessage.isEmpty {
                                if !detailedError.isEmpty { detailedError += "\n\n" }
                                detailedError += "Detay: \(errorMessage)"
                            }
                            if statusCode > 0 {
                                if !detailedError.isEmpty { detailedError += "\n" }
                                detailedError += "Kod: \(statusCode)"
                            }
                            if detailedError.isEmpty {
                                detailedError = "Belge yüklenemedi. Lütfen tekrar deneyin."
                            }
                            
                            self.showAlert(title: "Yükleme Hatası", message: detailedError)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Hata", message: "Yanıt işlenemedi: \(error.localizedDescription)")
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



