import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/company_models.dart';

class PdfGeneratorService {
  static Future<Uint8List> generateCompanyDetailPdf(CompanyItem company) async {
    try {
      final pdf = pw.Document();

      // Custom renkler
      final primaryColor = PdfColor.fromHex('#1976D2');
      final lightGray = PdfColor.fromHex('#F5F5F5');
      final mediumGray = PdfColor.fromHex('#757575');

      // Font yükleme - Türkçe karakter desteği için
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      // Logo ve görselleri önceden yükle
      final logoImage = await _loadImage(company.compLogo);
      final List<pw.MemoryImage?> imagesList = [];
      for (final img in company.images) {
        final loadedImage = await _loadImage(img.imageURL);
        imagesList.add(loadedImage);
      }
      
      // Banka logolarını yükle
      final List<pw.MemoryImage?> bankLogosList = [];
      for (final bank in company.banks) {
        final loadedBankLogo = await _loadImage(bank.bankLogo ?? '');
        bankLogosList.add(loadedBankLogo);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(company, primaryColor, fontBold, font, logoImage),
              pw.SizedBox(height: 30),
              
              // Firma Bilgileri
              _buildCompanyInfo(company, primaryColor, fontBold, font, lightGray),
              pw.SizedBox(height: 25),
              
              // Adres Bilgileri
              _buildAddressInfo(company, primaryColor, fontBold, font, lightGray),
              pw.SizedBox(height: 25),
              
              // Ortaklar
              if (company.partners.isNotEmpty) ...[
                _buildPartnersInfo(company.partners, primaryColor, fontBold, font, lightGray),
                pw.SizedBox(height: 25),
              ],
              
              // Belgeler
              if (company.documents.isNotEmpty) ...[
                _buildDocumentsInfo(company.documents, primaryColor, fontBold, font, lightGray),
                pw.SizedBox(height: 25),
              ],
              
              // Banka Bilgileri
              if (company.banks.isNotEmpty) ...[
                _buildBanksInfo(company.banks, bankLogosList, primaryColor, fontBold, font, lightGray),
                pw.SizedBox(height: 25),
              ],
              
              // Görseller
              if (company.images.isNotEmpty) ...[
                _buildImagesInfo(company.images, imagesList, primaryColor, fontBold, font, lightGray),
                pw.SizedBox(height: 25),
              ],
              
              pw.Spacer(),
              
              // Footer
              _buildFooter(font, mediumGray),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(font: font, fontSize: 10, color: mediumGray),
              ),
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      print('PDF oluşturulurken hata: $e');
      rethrow;
    }
  }

  static pw.Widget _buildHeader(CompanyItem company, PdfColor primaryColor, pw.Font fontBold, pw.Font font, pw.MemoryImage? logoImage) {
    final lightGray = PdfColor.fromHex('#F5F5F5');
    
    // Logo widget
    pw.Widget logoWidget;
    if (logoImage != null) {
      logoWidget = pw.Container(
        width: 80,
        height: 80,
        decoration: pw.BoxDecoration(
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 10,
          verticalRadius: 10,
          child: pw.Image(logoImage, fit: pw.BoxFit.fill),
        ),
      );
    } else {
      logoWidget = _buildDefaultLogo(company.compName, primaryColor, fontBold);
    }
    
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          logoWidget,
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company.compName,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 24,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  company.compType ?? 'Firma',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    color: PdfColor.fromHex('#757575'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Firma Detay Raporu',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColor.fromHex('#757575'),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Rapor Tarihi',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColor.fromHex('#757575'),
                ),
              ),
              pw.Text(
                _formatDate(DateTime.now()),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font fontBold, PdfColor primaryColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 16,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildCompanyInfo(CompanyItem company, PdfColor primaryColor, pw.Font fontBold, pw.Font font, PdfColor lightGray) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Firma Bilgileri', fontBold, primaryColor),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Vergi Numarası', company.compTaxNo ?? '-', font, fontBold),
              _buildDivider(),
              _buildInfoRow('Vergi Dairesi', company.compTaxPalace ?? '-', font, fontBold),
              _buildDivider(),
              _buildInfoRow('MERSİS Numarası', company.compMersisNo ?? '-', font, fontBold),
              _buildDivider(),
              _buildInfoRow('KEP Adresi', company.compKepAddress ?? '-', font, fontBold),
              if (company.compEmail != null && company.compEmail!.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('E-Posta', company.compEmail!, font, fontBold),
              ],
              if (company.compPhone != null && company.compPhone!.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Telefon', company.compPhone!, font, fontBold),
              ],
              if (company.compWebsite != null && company.compWebsite!.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Web Sitesi', company.compWebsite!, font, fontBold),
              ],
              if (company.compNaceCode != null && company.compNaceCode!.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('NACE Kodu', company.compNaceCode!, font, fontBold),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAddressInfo(CompanyItem company, PdfColor primaryColor, pw.Font fontBold, pw.Font font, PdfColor lightGray) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Adres Bilgileri', fontBold, primaryColor),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              if (company.addresses.isNotEmpty) ...[
                for (int i = 0; i < company.addresses.length; i++) ...[
                  _buildAddressCard(company.addresses[i], font, fontBold),
                  if (i < company.addresses.length - 1) _buildDivider(),
                ],
              ] else ...[
                _buildInfoRow('İl / İlçe', '${company.compCity} / ${company.compDistrict}', font, fontBold),
                _buildDivider(),
                _buildInfoRow('Adres', company.compAddress, font, fontBold),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAddressCard(CompanyAddressItem address, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            address.addressType ?? 'Adres',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
              color: PdfColor.fromHex('#1976D2'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            address.addressAddress ?? '-',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColor.fromHex('#424242'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPartnersInfo(List<PartnerItem> partners, PdfColor primaryColor, pw.Font fontBold, pw.Font font, PdfColor lightGray) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Ortaklar', fontBold, primaryColor),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                children: [
                  _buildTableHeader('Ad Soyad', fontBold),
                  _buildTableHeader('T.C. No', fontBold),
                  _buildTableHeader('Ünvan', fontBold),
                  _buildTableHeader('Hisse %', fontBold),
                  _buildTableHeader('Tutar', fontBold),
                ],
              ),
              // Rows
              for (final partner in partners)
                pw.TableRow(
                  children: [
                    _buildTableCell(partner.partnerFullname.isNotEmpty ? partner.partnerFullname : partner.partnerName, font),
                    _buildTableCell(partner.partnerIdentityNo.isNotEmpty ? partner.partnerIdentityNo : '-', font),
                    _buildTableCell(partner.partnerTitle.isNotEmpty ? partner.partnerTitle : '-', font),
                    _buildTableCell(partner.partnerShareRatio, font),
                    _buildTableCell(partner.partnerSharePrice, font),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDocumentsInfo(List<CompanyDocumentItem> documents, PdfColor primaryColor, pw.Font fontBold, pw.Font font, PdfColor lightGray) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Belgeler', fontBold, primaryColor),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              for (int i = 0; i < documents.length; i++) ...[
                _buildDocumentRow(documents[i], font, fontBold),
                if (i < documents.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBanksInfo(
    List<CompanyBankItem> banks, 
    List<pw.MemoryImage?> bankLogosList,
    PdfColor primaryColor, 
    pw.Font fontBold, 
    pw.Font font, 
    PdfColor lightGray,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Banka Bilgileri', fontBold, primaryColor),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              for (int i = 0; i < banks.length; i++) ...[
                _buildBankRow(banks[i], bankLogosList[i], font, fontBold),
                if (i < banks.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBankRow(CompanyBankItem bank, pw.MemoryImage? bankLogo, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        children: [
          // Banka logosu veya default icon
          pw.Container(
            width: 40,
            height: 40,
            decoration: pw.BoxDecoration(
              color: bankLogo != null ? PdfColors.white : PdfColor.fromHex('#E8F5E9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: bankLogo != null ? pw.Border.all(color: PdfColor.fromHex('#E0E0E0')) : null,
            ),
            child: bankLogo != null
                ? pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(bankLogo, fit: pw.BoxFit.fill),
                  )
                : pw.Center(
                    child: pw.Text(
                      '🏦',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  bank.bankName.isNotEmpty ? bank.bankName : 'Banka',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColor.fromHex('#424242'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Hesap Sahibi: ${bank.bankUsername}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('#757575'),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'IBAN: ${bank.bankIBAN}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: PdfColor.fromHex('#757575'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDocumentRow(CompanyDocumentItem document, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        children: [
          pw.Container(
            width: 40,
            height: 40,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E3F2FD'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Center(
              child: pw.Text(
                '📄',
                style: pw.TextStyle(fontSize: 16),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  document.documentType,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColor.fromHex('#424242'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Oluşturulma: ${document.createDate}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('#757575'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: PdfColor.fromHex('#757575'),
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColor.fromHex('#424242'),
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      height: 1,
      color: PdfColor.fromHex('#E0E0E0'),
      margin: const pw.EdgeInsets.symmetric(horizontal: 16),
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 10,
          color: PdfColor.fromHex('#424242'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: PdfColor.fromHex('#424242'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font, PdfColor mediumGray) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'))),
      ),
      child: pw.Center(
        child: pw.Text(
          'Artı Capital - Firma Detay Raporu',
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: mediumGray,
          ),
        ),
      ),
    );
  }

  static Future<File> savePdfToFile(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  // Görsel yükleme metodu
  static Future<pw.MemoryImage?> _loadImage(String url) async {
    try {
      if (url.isEmpty) return null;

      Uint8List bytes;

      if (url.startsWith('data:image/')) {
        // Base64 encoded image
        final commaIndex = url.indexOf(',');
        if (commaIndex == -1) return null;
        final base64String = url.substring(commaIndex + 1);
        bytes = base64Decode(base64String);
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        // Network image
        final response = await HttpClient().getUrl(Uri.parse(url));
        final httpResponse = await response.close();
        if (httpResponse.statusCode != 200) return null;
        
        final builder = BytesBuilder(copy: false);
        await for (final chunk in httpResponse) {
          builder.add(chunk);
        }
        bytes = builder.takeBytes();
      } else {
        return null;
      }

      return pw.MemoryImage(bytes);
    } catch (e) {
      print('Görsel yüklenirken hata: $e');
      return null;
    }
  }

  // Default logo widget
  static pw.Widget _buildDefaultLogo(String companyName, PdfColor primaryColor, pw.Font fontBold) {
    return pw.Container(
      width: 80,
      height: 80,
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Center(
        child: pw.Text(
          companyName.isNotEmpty ? companyName.substring(0, 1).toUpperCase() : 'F',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 32,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  // Görseller bölümü
  static pw.Widget _buildImagesInfo(
    List<CompanyImageItem> images,
    List<pw.MemoryImage?> imagesList,
    PdfColor primaryColor,
    pw.Font fontBold,
    pw.Font font,
    PdfColor lightGray,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Görseller', fontBold, primaryColor),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            images.length,
            (index) {
              final image = images[index];
              final loadedImage = imagesList[index];
              
              return pw.Container(
                width: 150,
                height: 120,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    if (loadedImage != null)
                      pw.Expanded(
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            loadedImage,
                            fit: pw.BoxFit.fill,
                          ),
                        ),
                      )
                    else
                      pw.Expanded(
                        child: pw.Container(
                          color: PdfColor.fromHex('#F5F5F5'),
                          child: pw.Center(
                            child: pw.Text(
                              '📷',
                              style: pw.TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F5F5F5'),
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(8),
                          bottomRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        image.imageType,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: PdfColor.fromHex('#424242'),
                        ),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
