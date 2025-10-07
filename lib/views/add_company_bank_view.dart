import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

// IBAN Formatter Class
class IbanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Sadece rakamlar
    
    if (newText.length > 24) {
      newText = newText.substring(0, 24); // Max 24 rakam
    }
    
    String formatted = 'TR';
    if (newText.isNotEmpty) {
      // İlk 2 rakamı TR'den sonra boşlukla ekle
      if (newText.length >= 2) {
        formatted += newText.substring(0, 2) + ' ';
        // Kalan rakamları 4'er grup halinde ekle
        String remaining = newText.substring(2);
        for (int i = 0; i < remaining.length; i += 4) {
          int end = (i + 4 < remaining.length) ? i + 4 : remaining.length;
          formatted += remaining.substring(i, end);
          if (end < remaining.length) {
            formatted += ' ';
          }
        }
      } else {
        // 2 rakamdan az ise direkt ekle
        formatted += newText;
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddCompanyBankView extends StatefulWidget {
  const AddCompanyBankView({super.key, required this.compId});
  final int compId;

  @override
  State<AddCompanyBankView> createState() => _AddCompanyBankViewState();
}

class _AddCompanyBankViewState extends State<AddCompanyBankView> {
  final _formKey = GlobalKey<FormState>();
  final _bankUsernameController = TextEditingController();
  final _bankBranchNameController = TextEditingController();
  final _bankBranchCodeController = TextEditingController();
  final _compIbanController = TextEditingController();
  
  bool _loading = false;
  bool _banksLoading = true;
  bool _companyLoading = true;
  List<BankItem> _banks = [];
  BankItem? _selectedBank;

  @override
  void initState() {
    super.initState();
    _compIbanController.text = 'TR';
    _loadBanks();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _bankUsernameController.dispose();
    _bankBranchNameController.dispose();
    _bankBranchCodeController.dispose();
    _compIbanController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() { _banksLoading = true; });
    try {
      final response = await const CompanyService().getBanks();
      if (mounted) {
        setState(() {
          _banks = response.banks;
          _banksLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _banksLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bankalar yüklenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _loadCompanyData() async {
    setState(() { _companyLoading = true; });
    try {
      final company = await const CompanyService().getCompanyDetail(widget.compId);
      if (mounted && company != null) {
        setState(() {
          _bankUsernameController.text = company.compName.toUpperCase();
          _companyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _companyLoading = false; });
      }
    }
  }

  Future<void> _addBank() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir banka seçin')),
      );
      return;
    }

    setState(() { _loading = true; });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bulunamadı')),
        );
        return;
      }

      final request = AddCompanyBankRequest(
        userToken: token,
        compID: widget.compId,
        bankID: _selectedBank!.bankID,
        bankUsername: _bankUsernameController.text.trim(),
        bankBranchName: _bankBranchNameController.text.trim(),
        bankBranchCode: _bankBranchCodeController.text.trim(),
        compIban: _compIbanController.text.replaceAll(' ', '').trim(),
      );

      final response = await const CompanyService().addCompanyBank(request);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banka bilgisi eklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banka Bilgisi Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Banka Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Bank Selection Dropdown
                      _banksLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<BankItem>(
                                value: _selectedBank,
                                decoration: const InputDecoration(
                                  labelText: 'Banka Seçin *',
                                  hintText: 'Bankanızı seçin',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  prefixIcon: Icon(Icons.account_balance, color: Colors.blue),
                                ),
                                dropdownColor: Colors.white,
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                                iconSize: 24,
                                menuMaxHeight: 300,
                                enableFeedback: true,
                                items: _banks.map((bank) {
                                  return DropdownMenuItem<BankItem>(
                                    value: bank,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                bank.bankLogo,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.account_balance,
                                                      size: 20,
                                                      color: Colors.blue,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  bank.bankName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                               
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (bank) {
                                  setState(() {
                                    _selectedBank = bank;
                                  });
                                },

                                selectedItemBuilder: (BuildContext context) {
                                  return _banks.map<Widget>((bank) {
                                    return Container(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                bank.bankLogo,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.account_balance,
                                                      size: 16,
                                                      color: Colors.blue,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              bank.bankName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankUsernameController,
                        decoration: InputDecoration(
                          labelText: 'Hesap Sahibi / Şirket Adı',
                          hintText: _companyLoading ? 'Şirket adı yükleniyor...' : 'Şirket adını girin',
                          border: const OutlineInputBorder(),
                          suffixIcon: _companyLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        enabled: !_companyLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankBranchNameController,
                        decoration: const InputDecoration(
                          labelText: 'Şube Adı',
                          hintText: 'Şube adını girin',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankBranchCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Şube Kodu',
                          hintText: 'Şube kodunu girin',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _compIbanController,
                        decoration: const InputDecoration(
                          labelText: 'IBAN',
                          hintText: 'TR12 3456 0000 0000 0000 0000 00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [IbanInputFormatter()],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _addBank,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Banka Bilgisi Ekle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}